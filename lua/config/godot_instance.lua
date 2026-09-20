local M = {}

local uv = vim.uv

local IS_WINDOWS = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
local HOST = "127.0.0.1"

local config = {
    godot_path = "godot",
    startup_timeout_ms = 15000,
    close_timeout_ms = 30000,
    force_close_timeout_ms = 5000,
    port_min = 16000,
    port_max = 49000,
}

local state = {
    bootstrapped = false,
    plugin_ready = false,
    transitioning = false,

    lsp_port = nil,
    dap_port = nil,
    port_lock_server = nil,

    active_root = nil,
    project_server = nil,

    godot_process = nil,
    generation = 0,
}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Godot Instance" })
end

local function normalize_slashes(path)
    return path:gsub("\\", "/")
end

local function normalize_path(path)
    if not path or path == "" then
        return nil
    end

    local full = vim.fn.fnamemodify(path, ":p")
    full = vim.fs.normalize(full)
    full = normalize_slashes(full)

    if full ~= "/" and not full:match("^%a:/$") then
        full = full:gsub("/+$", "")
    end

    return full
end

local function path_key(path)
    path = normalize_path(path)
    if not path then
        return nil
    end

    if IS_WINDOWS then
        return path:lower()
    end

    return path
end

local function same_path(a, b)
    local ka = path_key(a)
    local kb = path_key(b)
    return ka ~= nil and kb ~= nil and ka == kb
end

local function server_key(address)
    if not address or address == "" then
        return nil
    end

    address = normalize_slashes(address)
    if IS_WINDOWS then
        address = address:lower()
    end
    return address
end

local function own_server_exists(address)
    local wanted = server_key(address)
    for _, existing in ipairs(vim.fn.serverlist()) do
        if server_key(existing) == wanted then
            return true, existing
        end
    end
    return false, nil
end

local function claim_server(address)
    local ours, existing = own_server_exists(address)
    if ours then
        return true, existing
    end

    local ok, result = pcall(vim.fn.serverstart, address)
    if not ok then
        return false, tostring(result)
    end

    return true, result
end

local function release_server(address)
    if not address then
        return
    end

    local ours, existing = own_server_exists(address)
    if not ours then
        return
    end

    pcall(vim.fn.serverstop, existing)
end

local function project_root_for_file(filename)
    if not filename or filename == "" then
        return nil
    end

    local root = vim.fs.root(filename, "project.godot")
    return normalize_path(root)
end

