local helpers = require("tests.helpers")

local fixture_dir = helpers.fixture_path("")
local cases = {}

for name, kind in vim.fs.dir(fixture_dir) do
  if kind == "file" and name:match("%.input%.js$") then
    table.insert(cases, (name:gsub("%.input%.js$", "")))
  end
end
table.sort(cases)

describe("golden indentation fixtures", function()
  for _, name in ipairs(cases) do
    it(name, function()
      local input_path = helpers.fixture_path(name .. ".input.js")
      local expected_path = helpers.fixture_path(name .. ".expected.js")
      assert(vim.uv.fs_stat(expected_path), "missing expected fixture: " .. expected_path)

      local input = helpers.read_lines(input_path)
      local expected = helpers.read_lines(expected_path)
      local bufnr = helpers.new_javascript_buffer(input)

      vim.cmd("normal! gg=G")

      assert.are.same(expected, helpers.buffer_lines(bufnr))
    end)
  end
end)
