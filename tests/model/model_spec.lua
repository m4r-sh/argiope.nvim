local helpers = require("tests.helpers")
local model = require("argiope.model")

describe("tagged-template model", function()
  it("reports registered templates in source order", function()
    local bufnr = helpers.new_javascript_buffer({
      "const document = md`",
      "${items.map((item) => md`",
      "- ${item.name}",
      "`)}",
      "`",
    })

    local templates = assert(model.templates(bufnr))
    assert.are.equal(2, #templates)
    assert.are.equal("md", templates[1].tag)
    assert.are.equal("markdown", templates[1].language)
    assert.are.equal("md", templates[2].tag)
    assert.is_true(templates[2].registered)
  end)

  it("resolves the final property of a member-expression tag", function()
    local bufnr = helpers.new_javascript_buffer({
      "const document = ui.md`",
      "# Member syntax",
      "`",
    })

    local templates = assert(model.templates(bufnr))
    assert.are.equal(1, #templates)
    assert.are.equal("ui.md", templates[1].tag)
    assert.are.equal("markdown", templates[1].language)
    assert.is_true(templates[1].registered)

    local context = assert(model.context_at(bufnr, 1, 0))
    assert.are.equal(templates[1].node:id(), context.template.node:id())
  end)

  it("keeps an outer-to-inner ownership stack for nested templates", function()
    local bufnr = helpers.new_javascript_buffer({
      "const document = md`",
      "${items.map((item) => md`",
      "- ${item.name}",
      "`)}",
      "`",
    })

    local context = assert(model.context_at(bufnr, 2, 0))
    assert.are.equal(2, #context.stack)
    assert.are.equal("md", context.stack[1].tag)
    assert.are.equal("md", context.stack[2].tag)
    assert.are.equal(context.stack[2].node:id(), context.template.node:id())
  end)

  it("does not claim content owned by an unregistered nested tag", function()
    local bufnr = helpers.new_javascript_buffer({
      "const document = html`",
      "${raw`",
      "unmanaged",
      "`}",
      "`",
    })

    local context = assert(model.context_at(bufnr, 2, 0))
    assert.is_nil(context.template)
    assert.are.equal("raw", context.blocked_by.tag)
    assert.is_false(context.blocked_by.registered)
  end)

  it("does not claim an ordinary JavaScript template inside an interpolation", function()
    local bufnr = helpers.new_javascript_buffer({
      "const document = html`",
      "${`",
      "ordinary template content",
      "`}",
      "`",
    })

    local context = assert(model.context_at(bufnr, 2, 0))
    assert.is_nil(context.template)
    assert.is_false(context.blocked_by.tagged)
    assert.is_false(context.blocked_by.registered)
  end)
end)
