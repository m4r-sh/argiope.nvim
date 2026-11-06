local helpers = require('tests.helpers')

local lines = {
  "const { TITLE, BUTTON } = classify('Example')",
  'TITLE; BUTTON',
  'const { key: alias, a: VAL = INITIAL, shorthand = FALLBACK, ...remaining } = source',
  'const [ITEM, fallback = FALLBACK, ...rest] = source',
  'let { OTHER } = source',
}

local function captures(buf, line, text)
  local col = assert(lines[line]:find(text, 1, true)) - 1
  return vim.treesitter.get_captures_at_pos(buf, line - 1, col)
end

local function priority(items, capture)
  local highest
  for _, item in ipairs(items) do
    if item.lang == 'javascript' and item.capture == capture then
      local value = tonumber(item.metadata.priority) or vim.hl.priorities.treesitter
      if not highest or value > highest then highest = value end
    end
  end
  return highest
end

describe('JavaScript const declaration captures', function()
  local buf
  before_each(function()
    require('argiope').setup()
    buf = helpers.new_javascript_buffer(lines)
    assert(vim.treesitter.get_parser(buf, 'javascript'):parse(true))
  end)

  it('prioritizes uppercase destructured bindings over constant captures', function()
    for _, text in ipairs({ 'TITLE', 'BUTTON' }) do
      local items = captures(buf, 1, text)
      assert.is_true(priority(items, 'argiope.const.variable') > priority(items, 'constant'))
      assert.is_nil(priority(captures(buf, 2, text), 'argiope.const.variable'))
    end
  end)

  it('captures alias, default, array and rest binding positions only', function()
    for _, entry in ipairs({ {3, 'alias'}, {3, 'VAL'}, {3, 'shorthand'}, {3, 'remaining'},
      {4, 'ITEM'}, {4, 'fallback'}, {4, 'rest'} }) do
      assert.are.equal(115, priority(captures(buf, entry[1], entry[2]), 'argiope.const.variable'))
    end
    for _, entry in ipairs({ {3, 'key'}, {3, 'INITIAL'}, {3, 'FALLBACK'}, {5, 'OTHER'} }) do
      assert.is_nil(priority(captures(buf, entry[1], entry[2]), 'argiope.const.variable'))
    end
  end)
end)