local function project_root_for_buf(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return nil
    end

    local filename = vim.api.nvim_buf_get_name(bufnr)
    return project_root_for_file(filename)
end

local function project_pipe(root)
    local key = assert(path_key(root), "invalid Godot project root")
    return "//./pipe/nvim-godot-project-" .. vim.fn.sha256(key)
end

local function port_lock_pipe(lsp_port, dap_port)
    return string.format("//./pipe/nvim-godot-port-%d-%d", lsp_port, dap_port)
end

local function close_handle(handle)
    if not handle then
        return
    end

    pcall(function()
        if not handle:is_closing() then
            handle:close()
        end
    end)
end

local function can_listen(port)
    local tcp = uv.new_tcp()
    if not tcp then
        return false
    end

    local ok_bind, bind_result = pcall(function()
        return tcp:bind(HOST, port)
    end)

    if not ok_bind or bind_result == nil then
        close_handle(tcp)
        return false
    end

    local ok_listen, listen_result = pcall(function()
        return tcp:listen(1, function() end)
    end)

    local result = ok_listen and listen_result ~= nil
    close_handle(tcp)
    return result
end

local function ensure_port_pair()
    if state.lsp_port and state.dap_port and state.port_lock_server then
        return
    end

    local min_port = config.port_min
    local max_port = config.port_max

    if min_port % 2 ~= 0 then
        min_port = min_port + 1
    end
    if max_port % 2 ~= 0 then
        max_port = max_port - 1
    end

    if max_port <= min_port then
        error("Godot Instance: invalid port range")
    end

    local pair_count = math.floor((max_port - min_port) / 2) + 1
    local start_slot = vim.fn.getpid() % pair_count

    for offset = 0, pair_count - 1 do
        local slot = (start_slot + offset) % pair_count
        local lsp_port = min_port + slot * 2
        local dap_port = lsp_port + 1
        local lock_address = port_lock_pipe(lsp_port, dap_port)

        local claimed, lock_or_error = claim_server(lock_address)
        if claimed then
            if can_listen(lsp_port) and can_listen(dap_port) then
                state.lsp_port = lsp_port
                state.dap_port = dap_port
                state.port_lock_server = lock_or_error
                return
            end

            release_server(lock_or_error)
        end
    end

    error("Godot Instance: no free LSP/DAP port pair is available")
end

local function now_ms()
    return uv.hrtime() / 1000000
end

local function port_is_open(port, callback)
    local tcp = uv.new_tcp()
    if not tcp then
        vim.schedule(function()
            callback(false)
        end)
        return
    end

    local finished = false
    local function finish(open)
        if finished then
            return
        end
        finished = true
        close_handle(tcp)
        vim.schedule(function()
            callback(open)
        end)
    end

    local ok, request = pcall(function()
        return tcp:connect(HOST, port, function(err)
            finish(err == nil)
        end)
    end)

    if not ok or request == nil then
        finish(false)
    end
end

local function wait_for_port(port, expected_open, timeout_ms, generation, callback)
    local deadline = now_ms() + timeout_ms

    local function check()
        if generation ~= state.generation then
            return
        end

        port_is_open(port, function(open)
            if generation ~= state.generation then
                return
            end

            if open == expected_open then
                callback(true)
                return
            end

            if now_ms() >= deadline then
                callback(false)
                return
            end

            vim.defer_fn(check, 100)
        end)
    end

    check()
end

local function process_running(process)
    if not process then
        return false
    end

    local ok, closing = pcall(process.is_closing, process)
    return ok and not closing
end

local function wait_for_process_exit(process, timeout_ms, generation, callback)
    local deadline = now_ms() + timeout_ms

    local function check()
        if generation ~= state.generation then
            return
        end

        if not process_running(process) then
            callback(true)
            return
        end

        if now_ms() >= deadline then
            callback(false)
            return
        end

        vim.defer_fn(check, 150)
    end

    check()
end

local function disable_lsp()
    pcall(vim.lsp.enable, "gdscript", false)
end

local function enable_lsp()
    local ok, err = pcall(vim.lsp.enable, "gdscript", true)
    if not ok then
        notify("Failed to enable gdscript LSP:\n" .. tostring(err), vim.log.levels.ERROR)
    end
end

local function patch_lsp()
    vim.lsp.config("gdscript", {
        root_dir = function(bufnr, on_dir)
            local active_root = state.active_root
            if not active_root then
                return
            end

            local root = project_root_for_buf(bufnr)
            if not root or not same_path(root, active_root) then
                return
            end

            on_dir(active_root)
        end,
    })
end

local function stop_dap_session()
    local ok, dap = pcall(require, "dap")
    if not ok then
        return
    end

    local session = dap.session()
    if session then
        pcall(dap.terminate)
    end
end

local function patch_dap()
    local ok, dap = pcall(require, "dap")
    if not ok then
        return
    end

    dap.adapters.godot = {
        type = "server",
        host = HOST,
        port = state.dap_port,
    }
end

local function close_helper_path()
    return vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "tools", "godot-close.ps1")
end

local function request_normal_close(process, callback)
    if not process_running(process) then
        callback(true)
        return
    end

    if not IS_WINDOWS then
        callback(false, "normal window close helper is only configured for Windows")
        return
    end

    local helper = close_helper_path()
    if vim.fn.filereadable(helper) ~= 1 then
        callback(false, "missing helper: " .. helper)
        return
    end

    local ok, system_or_error = pcall(vim.system, {
        "powershell.exe",
        "-NoLogo",
        "-NoProfile",
        "-NonInteractive",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        helper,
        "-ProcessId",
        tostring(process.pid),
    }, {
        text = true,
    }, function(result)
        vim.schedule(function()
            if not process_running(process) then
                callback(true)
                return
            end

            if result.code ~= 0 then
                local detail = result.stderr or result.stdout or ""
                callback(false, detail ~= "" and detail or ("close helper exited with code " .. result.code))
                return
            end

            callback(true)
        end)
    end)

    if not ok then
        callback(false, tostring(system_or_error))
    end
end

local function force_kill_process(process)
    if not process_running(process) then
        return
    end

    pcall(process.kill, process, "sigterm")
end

