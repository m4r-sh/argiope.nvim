local root = assert(vim.env.ARGIOPE_ROOT, "ARGIOPE_ROOT is not set")
local source = vim.fs.joinpath(root, "palette", "theme.js")

local function regenerate()
  vim.cmd.update()

  local result = vim.system({ "bun", "run", "palette" }, {
    cwd = root,
    text = true,
  }):wait()

  if result.code ~= 0 then
    local message = result.stderr ~= "" and result.stderr or result.stdout
    vim.notify(message, vim.log.levels.ERROR, { title = "Argiope palette" })
    return
  end

  package.loaded["argiope.generated.palette"] = nil
  package.loaded["argiope.palette"] = nil
  package.loaded["argiope.theme"] = nil
  require("argiope.theme").apply()
  vim.cmd.redraw()
  vim.notify("Palette regenerated and reloaded", vim.log.levels.INFO, {
    title = "Argiope palette",
  })
end

vim.api.nvim_create_user_command("ArgiopePaletteEdit", function()
  vim.cmd.vsplit(vim.fn.fnameescape(source))
end, { desc = "Edit the Argiope HSL palette source" })

vim.api.nvim_create_user_command("ArgiopePaletteReload", regenerate, {
  desc = "Generate and reload the Argiope palette",
})

vim.keymap.set("n", "<leader>pe", "<Cmd>ArgiopePaletteEdit<CR>", {
  desc = "Edit Argiope palette",
})
vim.keymap.set("n", "<leader>pr", regenerate, {
  desc = "Regenerate and reload Argiope palette",
})
