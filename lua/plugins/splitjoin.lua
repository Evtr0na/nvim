--括号内自动换行

return {
  {
    "nvim-mini/mini.splitjoin",
    version = false,


    keys = {
      { "gS", mode = { "n", "x" } },
    },


    config = function()
      require("mini.splitjoin").setup({
        mappings = {
          toggle = "gS",
          split = "",
          join = "",
        },
      })
    end,
  },
}
