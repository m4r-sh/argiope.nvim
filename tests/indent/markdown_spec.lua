local helpers = require("tests.helpers")

describe("Markdown fenced JavaScript indentation", function()
  it("formats tagged HTML structurally without accumulating fence offsets", function()
    local input = {
      "# Example",
      "",
      "```js",
      "export default ({",
      "        info={},",
      "        toc=[]",
      "        }={}) => html`",
      "<div class=${WRAP}>",
      "<div class=${INFO}>",
      "",
      "</div>",
      "<div class=${TOC}>",
      "${toc.map(item => html`",
      "        <a class=${ITEM} href=${item.href}>",
      "        <span class=${ITEM.TITLE}>",
      "        ${item.name}",
      "        </span>",
      "        </a>",
      "        `)}",
      "</div>",
      "</div>",
      "`",
      "```",
    }
    vim.cmd("enew!")
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, input)
    vim.bo[bufnr].expandtab = true
    vim.bo[bufnr].shiftwidth = 2
    vim.bo[bufnr].softtabstop = 2
    vim.bo[bufnr].tabstop = 2
    vim.bo[bufnr].filetype = "markdown"
    assert(require("argiope").attach(bufnr))
    local languages = {}
    local parser = vim.treesitter.get_parser(bufnr, "markdown")
    assert(parser:parse(true))
    parser:for_each_tree(function(_, tree)
      languages[tree:lang()] = true
    end)
    assert.is_true(languages.javascript, vim.inspect(languages))

    vim.cmd("normal! gg=G")

    assert.are.same({
      "# Example",
      "",
      "```js",
      "export default ({",
      "  info={},",
      "  toc=[]",
      "}={}) => html`",
      "  <div class=${WRAP}>",
      "    <div class=${INFO}>",
      "",
      "    </div>",
      "    <div class=${TOC}>",
      "      ${toc.map(item => html`",
      "        <a class=${ITEM} href=${item.href}>",
      "          <span class=${ITEM.TITLE}>",
      "            ${item.name}",
      "          </span>",
      "        </a>",
      "      `)}",
      "    </div>",
      "  </div>",
      "`",
      "```",
    }, helpers.buffer_lines(bufnr))
  end)
end)
