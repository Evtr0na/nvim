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

    -- Godot's editor window can steal the foreground window on Windows when it
    -- is launched automatically. Keep the terminal/Nvim focused by default.
    preserve_focus_on_start = true,
    focus_guard_timeout_ms = 5000,
    focus_guard_poll_ms = 40,
    lsp_port_poll_ms = 25,

    ------------------------------------------------------------
    -- 实例复用（省掉 Godot 编辑器冷启动的 5-6 秒）
    ------------------------------------------------------------

    -- 托管启动的 Godot 是否活过 Nvim。true 时下一次启动 Nvim 可以直接
    -- 复用它，代价是它会留在后台，需要 :GodotStop 关掉。
    keep_alive = true,

    -- 总开关：启动时先找可复用的实例，找不到才托管启动。
    reuse = true,

    -- 是否也复用“不是本 Nvim 托管”的 Godot（也就是你自己开的那个）。
    reuse_external = true,

    -- 外部编辑器的 LSP 端口候选。对应 Godot 设置项
    -- network/language_server/remote_port（默认 6005）。
    reuse_external_ports = { 6005 },

    -- 外部编辑器的 DAP 端口 = LSP 端口 + 这个偏移（6005 -> 6006）。
    reuse_external_dap_offset = 1,

    -- 复用外部编辑器之前，用 Godot 窗口标题里的项目名确认它开的确实是
    -- 当前项目（Godot 4 的标题形如 "scene.tscn - 项目名 - Godot Engine"）。
    -- 关掉会退化成“6005 上有东西就连”，有连错项目的风险。
    reuse_external_verify = true,

    -- 实例状态文件目录，nil = stdpath("state")/godot_instance
    state_dir = nil,
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
    godot_process_pid = nil,
    generation = 0,

    -- 复用来的实例：{ source = "managed" | "external", pid = number|nil }
    adopted = nil,
}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Godot Instance" })
end

local function notify_unless_silent(opts, message, level)
    if not (opts and opts.silent) then
        notify(message, level)
    end
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

local function peer_server_reachable(address)
    if not address or address == "" then
        return false
    end

    -- serverlist() only reports servers owned by this Nvim on Windows. Probe
    -- the named pipe first so another Nvim owning it is a normal collision,
    -- not an expected serverstart() EADDRINUSE failure.
    local ok, channel = pcall(vim.fn.sockconnect, "pipe", address, { rpc = true })
    if not ok or type(channel) ~= "number" or channel <= 0 then
        return false
    end

    pcall(vim.fn.chanclose, channel)
    return true
end

local function claim_server(address)
    local ours, existing = own_server_exists(address)
    if ours then
        return true, existing
    end

    if peer_server_reachable(address) then
        return false, "address already in use"
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

----------------------------------------------------------------------------
-- 实例复用：状态持久化 + 存活探测
--
-- 托管启动的 Godot 现在会活过 Nvim，所以下一次启动 Nvim 可以直接复用同一个
-- 编辑器，不必再等它冷启动。
----------------------------------------------------------------------------

local function state_dir()
    return config.state_dir or vim.fs.joinpath(vim.fn.stdpath("state"), "godot_instance")
end

local function state_file()
    return vim.fs.joinpath(state_dir(), "instances.json")
end

local function read_records()
    if vim.fn.filereadable(state_file()) ~= 1 then
        return {}
    end

    local ok_read, lines = pcall(vim.fn.readfile, state_file())
    if not ok_read or type(lines) ~= "table" then
        return {}
    end

    local ok_decode, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok_decode or type(decoded) ~= "table" then
        return {}
    end

    return decoded
end

local function write_records(records)
    pcall(vim.fn.mkdir, state_dir(), "p")

    local ok_encode, encoded = pcall(vim.json.encode, records)
    if not ok_encode then
        return
    end

    pcall(vim.fn.writefile, { encoded }, state_file())
end

local function record_instance(root, pid, lsp_port, dap_port)
    local records = read_records()

    records[path_key(root)] = {
        root = normalize_path(root),
        pid = tonumber(pid),
        lsp_port = tonumber(lsp_port),
        dap_port = tonumber(dap_port),
        godot_path = config.godot_path,
        updated_at = os.time(),
    }

    write_records(records)
end

local function forget_instance(root)
    local key = path_key(root)
    if not key then
        return
    end

    local records = read_records()
    if records[key] == nil then
        return
    end

    records[key] = nil
    write_records(records)
end

local function pid_alive(pid)
    pid = tonumber(pid)
    if not pid or pid <= 0 then
        return false
    end

    -- uv.kill(pid, 0) 在 Windows 上就是一次 OpenProcess 存活检查。
    local ok, result = pcall(uv.kill, pid, 0)
    return ok and result ~= nil
