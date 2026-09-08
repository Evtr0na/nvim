local M = {}

local namespace = vim.api.nvim_create_namespace("glslang")

------------------------------------------------------------
-- Executable
------------------------------------------------------------

local function get_executable()
    if vim.fn.executable("glslangValidator") == 1 then
        return "glslangValidator"
    end

    return nil
end
------------------------------------------------------------
-- Shader stages
------------------------------------------------------------

-- Godot RDShaderFile section -> glslang stage
local section_stages = {
    vertex = "vert",
    fragment = "frag",

    -- Godot historically uses the misspelled "tesselation".
    tesselation_control = "tesc",
    tesselation_evaluation = "tese",

    -- Also accept the correctly spelled version.
    tessellation_control = "tesc",
    tessellation_evaluation = "tese",

    compute = "comp",

    -- Newer RenderingDevice ray-tracing stages.
    raygen = "rgen",
    any_hit = "rahit",
    closest_hit = "rchit",
    miss = "rmiss",
    intersection = "rint",
}

-- Filename -> glslang stage
local filename_stages = {
    vert = "vert",
    vertex = "vert",

    frag = "frag",
    fragment = "frag",

    comp = "comp",
    compute = "comp",

    tesc = "tesc",
    tese = "tese",

    rgen = "rgen",
    rahit = "rahit",
    rchit = "rchit",
    rmiss = "rmiss",
    rint = "rint",
}

------------------------------------------------------------
-- Detect shader stage
------------------------------------------------------------

local function stage_from_filename(path)
    local filename = vim.fs.basename(path)

    --------------------------------------------------------
    -- foo.comp.glsl
    -- foo.frag.glsl
    -- foo.vert.glsl
    --------------------------------------------------------

    local stage = filename:match("%.([^.]+)%.glsl$")

    if stage and filename_stages[stage] then
        return filename_stages[stage]
    end

    --------------------------------------------------------
    -- foo.comp
    -- foo.frag
    -- foo.vert
    --------------------------------------------------------

    stage = filename:match("%.([^.]+)$")

    if stage and filename_stages[stage] then
        return filename_stages[stage]
    end

    return nil
end

------------------------------------------------------------
-- Remove comments before source analysis
------------------------------------------------------------

