return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",

  keys = {
    {
      "<leader>m",
      function()
        require("config.mc_mode").enter()
      end,
      desc = "Enter MC select mode",
    },
  },

config = function()
  local mc = require("multicursor-nvim")

  mc.setup()

  vim.keymap.set("n", "<Esc>", function()
    local mode = require("config.mc_mode")

    if mode.active then
      -- MC SELECT:
      -- 退出 MC 模式，保留已经选好的副光标
      mode.leave()
      return
    end

    if mc.hasCursors() then
      -- 普通 Normal + multicursor:
      -- 删除所有副光标
      mc.clearCursors()
    end
  end, {
    desc = "Exit MC mode / clear multicursors",
  })
end,
}