end

-- 同步 TCP 探测。本机端口被拒绝是即时的（实测 < 1ms），所以可以直接
-- 放在启动路径上，不需要异步等待。
local function tcp_reachable(port)
    port = tonumber(port)
    if not port then
        return false
    end

    local ok, channel = pcall(vim.fn.sockconnect, "tcp", string.format("%s:%d", HOST, port), { rpc = false })
    if not ok or type(channel) ~= "number" or channel <= 0 then
        return false
    end

    pcall(vim.fn.chanclose, channel)
    return true
end

local function normalize_match(text)
    return (tostring(text):lower():gsub("[^%w]", ""))
end

local function project_name_for_root(root)
    local project_file = vim.fs.joinpath(root, "project.godot")

    if vim.fn.filereadable(project_file) == 1 then
        local ok, lines = pcall(vim.fn.readfile, project_file)
        if ok and type(lines) == "table" then
            for _, line in ipairs(lines) do
                local name = line:match('^%s*config/name%s*=%s*"(.*)"%s*$')
                if name and name ~= "" then
                    return name
                end
            end
        end
    end

    return vim.fs.basename(root)
end

----------------------------------------------------------------------------
-- 窗口标题
--
-- 用来确认“某个正在跑的 Godot 编辑器窗口属于当前项目”。Godot 4 的编辑器
-- 标题形如：
--     loot_container.tscn - 3D- RPG - Godot Engine
-- 因此标题里含有 project.godot 的 config/name。
----------------------------------------------------------------------------

local window_title_api_state = {
    initialized = false,
    ffi = nil,
    user32 = nil,
}

local function window_title_api()
    if not IS_WINDOWS then
        return nil, nil
    end

    if window_title_api_state.initialized then
        return window_title_api_state.ffi, window_title_api_state.user32
    end

    window_title_api_state.initialized = true

    local ok_ffi, ffi = pcall(require, "ffi")
    if not ok_ffi then
        return nil, nil
    end

    -- pcall：FFI 的 C 声明是进程级的，配置重载时会重复声明。
    pcall(ffi.cdef, [[
        int EnumWindows(int (*lpEnumFunc)(void*, intptr_t), intptr_t lParam);
        int GetWindowTextLengthW(void* hWnd);
        int GetWindowTextW(void* hWnd, unsigned short* lpString, int nMaxCount);
    ]])

    local ok_user32, user32 = pcall(ffi.load, "user32")
    if not ok_user32 then
        return nil, nil
    end

    window_title_api_state.ffi = ffi
    window_title_api_state.user32 = user32
    return ffi, user32
end

-- 所有顶层窗口标题的“归一化”形式：小写、只保留 ASCII 字母数字。
-- 这样 "3D- RPG" 和目录名 "3d--rpg" 都能匹配上。
local function normalized_window_titles()
    local ffi, user32 = window_title_api()
    if not ffi or not user32 then
        return nil
    end

    local titles = {}

    local callback = ffi.cast("int (*)(void*, intptr_t)", function(hwnd)
        local length = user32.GetWindowTextLengthW(hwnd)

        if length > 0 then
            local buffer = ffi.new("unsigned short[?]", length + 1)
            local copied = user32.GetWindowTextW(hwnd, buffer, length + 1)

            if copied > 0 then
                local chars = {}
                for index = 0, copied - 1 do
                    local code = buffer[index]
                    local is_digit = code >= 48 and code <= 57
                    local is_upper = code >= 65 and code <= 90
                    local is_lower = code >= 97 and code <= 122

                    if is_digit or is_upper or is_lower then
                        chars[#chars + 1] = string.char(is_upper and code + 32 or code)
                    end
                end
                titles[#titles + 1] = table.concat(chars)
            end
        end

        return 1
    end)

    local ok = pcall(user32.EnumWindows, callback, 0)
    if not ok then
        return nil
    end

    return titles
end

local function external_editor_serves_project(root)
    local wanted = normalize_match(project_name_for_root(root))

    -- 项目名太短（或不是 ASCII）时无法可靠校验，宁可退回托管启动。
    if #wanted < 3 then
        return false
    end

    local titles = normalized_window_titles()
    if not titles then
        return false
    end

    for _, title in ipairs(titles) do
        -- 同时要求出现项目名和 "godot"：Godot 编辑器标题是
        -- "<scene> - <项目名> - Godot Engine"，而某个终端的标题可能只是
        -- 恰好包含项目目录名，那种情况不算数。
        if title:find(wanted, 1, true) and title:find("godot", 1, true) then
            return true
        end
    end

    return false
end

----------------------------------------------------------------------------
-- 复用探测
----------------------------------------------------------------------------

local function adopt_instance(instance)
    -- 换到别的端口对时，把原来预留的那一对还回去。
    if state.port_lock_server and state.lsp_port ~= instance.lsp_port then
        release_server(state.port_lock_server)
        state.port_lock_server = nil
    end

    state.adopted = {
        source = instance.source,
        pid = instance.pid,
    }
    state.lsp_port = instance.lsp_port
    state.dap_port = instance.dap_port
end

local function release_adopted()
    if state.port_lock_server then
        release_server(state.port_lock_server)
    end

    state.adopted = nil
    state.lsp_port = nil
    state.dap_port = nil
    state.port_lock_server = nil
end

-- 返回 nil（没有可复用的）或 { source, lsp_port, dap_port, pid }
local function probe_reusable_instance(root)
    if not config.reuse then
        return nil
    end

    -- 1) 之前（可能是上一个 Nvim）托管启动、并且还活着的实例
    local record = read_records()[path_key(root)]
    if record then
        local lsp_port = tonumber(record.lsp_port)
        local dap_port = tonumber(record.dap_port)

        if lsp_port and dap_port and pid_alive(record.pid) and tcp_reachable(lsp_port) then
            return {
                source = "managed",
                lsp_port = lsp_port,
                dap_port = dap_port,
                pid = tonumber(record.pid),
            }
        end

        forget_instance(root)
    end

    -- 2) 外部编辑器（你自己开的那个 Godot）
    if config.reuse_external then
        local offset = tonumber(config.reuse_external_dap_offset) or 1

        for _, port in ipairs(config.reuse_external_ports) do
            port = tonumber(port)

            if port and tcp_reachable(port) then
                if not config.reuse_external_verify or external_editor_serves_project(root) then
                    return {
                        source = "external",
                        lsp_port = port,
                        dap_port = port + offset,
                        pid = nil,
                    }
                end
            end
        end
    end

    return nil
