local oz = require("oz")

vim.api.nvim_create_autocmd({ "BufEnter" }, {
  pattern = { "*.oz" },
  callback = function(args)
    oz.start_engine()

    vim.api.nvim_create_user_command("OzEnginePath", function()
      oz.engine_path()
    end, {})

    vim.api.nvim_create_user_command("OzFeedFile", function()
      oz.feed_file(args.buf)
    end, {})

    vim.api.nvim_create_user_command("OzEngineRestart", function()
      oz.restart_engine()
    end, {})

    vim.keymap.set("v", oz.config.opt.keymap, function()
      oz.feed_selection(args.buf)
    end, { desc = "Feed the current selection into the oz engine" })
  end,
})