local function close_managed_godot(opts, callback)
    opts = opts or {}

    local process = state.godot_process
    if not process_running(process) then
        state.godot_process = nil
        callback(true)
        return
    end

    local generation = state.generation

    if opts.force then
        force_kill_process(process)
        wait_for_process_exit(process, config.force_close_timeout_ms, generation, function(exited)
            if not exited and process_running(process) then
                pcall(process.kill, process, "sigkill")
            end

            wait_for_process_exit(process, config.force_close_timeout_ms, generation, function(exited_after_kill)
                if exited_after_kill then
                    if state.godot_process == process then
                        state.godot_process = nil
                    end
                    callback(true)
                else
                    callback(false, "Godot process did not exit after force close")
                end
            end)
        end)
        return
    end

    request_normal_close(process, function(close_requested, err)
        if not close_requested then
            callback(false, err)
            return
        end

        wait_for_process_exit(process, config.close_timeout_ms, generation, function(exited)
            if exited then
                if state.godot_process == process then
                    state.godot_process = nil
                end
                callback(true)
                return
            end

            callback(false, "Godot is still running. Finish or cancel its save/close dialog, then retry. Use ! only if you accept losing unsaved Godot editor changes.")
        end)
    end)
end

local function start_godot(root, generation, callback)
    local project_file = vim.fs.joinpath(root, "project.godot")
    if vim.fn.filereadable(project_file) ~= 1 then
        callback(false, "project.godot not found: " .. root)
        return
    end

    local cmd = {
        config.godot_path,
        "--editor",
        "--path",
        root,
        "--lsp-port",
        tostring(state.lsp_port),
        "--dap-port",
        tostring(state.dap_port),
    }

    local process
    local ok, system_or_error = pcall(function()
        process = vim.system(cmd, {
            cwd = root,
            stdout = false,
            stderr = false,
            detach = false,
        }, function(result)
            vim.schedule(function()
                if state.godot_process == process then
                    state.godot_process = nil
                    disable_lsp()

                    if result.code ~= 0 then
                        notify("Managed Godot exited with code " .. tostring(result.code), vim.log.levels.WARN)
                    end
                end
            end)
        end)
    end)

    if not ok then
        callback(false, tostring(system_or_error))
        return
    end

    state.godot_process = process

    wait_for_port(state.lsp_port, true, config.startup_timeout_ms, generation, function(ready)
        if generation ~= state.generation then
            return
        end

        if not ready then
            callback(false, string.format(
                "Godot started, but LSP port %d did not become ready. The project remains owned by this Nvim; fix Godot's TCP LSP setting and run :GodotRestart.",
                state.lsp_port
            ))
            return
        end

        enable_lsp()
        callback(true)
    end)
end

local function ensure_plugin_ready()
    if state.plugin_ready then
        return true
    end

    local ok_lazy, lazy = pcall(require, "lazy")
    if ok_lazy then
        pcall(lazy.load, { plugins = { "godotdev.nvim" } })
    end

    if state.plugin_ready then
        return true
    end

    notify(
        "godotdev.nvim is not initialized. Ensure its Lazy spec calls godot_instance.godotdev_opts() before setup and godot_instance.after_godotdev_setup() after setup.",
        vim.log.levels.ERROR
    )
    return false
end

local function cleanup_active_project()
    disable_lsp()
    stop_dap_session()

    if state.project_server then
        release_server(state.project_server)
    end

    state.active_root = nil
    state.project_server = nil
end

local function finish_transition()
    state.transitioning = false
end

local function acquire_project(root)
    local address = project_pipe(root)
    local claimed, server_or_error = claim_server(address)
    if not claimed then
        return nil, "This Godot project is already active in another Nvim:\n" .. root
    end

    return server_or_error
end

local function opened_projects()
    local result = {}
    local seen = {}

    local function add(root)
        root = normalize_path(root)
        if not root then
            return
        end

        local key = path_key(root)
        if seen[key] then
            return
        end

        seen[key] = true
        table.insert(result, root)
    end

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        add(project_root_for_buf(bufnr))
    end

    add(state.active_root)

    table.sort(result, function(a, b)
        return path_key(a) < path_key(b)
    end)

    return result
end

local function transition_guard()
    if state.transitioning then
        notify("A Godot transition is already in progress", vim.log.levels.WARN)
        return false
    end
    return true
end