end

local function project_root_for_file(filename)
    if not filename or filename == "" then
        return nil
    end

    local ok, root = pcall(vim.fs.root, filename, "project.godot")
    if not ok then
        return nil
    end

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
    -- 复用来的端口对没有 lock server，用 state.adopted 标记。
    if state.lsp_port and state.dap_port and (state.port_lock_server or state.adopted) then
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

            vim.defer_fn(check, math.max(tonumber(config.lsp_port_poll_ms) or 25, 10))
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

-- 当前项目“托管的”Godot 的 pid。
-- 复用外部编辑器（你自己开的那个）时返回 nil —— 那个进程不归我们管。
local function managed_pid()
    if process_running(state.godot_process) then
        return tonumber(state.godot_process_pid)
    end

    if state.adopted and state.adopted.source == "managed" then
        local pid = tonumber(state.adopted.pid)
        if pid_alive(pid) then
            return pid
        end
    end

    return nil
end

local function managed_alive()
    return managed_pid() ~= nil
end

local function instance_source_label()
    if state.adopted then
        if state.adopted.source == "external" then
            return "external editor (reused)"
        end

        return string.format("managed (reused, pid %s)", tostring(state.adopted.pid or "?"))
    end

    if process_running(state.godot_process) then
        return "managed (launched by this Nvim)"
    end

    return "-"
end

local windows_focus_api_state = {
    initialized = false,
    ffi = nil,
    user32 = nil,
    kernel32 = nil,
}

local function windows_focus_api()
    if not IS_WINDOWS then
        return nil, nil
    end

    if windows_focus_api_state.initialized then
        return windows_focus_api_state.ffi, windows_focus_api_state.user32, windows_focus_api_state.kernel32
    end

    windows_focus_api_state.initialized = true

    local ok_ffi, ffi = pcall(require, "ffi")
    if not ok_ffi then
        return nil, nil
    end

    -- pcall keeps this safe across config reloads, because LuaJIT FFI C
    -- declarations are global to the process and may already exist.
    pcall(ffi.cdef, [[
        void* GetForegroundWindow(void);
        int SetForegroundWindow(void* hWnd);
        int IsWindow(void* hWnd);
        int BringWindowToTop(void* hWnd);
        int AttachThreadInput(unsigned long idAttach, unsigned long idAttachTo, int fAttach);
        unsigned long GetWindowThreadProcessId(void* hWnd, unsigned long* lpdwProcessId);
        unsigned long GetCurrentThreadId(void);
    ]])

    local ok_user32, user32 = pcall(ffi.load, "user32")
    local ok_kernel32, kernel32 = pcall(ffi.load, "kernel32")
    if not ok_user32 or not ok_kernel32 then
        return nil, nil, nil
    end

    local ok_probe = pcall(function()
        return user32.GetForegroundWindow
            and user32.SetForegroundWindow
            and user32.IsWindow
            and user32.BringWindowToTop
            and user32.AttachThreadInput
            and user32.GetWindowThreadProcessId
            and kernel32.GetCurrentThreadId
    end)
    if not ok_probe then
        return nil, nil, nil
    end

    windows_focus_api_state.ffi = ffi
    windows_focus_api_state.user32 = user32
    windows_focus_api_state.kernel32 = kernel32
    return ffi, user32, kernel32
