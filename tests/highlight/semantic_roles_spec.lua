local function color(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
end

local function apply(variant, parent)
  local function family()
    return {
      colors = { darkest = '#111111', dim = '#223344', muted = '#556677', soft = '#8899AA', main = '#AABBCC' },
      roles = { builtin = 'dim', method_call = 'muted', const_binding = 'soft', member = 'main' },
    }
  end
  require('argiope').setup({ theme = {
    variant = variant,
    definitions = { [variant] = {
      extends = parent, name = 'Custom semantic roles',
      languages = { javascript = family(), javascript_embedded = family() },
    } },
  } })
  require('argiope.theme').apply()
end

describe('editable semantic roles', function()
  for _, entry in ipairs({ { 'custom', 'aurantia' }, { 'aurantia', 'versicolor' } }) do
    it('honors assignments for ' .. entry[1] .. ' regardless of the variant name', function()
      apply(entry[1], entry[2])
      for _, suffix in ipairs({ '.javascript', '.argiope_javascript' }) do
        assert.are.equal(0x223344, color('@function.builtin' .. suffix))
        assert.are.equal(0x556677, color('@function.method.call' .. suffix))
        assert.are.equal(0x8899AA, color('@argiope.const.variable' .. suffix))
        assert.are.equal(0xAABBCC, color('@variable.member' .. suffix))
      end
    end)
  end

  it('uses the explicit built-in assignments', function()
    require('argiope').setup()
    for _, variant in ipairs({ 'aurantia', 'versicolor', 'ocyaloides', 'trifasciata' }) do
      require('argiope').set_theme_variant(variant)
      local profile = require('argiope.palette').profile()
      for _, pair in ipairs({ { 'javascript', '.javascript' }, { 'javascript_embedded', '.argiope_javascript' } }) do
        local family, suffix = profile.languages[pair[1]], pair[2]
        -- Authored Studio documents may assign these roles independently.
        local authored = {
          ['versicolor'] = {
            javascript = { member = 'soft', builtin = 'light', method_call = 'gray_light', const_binding = 'dim' },
            javascript_embedded = { member = 'soft', builtin = 'accent', method_call = 'accent', const_binding = 'dim' },
          },
          ocyaloides = {
            javascript = { member = 'main', builtin = 'accent', method_call = 'bright', const_binding = 'main' },
            javascript_embedded = { member = 'main', builtin = 'accent', method_call = 'bright', const_binding = 'main' },
          },
          trifasciata = {
            javascript = { member = 'main', builtin = 'accent', method_call = 'bright', const_binding = 'main' },
            javascript_embedded = { member = 'darkest', builtin = 'dim', method_call = 'muted', const_binding = 'soft' },
          },
        }
        if authored[variant] then
          for role, shade in pairs(authored[variant][pair[1]]) do
            assert.are.equal(shade, family.roles[role])
          end
        else
          local warm = variant == 'aurantia'
          assert.are.equal(family.roles.property, family.roles.member)
          assert.are.equal(warm and family.colors.darkest or family.colors[family.roles["function"]], family.colors[family.roles.builtin])
          assert.are.equal(warm and family.colors.darkest or family.colors[family.roles.call], family.colors[family.roles.method_call])
          assert.are.equal(warm and family.colors.main or family.colors[family.roles.variable], family.colors[family.roles.const_binding])
        end
        for _, role in ipairs({ { 'builtin', '@function.builtin' }, { 'method_call', '@function.method.call' }, { 'const_binding', '@argiope.const.variable' }, { 'member', '@variable.member' } }) do
          assert.are.equal(tonumber(family.colors[family.roles[role[1]]]:sub(2), 16), color(role[2] .. suffix))
        end
      end
    end
  end)
end)

describe('inherited semantic roles', function()
  local palette = require('argiope.palette')
  after_each(function() palette.reset() end)

  local function inherited(parent, roles, extra)
    local definitions = extra or {}
    definitions.child = {
      extends = parent, name = 'Inherited test',
      languages = { javascript = { roles = roles } },
    }
    palette.reset(definitions)
    return palette.profile('child').languages.javascript.roles
  end

  it('follows changed generic assignments in older partial themes', function()
    local roles = inherited('versicolor', {
      ['function'] = 'gray', call = 'gray', variable = 'gray', property = 'gray',
    })
    assert.are.equal('gray', roles.builtin)
    assert.are.equal('gray', roles.method_call)
    assert.are.equal('gray', roles.const_binding)
    assert.are.equal('gray', roles.member)
  end)

  it('retains distinct parent roles when generic assignments did not change', function()
    local original = palette.profile('aurantia').languages.javascript.roles
    local roles = inherited('aurantia', {
      ['function'] = original['function'], call = original.call,
      variable = original.variable, property = original.property,
    })
    assert.are.equal(original.builtin, roles.builtin)
    assert.are.equal(original.method_call, roles.method_call)
    assert.are.equal(original.const_binding, roles.const_binding)
    assert.are.equal(original.member, roles.member)
  end)

  it('always respects explicitly supplied special roles', function()
    local roles = inherited('aurantia', {
      ['function'] = 'dim', builtin = 'soft', call = 'dim', method_call = 'soft',
      variable = 'darkest', const_binding = 'soft', property = 'dim', member = 'soft',
    })
    for _, role in ipairs({ 'builtin', 'method_call', 'const_binding', 'member' }) do
      assert.are.equal('soft', roles[role])
    end
  end)

  it('retains property members when only variables change and follows variables for gray presets', function()
    local roles = inherited('versicolor', { variable = 'darkest' })
    assert.are.equal('soft', roles.member)
    roles = inherited('ocyaloides', { variable = 'darkest' })
    assert.are.equal('darkest', roles.member)
  end)

  it('uses the resolved parent roles across multiple inheritance levels', function()
    local roles = inherited('middle', { variable = 'darkest' }, {
      middle = { extends = 'ocyaloides', name = 'Middle', languages = { javascript = { roles = { variable = 'soft' } } } },
    })
    assert.are.equal('darkest', roles.const_binding)
    assert.are.equal('darkest', roles.member)
  end)
end)
