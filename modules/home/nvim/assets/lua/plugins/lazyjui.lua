return {
  "mrdwarf7/lazyjui.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  cmd = "LazyJui",
  keys = {
    {
      "<leader>jj",
      function()
        require("lazyjui").open()
      end,
      desc = "Open LazyJui (jjui)",
    },
  },
  opts = {
    use_default_keymaps = false,
  },
}