end

local function capture_foreground_window()
    if not config.preserve_focus_on_start then
        return nil
    end

    local ffi, user32, kernel32 = windows_focus_api()
    if not ffi or not user32 or not kernel32 then
        return nil
    end

    local ok, hwnd = pcall(user32.GetForegroundWindow)
    if not ok or hwnd == nil or hwnd == ffi.NULL then
        return nil
    end

    return {
        ffi = ffi,
        user32 = user32,
        kernel32 = kernel32,
        hwnd = hwnd,
    }
end

local function foreground_process_id(focus, hwnd)
    local pid = focus.ffi.new("unsigned long[1]")
    local ok, thread_id = pcall(focus.user32.GetWindowThreadProcessId, hwnd, pid)
    if not ok or thread_id == 0 then
        return nil
    end

    return tonumber(pid[0])
end

local function restore_foreground_window(focus, foreground)
    local ok_window, is_window = pcall(focus.user32.IsWindow, focus.hwnd)
    if not ok_window or is_window == 0 then
        return false
    end

    local ok_set, set_result = pcall(focus.user32.SetForegroundWindow, focus.hwnd)
    if ok_set and set_result ~= 0 then
        return true
    end

    -- Windows can reject SetForegroundWindow because of its foreground-lock
    -- rules. Temporarily attach Nvim's input thread to the current foreground
    -- thread and the terminal window thread, retry, then immediately detach.
    local ok_current, current_thread = pcall(focus.kernel32.GetCurrentThreadId)
    if not ok_current or current_thread == 0 then
        return false
    end

    local foreground_thread = nil
    if foreground and foreground ~= focus.ffi.NULL then
        local ok_fg, thread_id = pcall(focus.user32.GetWindowThreadProcessId, foreground, nil)
        if ok_fg and thread_id ~= 0 then
            foreground_thread = thread_id
        end
    end

    local ok_target, target_thread = pcall(focus.user32.GetWindowThreadProcessId, focus.hwnd, nil)
    if not ok_target or target_thread == 0 then
        return false
    end

    local attached = {}
    local function attach(thread_id)
        if not thread_id or thread_id == 0 or thread_id == current_thread then
            return
        end

        local ok_attach, attached_ok = pcall(focus.user32.AttachThreadInput, current_thread, thread_id, 1)
        if ok_attach and attached_ok ~= 0 then
            table.insert(attached, thread_id)
        end
    end

    attach(foreground_thread)
    attach(target_thread)

    pcall(focus.user32.BringWindowToTop, focus.hwnd)
    local ok_retry, retry_result = pcall(focus.user32.SetForegroundWindow, focus.hwnd)

    for index = #attached, 1, -1 do
        pcall(focus.user32.AttachThreadInput, current_thread, attached[index], 0)
    end

    return ok_retry and retry_result ~= 0
end

local function guard_focus_after_godot_launch(focus, process, pid)
    if not focus or not process or not pid then
        return
    end

    local timeout_ms = math.max(tonumber(config.focus_guard_timeout_ms) or 0, 0)
    local poll_ms = math.max(tonumber(config.focus_guard_poll_ms) or 40, 10)
    if timeout_ms == 0 then
        return
    end

    local deadline = now_ms() + timeout_ms
    local godot_pid = tonumber(pid)

    local function check()
        if state.godot_process ~= process or not process_running(process) then
            return
        end

        if now_ms() >= deadline then
            return
        end

        local ok, foreground = pcall(focus.user32.GetForegroundWindow)
        if not ok or foreground == nil or foreground == focus.ffi.NULL then
            vim.defer_fn(check, poll_ms)
            return
        end

        -- As long as Nvim's terminal is still in front, keep watching for the
        -- Godot editor's first activation.
        if foreground == focus.hwnd then
            vim.defer_fn(check, poll_ms)
            return
        end

        local foreground_pid = foreground_process_id(focus, foreground)
        if foreground_pid == godot_pid then
            -- Godot itself took focus. Restore the exact window that was in
            -- front before launch, then stop watching so later intentional
            -- Alt-Tab/mouse/GlazeWM focus changes are never fought.
            restore_foreground_window(focus, foreground)
            return
        end

        -- Some other window became foreground first. Treat that as an
        -- intentional user/window-manager focus change and do not interfere.
    end

    vim.schedule(check)
end