local function strip_comments(lines)
    local result = {}
    local in_block_comment = false

    for _, line in ipairs(lines) do
        local parts = {}
        local index = 1

        while index <= #line do
            ------------------------------------------------
            -- Inside /* ... */
            ------------------------------------------------

            if in_block_comment then
                local close_start, close_end = line:find("*/", index, true)

                if close_start then
                    in_block_comment = false
                    index = close_end + 1
                else
                    break
                end

            ------------------------------------------------
            -- Normal source
            ------------------------------------------------
            else
                local line_comment = line:find("//", index, true)

                local block_comment = line:find("/*", index, true)

                ------------------------------------------------
                -- // comes first
                ------------------------------------------------

                if line_comment and (not block_comment or line_comment < block_comment) then
                    parts[#parts + 1] = line:sub(index, line_comment - 1)

                    break

                ------------------------------------------------
                -- /* comes first
                ------------------------------------------------
                elseif block_comment then
                    parts[#parts + 1] = line:sub(index, block_comment - 1)

                    in_block_comment = true
                    index = block_comment + 2

                ------------------------------------------------
                -- No comments
                ------------------------------------------------
                else
                    parts[#parts + 1] = line:sub(index)

                    break
                end
            end
        end

        result[#result + 1] = table.concat(parts)
    end

    return result
end

------------------------------------------------------------
-- Explicit source declaration
--
--     // glsl-stage: comp
--     // glsl-stage: frag
--     // glsl-stage: vert
------------------------------------------------------------

local function stage_from_header(lines)
    for i = 1, math.min(#lines, 30) do
        local stage = lines[i]:match("^%s*//%s*glsl%-stage:%s*([%w_]+)%s*$")

        if stage and filename_stages[stage] then
            return filename_stages[stage]
        end

        ----------------------------------------------------
        -- Also understand:
        --
        -- #pragma shader_stage(compute)
        ----------------------------------------------------

        stage = lines[i]:match("^%s*#pragma%s+shader_stage%s*%(%s*([%w_]+)%s*%)")

        if stage and filename_stages[stage] then
            return filename_stages[stage]
        end
    end

    return nil
end

------------------------------------------------------------
-- Detect stage from GLSL source
------------------------------------------------------------

local function stage_from_source(lines)
    --------------------------------------------------------
    -- Explicit declaration always wins.
    --------------------------------------------------------

    local explicit = stage_from_header(lines)

    if explicit then
        return explicit
    end

    --------------------------------------------------------
    -- Ignore comments during automatic inference.
    --------------------------------------------------------

    local clean_lines = strip_comments(lines)

    local source = table.concat(clean_lines, "\n")

    -- Makes multiline layout(...) easier to inspect.
    local compact = source:gsub("%s+", " ")

    --------------------------------------------------------
    -- Compute
    --------------------------------------------------------

    local compute_markers = {
        "gl_GlobalInvocationID",
        "gl_LocalInvocationID",
        "gl_LocalInvocationIndex",
        "gl_WorkGroupID",
        "gl_NumWorkGroups",
        "gl_WorkGroupSize",
    }

    for _, marker in ipairs(compute_markers) do
        if source:find(marker, 1, true) then
            return "comp"
        end
    end

    -- layout(
    --     local_size_x = 8,
    --     local_size_y = 8
    -- ) in;
    if compact:match("layout%s*%([^%)]*local_size_[xyz]%s*=") then
        return "comp"
    end

    --------------------------------------------------------
    -- Geometry
    --------------------------------------------------------

    if
        source:find("EmitVertex", 1, true)
        or source:find("EndPrimitive", 1, true)
        or source:find("EmitStreamVertex", 1, true)
        or source:find("EndStreamPrimitive", 1, true)
    then
        return "geom"
    end

    --------------------------------------------------------
    -- Tessellation evaluation
    --------------------------------------------------------

    if source:find("gl_TessCoord", 1, true) then
        return "tese"
    end

    --------------------------------------------------------
    -- Fragment
    --------------------------------------------------------

    local fragment_markers = {
        "gl_FragCoord",
        "gl_FrontFacing",
        "gl_PointCoord",
        "gl_FragDepth",
        "gl_SampleID",
        "gl_SamplePosition",
        "gl_SampleMaskIn",
    }

    for _, marker in ipairs(fragment_markers) do
        if source:find(marker, 1, true) then
            return "frag"
        end
    end

    -- discard is fragment-only in normal GLSL usage.
    if source:match("%f[%a]discard%f[%A]") then
        return "frag"
    end

    --------------------------------------------------------
    -- Vertex
    --------------------------------------------------------

    local vertex_markers = {
        -- Vulkan GLSL
        "gl_VertexIndex",
        "gl_InstanceIndex",

        -- OpenGL-style GLSL
        "gl_VertexID",
        "gl_InstanceID",
    }

    for _, marker in ipairs(vertex_markers) do
        if source:find(marker, 1, true) then
            return "vert"
        end
    end

    --------------------------------------------------------
    -- Do NOT blindly use gl_Position.
    --
    -- gl_Position can also occur in geometry/tessellation
    -- shaders, so guessing "vert" from that alone is unsafe.
    --------------------------------------------------------

    return nil
end

------------------------------------------------------------
-- Final stage detection
------------------------------------------------------------

local function detect_stage(lines, path)
    --------------------------------------------------------
    -- Filename is authoritative.
    --------------------------------------------------------

    local stage = stage_from_filename(path)

    if stage then
        return stage
    end

    --------------------------------------------------------
    -- Plain *.glsl:
    -- inspect its source.
    --------------------------------------------------------

    return stage_from_source(lines)
end
------------------------------------------------------------
-- Create glslang jobs
--
-- Supports:
--
-- Standard GLSL:
--
--     foo.comp
--     foo.frag
--     foo.comp.glsl
--
-- Godot RDShaderFile:
--
--     #[vertex]
--     ...
--     #[fragment]
--     ...
--
-- We replace all other sections with blank lines so that
-- glslang line numbers remain identical to the source file.
------------------------------------------------------------

local function create_jobs(lines, path)
    local sections = {}

    local current_stage = nil
    local has_godot_sections = false

    for line_number, line in ipairs(lines) do
        local section = line:match("^%s*#%[([%w_]+)%]")

        if section then
            -- Any #[...] closes the current GLSL section.
            current_stage = section_stages[section]

            if current_stage then
                has_godot_sections = true

                sections[current_stage] = sections[current_stage] or {}
            end
        elseif current_stage then
            sections[current_stage][line_number] = line
        end
    end

    --------------------------------------------------------
    -- Godot-style GLSL
    --------------------------------------------------------

    if has_godot_sections then
        local jobs = {}

        for stage, source_lines in pairs(sections) do
            local output = {}

            -- Keep the exact original number of lines.
            for i = 1, #lines do
                output[i] = source_lines[i] or ""
            end

            jobs[#jobs + 1] = {
                stage = stage,
                source = table.concat(output, "\n"),
            }
        end

        return jobs
    end

    --------------------------------------------------------
    -- Standard GLSL
    --------------------------------------------------------

    local stage = detect_stage(lines, path)

    if not stage then
        return {}
    end

    return {
        {
            stage = stage,
            source = table.concat(lines, "\n"),
        },
    }
end

------------------------------------------------------------
-- Parse glslang diagnostics
------------------------------------------------------------

local ignored_messages = {
    "compilation terminated",
    "No code generated",
}

local function should_ignore(message)
    for _, pattern in ipairs(ignored_messages) do
        if message:find(pattern, 1, true) then
            return true
        end
    end

    return false
end

local function parse_output(output, stage)
    local diagnostics = {}

    for line in output:gmatch("[^\r\n]+") do
        local severity
        local rest

        severity, rest = line:match("^([%a]+):%s*(.*)$")

        if severity then
            severity = severity:upper()

            if severity == "ERROR" or severity == "WARNING" then
                -- Examples:
                --
                -- ERROR: stdin:10: message
                -- ERROR: 0:10: message
                -- ERROR: shader.comp:10: message
                --
                local _, lnum, message = rest:match("^(.-):(%d+):%s*(.*)$")

                if lnum and not should_ignore(message) then
                    diagnostics[#diagnostics + 1] = {
                        lnum = math.max(tonumber(lnum) - 1, 0),

                        col = 0,

                        severity = severity == "ERROR" and vim.diagnostic.severity.ERROR
                            or vim.diagnostic.severity.WARN,

                        message = ("[%s] %s"):format(stage, message),

                        source = "glslang",
                    }
                end
            end
        end
    end

    return diagnostics
end

------------------------------------------------------------
-- Lint
------------------------------------------------------------

function M.lint(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    local executable = get_executable()

    if not executable then
        vim.notify_once("glslang/glslangValidator not found", vim.log.levels.WARN)

        return
    end

    local path = vim.api.nvim_buf_get_name(bufnr)

    if path == "" then
        return
    end

    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local jobs = create_jobs(lines, path)

    --------------------------------------------------------
    -- A plain foo.glsl has no shader stage.
    --
    -- It may simply be an include/library, so don't report
    -- that as an error.
    --------------------------------------------------------

    if #jobs == 0 then
        vim.diagnostic.reset(namespace, bufnr)

        return
    end

    local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

    local cwd = vim.fs.dirname(path)

    local diagnostics = {}
    local pending = #jobs

    for _, job in ipairs(jobs) do
        --------------------------------------------------------
        -- Temporary files
        --------------------------------------------------------

        -- Give the temporary shader a real stage extension.
        --
        -- Example:
        --     C:/.../tmp123.comp
        --
        -- This also makes glslang happy even without relying
        -- on the original *.glsl filename.
        local temp_shader = vim.fn.tempname() .. "." .. job.stage

        local temp_spv = vim.fn.tempname() .. ".spv"

        --------------------------------------------------------
        -- Write sanitized shader
        --------------------------------------------------------

        local file, err = io.open(temp_shader, "wb")

        if not file then
            vim.notify("GLSLang: failed to create temporary shader: " .. tostring(err), vim.log.levels.ERROR)

            return
        end

        file:write(job.source)
        file:close()

        --------------------------------------------------------
        -- Command
        --------------------------------------------------------

        local command = {
            executable,

            -- Continue parsing after errors.
            "-C",

            -- Vulkan GLSL / SPIR-V rules.
            "-V",

            -- Shader stage.
            "-S",
            job.stage,

            "-o",
            temp_spv,
        }
        --------------------------------------------------------
        -- Includes
        --------------------------------------------------------

        if cwd then
            command[#command + 1] = "-I" .. cwd
        end

        --------------------------------------------------------
        -- Input
        --------------------------------------------------------

        command[#command + 1] = temp_shader

        --------------------------------------------------------
        -- Run glslang
        --------------------------------------------------------

        vim.system(command, {
            text = true,
            cwd = cwd,
        }, function(result)
            ------------------------------------------------
            -- Cleanup
            ------------------------------------------------

            os.remove(temp_shader)
            os.remove(temp_spv)

            ------------------------------------------------
            -- Output
            ------------------------------------------------

            local output = (result.stdout or "") .. "\n" .. (result.stderr or "")

            local result_diagnostics = parse_output(output, job.stage)

            vim.list_extend(diagnostics, result_diagnostics)

            pending = pending - 1

            if pending ~= 0 then
                return
            end

            ------------------------------------------------
            -- Publish
            ------------------------------------------------

            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(bufnr) then
                    return
                end

                -- Ignore stale results.
                if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
                    return
                end

                vim.diagnostic.set(namespace, bufnr, diagnostics)
            end)
        end)
    end
end
------------------------------------------------------------
-- Autocmd
------------------------------------------------------------

local group = vim.api.nvim_create_augroup("GLSLangDiagnostics", {
    clear = true,
})

vim.api.nvim_create_autocmd({
    "BufReadPost",
    "BufWritePost",
    "InsertLeave",
}, {
    group = group,

    pattern = {
        "*.glsl",

        "*.vert",
        "*.frag",
        "*.comp",
        "*.tesc",
        "*.tese",

        "*.rgen",
        "*.rahit",
        "*.rchit",
        "*.rmiss",
        "*.rint",
    },

    callback = function(args)
        M.lint(args.buf)
    end,
})

------------------------------------------------------------
-- :GLSLang
------------------------------------------------------------

vim.api.nvim_create_user_command("GLSLang", function()
    M.lint()
end, {})

return M
