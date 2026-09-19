-- Small, non-validating XML reader for SLNX. No DTDs or external entities.
local M = {}
local entities = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'" }

local function decode(value)
  return (value:gsub("&([^;]+);", function(entity)
    if entities[entity] then
      return entities[entity]
    end
    local number = entity:match("^#x(%x+)$")
    number = number and tonumber(number, 16) or tonumber(entity:match("^#(%d+)$"))
    if not number or number == 0 or number > 0x10ffff or (number >= 0xd800 and number <= 0xdfff) then
      error("Invalid XML entity: &" .. entity .. ";", 0)
    end
    return vim.fn.nr2char(number)
  end))
end

local function parse_attributes(text, tag_name)
  local attributes = {}
  while text:match("%S") do
    local key, delimiter, offset = text:match("^%s+([%w_:.-]+)%s*=%s*(['\"])()")
    assert(key, "Invalid XML attributes on " .. tag_name)
    local finish = assert(text:find(delimiter, offset, true), "Unclosed XML attribute")
    assert(attributes[key] == nil, "Duplicate XML attribute: " .. key)
    attributes[key] = decode(text:sub(offset, finish - 1))
    text = text:sub(finish + 1)
  end
  return attributes
end

local function tag_end(text, start)
  local position, quote = start + 1, nil
  while position <= #text do
    local character = text:sub(position, position)
    if quote then
      if character == quote then
        quote = nil
      end
    elseif character == '"' or character == "'" then
      quote = character
    elseif character == ">" then
      return position
    end
    position = position + 1
  end
  error("Unclosed XML tag")
end

function M.parse(text)
  local document = { children = {} }
  local stack, pos = { document }, 1
  while true do
    local start = text:find("<", pos, true)
    if not start then
      break
    end
    if text:sub(start, start + 3) == "<!--" then
      local stop = assert(text:find("-->", start + 4, true), "Unclosed XML comment")
      pos = stop + 3
    elseif text:sub(start, start + 1) == "<?" then
      local stop = assert(text:find("?>", start + 2, true), "Unclosed XML declaration")
      pos = stop + 2
    elseif text:sub(start, start + 8) == "<![CDATA[" then
      local stop = assert(text:find("]]>", start + 9, true), "Unclosed CDATA")
      pos = stop + 3
    else
      assert(text:sub(start, start + 1) ~= "<!", "XML DTDs are not supported")
      local stop = tag_end(text, start)
      local tag = text:sub(start + 1, stop - 1)
      local closing = tag:match("^/%s*([%w_:.-]+)%s*$")
      if closing then
        assert(#stack > 1 and stack[#stack].name == closing, "Mismatched XML closing tag: " .. closing)
        table.remove(stack)
      else
        local name, attrs = tag:match("^([%w_:.-]+)(.*)$")
        assert(name, "Invalid XML tag")
        local self_closing = attrs:match("/%s*$") ~= nil
        if self_closing then
          attrs = attrs:gsub("/%s*$", "")
        end
        local node = { name = name, attrs = parse_attributes(attrs, name), children = {} }
        table.insert(stack[#stack].children, node)
        if not self_closing then
          stack[#stack + 1] = node
        end
      end
      pos = stop + 1
    end
  end
  assert(#stack == 1, "Unclosed XML element")
  assert(#document.children == 1, "Expected one XML root element")
  return document.children[1]
end

return M
