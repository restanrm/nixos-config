return {
  "AntonVanAssche/md-headers.nvim",
  cmd = { "MDHeaders", "MDHeadersCurrent", "MDHeadersQuickfix", "MDHeadersTelescope" },
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "markdown", "html" })
      end,
    },
  },
  ft = { "markdown" },
  keys = {
    { "<leader>mh", "<cmd>MDHeaders<cr>", desc = "Markdown headings" },
  },
  opts = {},
}