function M.activate(root, opts)
    opts = opts or {}

    if not ensure_plugin_ready() or not transition_guard() then
        return
    end

    ensure_port_pair()

    root = normalize_path(root)
    if not root then
        notify("Invalid Godot project root", vim.log.levels.ERROR)
        return
    end

    if vim.fn.filereadable(vim.fs.joinpath(root, "project.godot")) ~= 1 then
        notify("project.godot not found:\n" .. root, vim.log.levels.ERROR)
        return
    end

    if same_path(root, state.active_root) then
        if process_running(state.godot_process) then
            notify("Already active:\n" .. root)
            return
        end

        state.transitioning = true
        state.generation = state.generation + 1
        local generation = state.generation
        disable_lsp()
        start_godot(root, generation, function(ok, err)
            finish_transition()
            if not ok then
                notify(err, vim.log.levels.ERROR)
                return
            end

            notify(string.format(
                "Godot active:\n%s\nLSP :%d  DAP :%d",
                root,
                state.lsp_port,
                state.dap_port
            ))
        end)
        return
    end

    local target_server, acquire_error = acquire_project(root)
    if not target_server then
        notify(acquire_error, vim.log.levels.WARN)
        return
    end

    state.transitioning = true
    state.generation = state.generation + 1
    local generation = state.generation

    local old_root = state.active_root
    local old_server = state.project_server

    local function abort_switch(message)
        release_server(target_server)
        finish_transition()
        if message then
            notify(message, vim.log.levels.WARN)
        end
    end

    local function commit_switch()
        if generation ~= state.generation then
            release_server(target_server)
            return
        end

        disable_lsp()
        stop_dap_session()

        if old_server then
            release_server(old_server)
        end

        state.active_root = root
        state.project_server = target_server
        patch_lsp()
        patch_dap()

        start_godot(root, generation, function(ok, err)
            finish_transition()

            if not ok then
                notify(err, vim.log.levels.ERROR)
                return
            end

            notify(string.format(
                "Godot active:\n%s\nLSP :%d  DAP :%d",
                root,
                state.lsp_port,
                state.dap_port
            ))
        end)
    end

    if old_root and process_running(state.godot_process) then
        close_managed_godot({ force = opts.force == true }, function(closed, err)
            if generation ~= state.generation then
                release_server(target_server)
                return
            end

            if not closed then
                abort_switch(err or "Godot switch cancelled")
                return
            end

            commit_switch()
        end)
        return
    end

    commit_switch()
end

function M.here(opts)
    opts = opts or {}

    local root = project_root_for_buf(vim.api.nvim_get_current_buf())
    if not root then
        notify("Current buffer is not inside a Godot project", vim.log.levels.WARN)
        return
    end

    M.activate(root, opts)
end

function M.project(opts)
    opts = opts or {}

    if not ensure_plugin_ready() then
        return
    end

    local projects = opened_projects()
    if #projects == 0 then
        notify("No opened Godot projects found", vim.log.levels.WARN)
        return
    end

    vim.ui.select(projects, {
        prompt = "Godot Project",
        format_item = function(root)
            local marker = same_path(root, state.active_root) and "● " or "  "
            return marker .. vim.fs.basename(root) .. "    " .. root
        end,
    }, function(choice)
        if choice then
            M.activate(choice, opts)
        end
    end)
end

function M.restart(opts)
    opts = opts or {}

    if not ensure_plugin_ready() or not transition_guard() then
        return
    end

    if not state.active_root then
        notify("No active Godot project", vim.log.levels.WARN)
        return
    end

    state.transitioning = true
    state.generation = state.generation + 1
    local generation = state.generation
    local root = state.active_root

    local function start_again()
        disable_lsp()
        stop_dap_session()
        patch_lsp()
        patch_dap()

        start_godot(root, generation, function(ok, err)
            finish_transition()
            if not ok then
                notify(err, vim.log.levels.ERROR)
                return
            end

            notify(string.format(
                "Godot restarted:\n%s\nLSP :%d  DAP :%d",
                root,
                state.lsp_port,
                state.dap_port
            ))
        end)
    end

    if process_running(state.godot_process) then
        close_managed_godot({ force = opts.force == true }, function(closed, err)
            if generation ~= state.generation then
                return
            end

            if not closed then
                finish_transition()
                notify(err or "Godot restart cancelled", vim.log.levels.WARN)
                return
            end

            start_again()
        end)
        return
    end

    start_again()
end

