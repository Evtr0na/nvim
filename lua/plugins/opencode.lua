local port = 4096
local url = "http://127.0.0.1:" .. port

local function start_opencode()
    local cwd = vim.fn.getcwd()

    vim.system({
        "wezterm",
        "cli",
        "spawn",
        "--new-window",
        "--cwd",
        cwd,
        "--",
        "cmd.exe",
        "/c",
        "opencode",
        "--port",
        tostring(port),
    })
end

return {
    "nickjvandyke/opencode.nvim",

    version = "*",

    keys = {
        {
            "<leader>ao",
            function()
                require("opencode").ask("@buffer: ")
            end,
            mode = "n",
            desc = "OpenCode Ask Buffer",
        },

        {
            "<leader>ao",
            function()
                require("opencode").ask("@this: ")
            end,
            mode = "x",
            desc = "OpenCode Ask Selection",
        },

        -- {
        --     "<leader>aa",
        --     function()
        --         require("opencode").select()
        --     end,
        --     mode = { "n", "x" },
        --     desc = "OpenCode Actions",
        -- },
        --
        --     {
        --         "<leader>on",
        --         function()
        --             require("opencode").command("session.new")
        --         end,
        --         desc = "OpenCode New Session",
        --     },
        --
        --     {
        --         "<leader>os",
        --         function()
        --             require("opencode").command("session.select")
        --         end,
        --         desc = "OpenCode Sessions",
        --     },
        --
        --     {
        --         "<leader>oc",
        --         function()
        --             require("opencode").command("session.compact")
        --         end,
        --         desc = "OpenCode Compact",
        --     },
        --
        --     {
        --         "<leader>om",
        --         function()
        --             require("opencode").command("agent.cycle")
        --         end,
        --         desc = "OpenCode Cycle Agent",
        --     },
    },

    config = function()
        vim.g.opencode_opts = {
            server = {
                url = url,

                start = start_opencode,
            },
        }

        vim.o.autoread = true
    end,
}
