-- bold-author.lua
-- Bolds "Brailey, T." (and any following initials) wherever it appears
-- inside bibliography reference divs (ids starting with "refs").

local function bold_name_in_inlines(inlines)
  local result = pandoc.List()
  local i = 1
  while i <= #inlines do
    local el = inlines[i]
    -- Match the last-name token "Brailey,"
    if el.t == "Str" and el.text == "Brailey," then
      local span = pandoc.List({el})
      local j = i + 1
      -- Collect Space + initial pairs belonging to this author's name.
      -- A trailing "," on an initial is the APA author-list delimiter;
      -- include that token but stop immediately so the next author's
      -- last name is not swept into the bold span.
      while inlines[j] and inlines[j].t == "Space" and
            inlines[j + 1] and inlines[j + 1].t == "Str" and
            inlines[j + 1].text:match("^[A-Z]") do
        local tok = inlines[j + 1]
        span:insert(inlines[j])
        span:insert(tok)
        j = j + 2
        if tok.text:match(",$") then  -- delimiter comma → last initial, stop
          break
        end
      end
      result:insert(pandoc.Strong(span))
      i = j
    else
      result:insert(el)
      i = i + 1
    end
  end
  return result
end

local function process_block(block)
  if block.t == "Para" or block.t == "Plain" then
    for _, v in ipairs(block.content) do
      if v.t == "Str" and v.text == "Brailey," then
        block.content = bold_name_in_inlines(block.content)
        return block
      end
    end
  end
end

function Div(el)
  -- Only process bibliography divs produced by multibib
  if el.identifier and el.identifier:match("^refs") then
    return pandoc.walk_block(el, {
      Para  = process_block,
      Plain = process_block,
    })
  end
end