local function wait_for_pid_exit(pid, timeout_ms, generation, callback)
    local deadline = now_ms() + timeout_ms

    local function check()
        if generation ~= state.generation then
            return
        end

        if not pid_alive(pid) then
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
    local lsp_config = {
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
    }

    -- godotdev.nvim currently launches an external `ncat` process on Windows.
    -- Neovim already has a native TCP LSP transport, so use it directly:
    --   * no extra ncat process
    --   * no ncat startup/exit noise
    --   * connects immediately once Godot's port is ready
    if vim.lsp.rpc and type(vim.lsp.rpc.connect) == "function" and state.lsp_port then
        lsp_config.cmd = vim.lsp.rpc.connect(HOST, state.lsp_port)
    end

    vim.lsp.config("gdscript", lsp_config)
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

local function request_normal_close(pid, callback)
    if not pid_alive(pid) then
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
        tostring(pid),
    }, {
        text = true,
    }, function(result)
        vim.schedule(function()
            if not pid_alive(pid) then
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

local function force_kill_pid(pid)
    if not pid_alive(pid) then
        return
    end

    pcall(uv.kill, pid, "sigterm")
end

local function close_managed_godot(opts, callback)
    opts = opts or {}

    -- opts.pid 用于“关掉切换之前的那个实例”，此时 state 里已经是新实例了。
    local pid = tonumber(opts.pid) or managed_pid()
    if not pid then
        state.godot_process = nil
        state.godot_process_pid = nil
        callback(true)
        return
    end

    local generation = state.generation

    local function finish()
        if process_running(state.godot_process) and tonumber(state.godot_process_pid) == pid then
            state.godot_process = nil
            state.godot_process_pid = nil
        end

        if state.adopted and state.adopted.source == "managed" and tonumber(state.adopted.pid) == pid then
            state.adopted = nil
        end
    end

    if opts.force then
        force_kill_pid(pid)
        wait_for_pid_exit(pid, config.force_close_timeout_ms, generation, function(exited)
            if not exited and pid_alive(pid) then
                pcall(uv.kill, pid, "sigkill")
            end

            wait_for_pid_exit(pid, config.force_close_timeout_ms, generation, function(exited_after_kill)
                if exited_after_kill then
                    finish()
                    callback(true)
                else
                    callback(false, "Godot process did not exit after force close")
                end
            end)
        end)
        return
    end

    request_normal_close(pid, function(close_requested, err)
        if not close_requested then
            callback(false, err)
            return
        end

        wait_for_pid_exit(pid, config.close_timeout_ms, generation, function(exited)
            if exited then
                finish()
                callback(true)
                return
            end

            callback(false, "Godot is still running. Finish or cancel its save/close dialog, then retry. Use ! only if you accept losing unsaved Godot editor changes.")
        end)
    end)
end

-- 用 uv.spawn 而不是 vim.system 启动 Godot，原因有两个：
--
--   1. vim.system 硬编码了 hide = true，libuv 会据此设置
--      STARTF_USESHOWWINDOW + SW_HIDE。结果是 Godot 的编辑器窗口以隐藏状态
--      创建：你看不到它，而且它没有 MainWindowHandle，于是
--      lua/tools/godot-close.ps1（:GodotStop / :GodotRestart 的优雅关闭）
--      会报 "has no main window handle" 直接失败。
--   2. vim.system 不暴露 process handle，没法 unref。
--
-- stdio = { nil, nil, nil } 在 luv 里是 UV_IGNORE，Godot 的输出不会写进
-- Nvim 的终端。
local function spawn_godot(root, lsp_port, dap_port, on_exit)
    local handle, pid_or_error = uv.spawn(config.godot_path, {
        args = {
            "--editor",
            "--path",
            root,
            "--lsp-port",
            tostring(lsp_port),
            "--dap-port",
            tostring(dap_port),
        },
        cwd = root,
        stdio = { nil, nil, nil },
        -- keep_alive：让 Godot 活过 Nvim。
        --
        -- detached = false 时 libuv 会把子进程放进 job object，父进程一退出
        -- 就把它杀掉，于是每次启动 Nvim 都要重新冷启动一个编辑器。
        detached = config.keep_alive == true,
        -- 这里绝对不要加 hide，理由见上面第 1 条。
    }, function(code)
        on_exit(code)
    end)

    if not handle then
        return nil, tostring(pid_or_error)
    end

    if config.keep_alive == true then
        -- libuv 文档：detached 的子进程仍然会让父进程的事件循环保持存活，
        -- 除非父进程对它的 process handle 调用 unref。
        pcall(function()
            handle:unref()
        end)
    end

    return handle, tonumber(pid_or_error)
end

local function start_godot(root, generation, callback)
    local project_file = vim.fs.joinpath(root, "project.godot")
    if vim.fn.filereadable(project_file) ~= 1 then
        callback(false, "project.godot not found: " .. root, "launch")
        return
    end

    -- 固定住这一代实例的端口：启动过程中 state 里的端口不应该再变。
    local lsp_port = state.lsp_port
    local dap_port = state.dap_port

    local foreground_before_launch = capture_foreground_window()

    local process

    local function on_exit(code)
        vim.schedule(function()
            if state.godot_process ~= process then
                return
            end

            state.godot_process = nil
            state.godot_process_pid = nil
            forget_instance(root)
            disable_lsp()

            if code ~= nil and code ~= 0 then
                notify("Managed Godot exited with code " .. tostring(code), vim.log.levels.WARN)
            end
        end)
    end

    local godot_pid
    process, godot_pid = spawn_godot(root, lsp_port, dap_port, on_exit)

    if not process then
        callback(false, tostring(godot_pid), "launch")
        return
    end

    state.godot_process = process
    state.godot_process_pid = godot_pid

    guard_focus_after_godot_launch(foreground_before_launch, process, godot_pid)

    wait_for_port(lsp_port, true, config.startup_timeout_ms, generation, function(ready)
        if generation ~= state.generation then
            return
        end

        if not ready then
            callback(false, string.format(
                "Godot started, but LSP port %d did not become ready. The project remains owned by this Nvim; fix Godot's TCP LSP setting and run :GodotRestart.",
                lsp_port
            ), "lsp_timeout")
            return
        end

        -- 记下来，好让下一个 Nvim（或者 Nvim 重开之后）直接复用。
        if process_running(process) and godot_pid then
            record_instance(root, godot_pid, lsp_port, dap_port)
        end

        enable_lsp()
        callback(true)
    end)
end

local function ensure_plugin_ready(opts)
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

    notify_unless_silent(opts,
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
    state.adopted = nil
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

local function transition_guard(opts)
    if state.transitioning then
        notify_unless_silent(opts, "A Godot transition is already in progress", vim.log.levels.WARN)
        return false
    end

    return true
end

function M.activate(root, opts)
    opts = opts or {}

    -- Auto binding is intentionally one-shot. Once this Nvim owns a project,
    -- entering buffers from another project never switches it automatically.
    if opts.auto and state.active_root then
        return
    end

    root = normalize_path(root)
    if not root then
        notify_unless_silent(opts, "Invalid Godot project root", vim.log.levels.ERROR)
        return
    end

    if vim.fn.filereadable(vim.fs.joinpath(root, "project.godot")) ~= 1 then
        notify_unless_silent(opts, "project.godot not found:\n" .. root, vim.log.levels.ERROR)
        return
    end

    if not transition_guard(opts) then
        return
    end

    ------------------------------------------------------------
    -- 复用优先
    --
    -- 有已经在跑的 Godot（上一个 Nvim 托管启动并保活的，或者你自己开的那
    -- 个）就直接挂上去，省掉整个编辑器冷启动。
    --
    -- 必须发生在 ensure_plugin_ready() 之前：godotdev 的 setup 会读取
    -- state.lsp_port / state.dap_port，复用时要让它拿到复用实例的端口。
    ------------------------------------------------------------

    local previous_pid = managed_pid()
    local instance = probe_reusable_instance(root)

    -- 已经是当前项目、端口没变、实例也还在 —— 什么都不用做。
    if
        instance
        and same_path(root, state.active_root)
        and state.lsp_port == instance.lsp_port
        and (managed_alive() or instance.source == "external")
    then
        notify_unless_silent(opts, "Already active:\n" .. root)
        return
    end

    if instance then
        adopt_instance(instance)
    end

    if not ensure_plugin_ready(opts) then
        if instance then
            release_adopted()
        end
        return
    end

    -- 复用时这里直接返回，不会分配新的端口对。
    ensure_port_pair()

    local function notify_active(verb)
        notify_unless_silent(opts, string.format(
            "Godot %s:\n%s\nLSP :%d  DAP :%d\nInstance: %s",
            verb,
            root,
            state.lsp_port,
            state.dap_port,
            instance_source_label()
        ))
    end

    -- 要复用的实例不是“切换前正在用的那个托管实例”时，先把旧的关掉，
    -- 免得留下一堆孤儿编辑器。注意外部编辑器（你自己开的）不归我们管。
    local target_pid = instance and tonumber(instance.pid) or nil
    local must_close_previous = previous_pid ~= nil and previous_pid ~= target_pid

    if same_path(root, state.active_root) then
        state.transitioning = true
        state.generation = state.generation + 1
        local generation = state.generation

        local function start_again()
            disable_lsp()
            stop_dap_session()

            if instance then
                patch_lsp()
                patch_dap()
                enable_lsp()
                finish_transition()
                notify_active("reused")
                return
            end

            -- 要托管启动一个新实例：不能沿用复用实例的端口，重新分配一对。
            if state.adopted then
                release_adopted()
            end
            ensure_port_pair()

            patch_lsp()
            patch_dap()

            start_godot(root, generation, function(ok, err, failure_kind)
                if failure_kind == "launch" then
                    cleanup_active_project()
                end
                finish_transition()

                if not ok then
                    notify_unless_silent(opts, err, vim.log.levels.ERROR)
                    return
                end

                notify_active("active")
            end)
        end

        if must_close_previous then
            close_managed_godot({ force = opts.force == true, pid = previous_pid }, function(closed, err)
                if generation ~= state.generation then
                    return
                end

                if not closed then
                    finish_transition()
                    notify_unless_silent(opts, err or "Godot restart cancelled", vim.log.levels.WARN)
                    return
                end

                start_again()
            end)
            return
        end

        start_again()
        return
    end

    local target_server, acquire_error = acquire_project(root)
    if not target_server then
        -- This is the expected failure for auto-bind when another Nvim already
        -- owns the project, so silent auto-bind produces no warning popup.
        if instance then
            release_adopted()
        end
        notify_unless_silent(opts, acquire_error, vim.log.levels.WARN)
        return
    end

    state.transitioning = true
    state.generation = state.generation + 1
    local generation = state.generation
    local old_server = state.project_server

    local function abort_switch(message)
        release_server(target_server)
        finish_transition()
        if message then
            notify_unless_silent(opts, message, vim.log.levels.WARN)
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

        if instance then
            patch_lsp()
            patch_dap()
            enable_lsp()
            finish_transition()
            notify_active("reused")
            return
        end

        -- 要托管启动一个新实例：不能沿用复用实例的端口，重新分配一对。
        if state.adopted then
            release_adopted()
        end
        ensure_port_pair()

        patch_lsp()
        patch_dap()

        start_godot(root, generation, function(ok, err, failure_kind)
            if failure_kind == "launch" then
                -- The process never started. Do not leave a stale project pipe
                -- claiming ownership of a project with no managed Godot.
                cleanup_active_project()
            end

            finish_transition()

            if not ok then
                notify_unless_silent(opts, err, vim.log.levels.ERROR)
                return
            end

            notify_active("active")
        end)
    end

    if must_close_previous then
        close_managed_godot({ force = opts.force == true, pid = previous_pid }, function(closed, err)
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

function M.auto_bind(bufnr)
    if state.transitioning or state.active_root then
        return
    end

    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    local root = project_root_for_buf(bufnr)

    -- Covers starting Nvim from a Godot project with an unnamed initial buffer.
    if not root and vim.api.nvim_buf_get_name(bufnr) == "" then
        root = project_root_for_file(vim.fn.getcwd())
    end

    if not root then
        return
    end

    M.activate(root, {
        auto = true,
        silent = true,
    })
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
            local marker = same_path(root, state.active_root) and "* " or "  "
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

    local external = state.adopted ~= nil and state.adopted.source == "external"

    local function start_again()
        disable_lsp()
        stop_dap_session()

        -- 新实例要用新的端口对，复用的那一对还回去。
        if state.adopted then
            release_adopted()
        end
        ensure_port_pair()

        patch_lsp()
        patch_dap()

        start_godot(root, generation, function(ok, err, failure_kind)
            if failure_kind == "launch" then
                cleanup_active_project()
            end
            finish_transition()

            if not ok then
                notify(err, vim.log.levels.ERROR)
                return
            end

            notify(string.format(
                "Godot restarted:\n%s\nLSP :%d  DAP :%d\nInstance: %s%s",
                root,
                state.lsp_port,
                state.dap_port,
                instance_source_label(),
                external and "\n(你手动开的那个 Godot 编辑器仍然在运行)" or ""
            ))
        end)
    end

    if managed_alive() then
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
        local was_external = state.adopted ~= nil and state.adopted.source == "external"
        local stopped_root = state.active_root

        cleanup_active_project()

        -- 外部编辑器不归我们管，记录也留着（下次还能复用）。
        if stopped_root and not was_external then
            forget_instance(stopped_root)
        end

        finish_transition()
        notify(was_external
            and "Detached from the external Godot editor (it keeps running)"
            or "Godot instance stopped")
    end

    if managed_alive() then
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

    -- godotdev 想把 client 命名成 "godot_editor"，但 patch_lsp() 里
    -- vim.lsp.config("gdscript", ...) 之后实际注册的名字是 "gdscript"，
    -- 所以两个都认（否则这里永远显示 false）。
    for _, client in ipairs(vim.lsp.get_clients()) do
        if client.name == "gdscript" or client.name == "godot_editor" then
            if state.active_root and same_path(client.root_dir, state.active_root) then
                active_client = client
                break
            end
        end
    end

    local pid = managed_pid()
    local godot_pid = pid and tostring(pid) or "-"

    if not pid and state.adopted and state.adopted.source == "external" then
        godot_pid = "external (not managed)"
    end

    local lines = {
        string.format("Nvim PID    : %d", vim.fn.getpid()),
        string.format("Nvim server : %s", vim.v.servername ~= "" and vim.v.servername or "-"),
        "",
        string.format("Project     : %s", state.active_root or "-"),
        string.format("Project RPC : %s", state.project_server or "-"),
        string.format("Instance    : %s", instance_source_label()),
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
    opts.autostart_editor_server = false

    if opts.godot_path then
        config.godot_path = opts.godot_path
    end

    return opts
end

local function disable_godotdev_editor_server()
    -- The project-specific RPC pipe is owned by this manager. godotdev.nvim's
    -- generic editor-server autostart layer is redundant in this architecture
    -- and can race with another Nvim instance, so remove the automatic hook.
    pcall(vim.api.nvim_del_augroup_by_name, "godotdev_start_editor_server")

    if vim.fn.exists(":GodotStartEditorServer") == 2 then
        pcall(vim.api.nvim_del_user_command, "GodotStartEditorServer")
    end

    vim.api.nvim_create_user_command("GodotStartEditorServer", function()
        if state.project_server then
            notify("Godot editor RPC is already managed by this Nvim:\n" .. state.project_server)
        else
            notify("Godot editor RPC will be created automatically when this Nvim binds a Godot project")
        end
    end, {
        desc = "Show the project-specific Godot editor RPC server managed by godot_instance",
    })
end

function M.after_godotdev_setup(opts)
    opts = opts or {}

    if opts.godot_path then
        config.godot_path = opts.godot_path
    end

    ensure_port_pair()

    -- gdscript.lua suppresses godotdev's one eager vim.lsp.enable() call.
    -- Keep it disabled here as a second guard until the managed Godot LSP
    -- TCP port is actually accepting connections.
    disable_lsp()
    patch_lsp()
    patch_dap()
    disable_godotdev_editor_server()
    state.plugin_ready = true
end

local function setup_remote_open()
    _G.godot_remote_open = function(encoded_file, line, column)
        if not vim.base64 or not vim.base64.decode then
            error("vim.base64.decode is unavailable")
        end

        local ok_decode, file = pcall(vim.base64.decode, encoded_file)
        if not ok_decode or not file or file == "" then
            error("invalid Godot remote-open path")
        end

        local root = project_root_for_file(file)
        if not state.active_root or not root or not same_path(root, state.active_root) then
            error("Godot remote-open project does not match this Nvim")
        end

        line = tonumber(line) or 1
        column = tonumber(column) or 1
        line = math.max(math.floor(line), 1)
        column = math.max(math.floor(column), 1)

        vim.schedule(function()
            -- Re-check after scheduling in case the active project changed.
            local scheduled_root = project_root_for_file(file)
            if not state.active_root or not scheduled_root or not same_path(scheduled_root, state.active_root) then
                return
            end

            local ok_drop, err = pcall(vim.api.nvim_cmd, {
                cmd = "drop",
                args = { file },
                magic = { file = false, bar = false },
            }, {})

            if not ok_drop then
                notify("Godot remote open failed:\n" .. tostring(err), vim.log.levels.ERROR)
                return
            end

            -- Preserve the old router's cursor() semantics: both values are
            -- 1-based and Vim handles clamping for us.
            pcall(vim.fn.cursor, line, column)
        end)

        return 1
    end
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
    setup_remote_open()

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

    local group = vim.api.nvim_create_augroup("godot_instance_manager", { clear = true })

    -- Auto-bind only while this Nvim has no active Godot project. The actual
    -- ownership claim is still the project-specific named pipe, so another
    -- Nvim already owning the project makes this a silent no-op.
    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(args)
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then
                    M.auto_bind(args.buf)
                end
            end)
        end,
    })

    -- If bootstrap happens after the initial BufEnter, or Nvim starts in a
    -- Godot project with an unnamed buffer, this catches the initial project.
    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        once = true,
        callback = function()
            vim.schedule(function()
                M.auto_bind(vim.api.nvim_get_current_buf())
            end)
        end,
    })

    -- Never force-kill Godot during Nvim shutdown: that could discard unsaved
    -- scene/resource changes. Pipe ownership disappears with the Nvim process.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            disable_lsp()
            stop_dap_session()
        end,
    })

    state.bootstrapped = true

    -- Covers configurations where commands.lua is sourced after VimEnter.
    vim.schedule(function()
        M.auto_bind(vim.api.nvim_get_current_buf())
    end)
end

return M