function M.stop(opts)
    opts = opts or {}

    if not ensure_plugin_ready() or not transition_guard() then
        return
    end

    if not state.active_root then
        disable_lsp()
        notify("No active Godot project")
        return
    end

    state.transitioning = true
    state.generation = state.generation + 1
    local generation = state.generation

    local function finish_stop()
        cleanup_active_project()
        finish_transition()
        notify("Godot instance stopped")
    end

    if process_running(state.godot_process) then
        close_managed_godot({ force = opts.force == true }, function(closed, err)
            if generation ~= state.generation then
                return
            end

            if not closed then
                finish_transition()
                notify(err or "Godot stop cancelled", vim.log.levels.WARN)
                return
            end

            finish_stop()
        end)
        return
    end

    finish_stop()
end

function M.status()
    if not ensure_plugin_ready() then
        return
    end

    ensure_port_pair()

    local active_client = nil
    for _, client in ipairs(vim.lsp.get_clients({ name = "godot_editor" })) do
        if state.active_root and same_path(client.root_dir, state.active_root) then
            active_client = client
            break
        end
    end

    local godot_pid = "-"
    if process_running(state.godot_process) then
        godot_pid = tostring(state.godot_process.pid)
    end

    local project_pipe_value = state.project_server or "-"

    local lines = {
        string.format("Nvim PID    : %d", vim.fn.getpid()),
        string.format("Nvim server : %s", vim.v.servername ~= "" and vim.v.servername or "-"),
        "",
        string.format("Project     : %s", state.active_root or "-"),
        string.format("Project RPC : %s", project_pipe_value),
        string.format("Godot PID   : %s", godot_pid),
        "",
        string.format("Godot LSP   : %s:%d", HOST, state.lsp_port),
        string.format("Godot DAP   : %s:%d", HOST, state.dap_port),
        string.format("LSP attached: %s", tostring(active_client ~= nil and active_client.initialized == true)),
        string.format("Transition  : %s", tostring(state.transitioning)),
    }

    notify(table.concat(lines, "\n"))
end

function M.active_root()
    return state.active_root
end

function M.godotdev_opts(opts)
    opts = vim.deepcopy(opts or {})
    ensure_port_pair()

    opts.editor_host = HOST
    opts.editor_port = state.lsp_port
    opts.debug_port = state.dap_port

    -- We own the project-specific editor RPC pipe ourselves.
    opts.autostart_editor_server = false

    if opts.godot_path then
        config.godot_path = opts.godot_path
    end

    return opts
end

function M.after_godotdev_setup(opts)
    opts = opts or {}
    if opts.godot_path then
        config.godot_path = opts.godot_path
    end

    ensure_port_pair()

    -- godotdev.setup() enables gdscript immediately. Keep it disabled until
    -- this Nvim has an active project and its Godot LSP port is listening.
    disable_lsp()
    patch_lsp()

    -- Work around godotdev.nvim@ccac07c passing host/port while dap.lua reads
    -- editor_host/debug_port.
    patch_dap()

    state.plugin_ready = true
end

local function create_command(name, callback, opts)
    opts = opts or {}
    if vim.fn.exists(":" .. name) == 2 then
        vim.api.nvim_del_user_command(name)
    end

    vim.api.nvim_create_user_command(name, callback, opts)
end

function M.bootstrap(opts)
    if state.bootstrapped then
        return
    end

    config = vim.tbl_deep_extend("force", config, opts or {})

    create_command("GodotHere", function(command_opts)
        M.here({ force = command_opts.bang })
    end, {
        bang = true,
        desc = "Set current buffer's Godot project active (! force-closes old managed Godot)",
    })

    create_command("GodotProject", function(command_opts)
        M.project({ force = command_opts.bang })
    end, {
        bang = true,
        desc = "Choose active Godot project (! force-closes old managed Godot)",
    })

    create_command("GodotRestart", function(command_opts)
        M.restart({ force = command_opts.bang })
    end, {
        bang = true,
        desc = "Restart managed Godot Editor (! may discard unsaved Godot editor changes)",
    })

    create_command("GodotStop", function(command_opts)
        M.stop({ force = command_opts.bang })
    end, {
        bang = true,
        desc = "Stop managed Godot Editor (! may discard unsaved Godot editor changes)",
    })

    create_command("GodotStatus", function()
        M.status()
    end, {
        desc = "Show Godot instance status",
    })

    -- Never force-kill Godot during Nvim shutdown: that could discard unsaved
    -- scene/resource changes. Named-pipe ownership disappears automatically
    -- when this Nvim process exits, so routing fails closed instead of going to
    -- another Nvim.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("godot_instance_manager", { clear = true }),
        callback = function()
            disable_lsp()
            stop_dap_session()
        end,
    })

    state.bootstrapped = true
end

return M
