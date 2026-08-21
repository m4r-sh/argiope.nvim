local function injection_languages(source)
  local parser = vim.treesitter.get_string_parser(source, "javascript")
  local tree = assert(parser:parse(true)[1])
  local query = assert(vim.treesitter.query.get("javascript", "injections"))
  local languages = {}

  for _, match, metadata in query:iter_matches(tree:root(), source, 0, -1, { all = true }) do
    local language = metadata["injection.language"]
    local has_content = false

    for capture_id, nodes in pairs(match) do
      local capture = query.captures[capture_id]
      if capture == "injection.content" then
        has_content = true
      elseif capture == "injection.language" then
        local node = type(nodes) == "table" and nodes[1] or nodes
        language = vim.treesitter.get_node_text(node, source):lower()
      end
    end

    if has_content and language then
      languages[language] = true
    end
  end

  return languages
end

describe("JavaScript injections", function()
  before_each(function()
    require("argiope").setup()
  end)

  it("preserves upstream comment and regular-expression injections", function()
    local languages = injection_languages([[
/** API documentation */
const matcher = /argiope/;
]])

    assert.is_true(languages.jsdoc)
    assert.is_true(languages.comment)
    assert.is_true(languages.regex)
  end)

  it("preserves upstream tagged-template injections for unmanaged tags", function()
    local languages = injection_languages([[
const query = sql`SELECT * FROM spiders`;
const animation = keyframes`from { opacity: 0; }`;
]])

    assert.is_true(languages.sql)
    assert.is_true(languages.styled)
  end)

  it("adds registered tagged-template injections", function()
    local languages = injection_languages([[
const markup = html`<main>${value}</main>`;
const styles = css`main { color: ${color}; }`;
const prose = md`# ${title}`;
const script = raw.js`const value = true;`;
const icon = svg`<svg><path d=${path} /></svg>`;
const vertex = glsl`void main() { gl_Position = position; }`;
const compute = wgsl`fn main() { let value = 1.0; }`;
]])

    assert.is_true(languages.argiope_html)
    assert.is_true(languages.argiope_javascript)
    assert.is_true(languages.css)
    assert.is_true(languages.markdown)
    assert.is_true(languages.argiope_svg)
    assert.is_true(languages.glsl)
    assert.is_true(languages.wgsl)
  end)

  it("hands tags back to upstream queries when Argiope is disabled", function()
    require("argiope").setup({ enabled = false })
    local languages = injection_languages([[
const markup = html`<main>${value}</main>`;
const styles = css`main { color: ${color}; }`;
const prose = md`# ${title}`;
]])

    assert.is_true(languages.html)
    assert.is_true(languages.styled)
    assert.is_true(languages.md)
    assert.is_nil(languages.css)
    assert.is_nil(languages.markdown)
  end)
end)
