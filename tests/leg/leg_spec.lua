-- Optional parser integration: run `VIMOTE_SOURCE=... bun run test:leg`.
if not vim.env.ARGIOPE_LEG_RUNTIME then return end
local helpers = require('tests.helpers')

describe('Leg templates', function()
  before_each(function() require('argiope').setup() end)
  it('highlights Leg syntax around JavaScript expressions and source escapes', function()
    local lines = {
      'const edit = leg`',
      '  @begin greeting',
      '  @note Add a greeting.',
      '  /: \\Vhello',
      '  i: ${name}<CR>',
      '  @mark inserted',
      '  @end greeting',
      '`;',
    }
    local buf = helpers.new_javascript_buffer(lines)
    local parser = vim.treesitter.get_parser(buf, 'javascript')
    assert(parser:parse(true))
    local found = false
    parser:for_each_tree(function(tree, language)
      if language:lang() == 'leg' then
        found = true
        assert.is_false(tree:root():has_error())
      end
    end)
    assert.is_true(found)
    local function captured(row, col, lang, capture)
      for _, item in ipairs(vim.treesitter.get_captures_at_pos(buf, row, col)) do
        if item.lang == lang and item.capture == capture then return true end
      end
      return false
    end
    assert.is_true(captured(1, 3, 'leg', 'keyword'))
    assert.is_true(captured(2, 10, 'leg', 'comment'))
    assert.is_true(captured(5, 9, 'leg', 'label'))
    assert.is_true(captured(4, 12, 'leg', 'constant.builtin'))
    assert.is_true(captured(4, 8, 'javascript', 'variable'))
    for _, item in ipairs(vim.treesitter.get_captures_at_pos(buf, 4, 8)) do
      assert.is_not.equal('leg', item.lang)
    end
    assert.is_not_nil(require('argiope.render').html(table.concat(lines, '\n')):find('inserted', 1, true))
  end)

  it('keeps separate inline templates in separate Leg parses', function()
    local source = 'const a = leg`@mark start`; const b = vimote.leg`i: ${value}<CR>`;'
    local parser = vim.treesitter.get_string_parser(source, 'javascript')
    assert(parser:parse(true))
    local count = 0
    parser:for_each_tree(function(tree, lang)
      if lang:lang() == 'leg' then
        count = count + 1
        assert.is_false(tree:root():has_error())
      end
    end)
    assert.are.equal(2, count)
  end)

  it('uses Leg comments and a flat indentation baseline for aliases', function()
    require('argiope').setup({tags = { edit = 'leg' }})
    local buf = helpers.new_javascript_buffer({'const edit = vimote.edit`', '  i: hello', '`;'})
    assert(vim.treesitter.get_parser(buf):parse(true))
    require('vim._comment').toggle_lines(2, 2, {2, 3})
    assert.are.equal('  // i: hello', helpers.buffer_lines(buf)[2])
    vim.cmd('normal! gg=G')
    assert.are.equal('  // i: hello', helpers.buffer_lines(buf)[2])
  end)
end)
