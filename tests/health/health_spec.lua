describe("Argiope health", function()
  it("passes with the supported test runtime", function()
    local errors = {}
    local original = {
      error = vim.health.error,
      ok = vim.health.ok,
      start = vim.health.start,
      warn = vim.health.warn,
    }

    vim.health.start = function() end
    vim.health.ok = function() end
    vim.health.warn = function() end
    vim.health.error = function(message)
      table.insert(errors, message)
    end

    local checked, check_error = pcall(require("argiope.health").check)

    vim.health.error = original.error
    vim.health.ok = original.ok
    vim.health.start = original.start
    vim.health.warn = original.warn

    assert.is_true(checked, check_error)
    assert.are.same({}, errors)
  end)
end)
