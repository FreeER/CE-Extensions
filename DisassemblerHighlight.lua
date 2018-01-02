--##### RegisterHighlight Script
--##### Author: FreeER (based on code from STN)
--##### Website: http://forum.cheatengine.org/viewtopic.php?t=604314
--##### Github: https://github.com/FreeER
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw

-- BGR
--local staticColor = 0xAE33AE
local menuCaption = 'Disassembler Highlight'
if getCEVersion() < 6.4 then
  error(menuCaption .. " requires CE >= 6.4, update CE!")
end

local function addColorCodes(ps,reg)
  --local ps = "{R}edx(N),{S}Tutorial-1386.exe+201004{N}"
  local lowerps = ps:lower()
  local found=1, last
  local format = "{C%0.6x}%s{N}"
  -- if all letters (ignoring whitespace) then prepend with } so ax only matches ax not eax
  -- else assume the user knows what they wanted and use their input
  -- hopefully there's not an exploit by passing crafted data to find
  local nospaces = reg:gsub('%s',''):lower()
  local lowerreg = nospaces:find('%W') ~= 1 and '}' .. nospaces or reg
  local newcolor = staticColor and staticColor or math.floor(math.random()*0xffffff)
  while true do
    found, last = lowerps:find(lowerreg, last)
    if not found then break end
    local match = ps:sub(lowerps:find(nospaces,found),last)
    local new = format:format(newcolor, match)
    ps = ps:sub(1,found-1) .. new .. ps:sub(last+1)
    last = found + #new
  end
  return ps
end

local function enableHighlight()
  local reg = inputQuery(menuCaption, "What do you want to highlight?", targetIs64Bit() and "RAX" or "EAX")
  local visDis = getVisibleDisassembler()
  if not reg or reg:gsub("%s","") == "" then visDis.OnPostDisassemble=nil return end

  function f(sender, address, LastDisassembleData, result, description) 
    if not sender.syntaxHighlighting then return end
    LastDisassembleData.parameters = addColorCodes(LastDisassembleData.parameters, reg)
    return result,description 
  end 

  visDis.OnPostDisassemble = f
end

local function createMenu(f)
  local items = f.menu.Items
  for j=0,items.Count-1 do
    if items[j].Caption == menuCaption then return end
  end
  local themenu = createMenuItem(f.Menu)
  themenu.Caption = menuCaption
  themenu.OnClick = enableHighlight
  items.add(themenu)
end

-- add menu to main memory view form
createMenu(getMemoryViewForm())

-- remember when the user pastes a memory record to workaround a bug
local ctrlv_time = os.clock()

-- keyboard shortcut
local ctrlv = createHotkey(function(hk) ctrlv_time = os.clock() end, VK_CONTROL, VK_V)

-- menu
local pasteMenuItem = nil
-- find the menu item for paste
local it = MainForm.PopupMenu2.Items
for i=0,it.Count-1 do
  if it[i].Caption == 'Paste' then
    pasteMenuItem = it[i]
    break
  end
end
if not pasteMenuItem then error('failed to find paste menu item') end

-- add an onclick function
local pasteMenuItem_onclick = pasteMenuItem.OnClick
pasteMenuItem.OnClick = function(...)
  ctrlv_time = os.clock()
  if pasteMenuItem_onclick and type(pasteMenuItem_onclick) == 'function' then
    pasteMenuItem_onclick(...)
  end
end

-- setup event to add menu to new forms
-- seems to get an invalid form on paste that causes an error, no idea why
registerFormAddNotification(function(form)
  -- captions/names don't seem to be set yet so start a timer to check later
  local t = createTimer()
  t.OnTimer = function(t)
    -- stop checking (only checks once after a delay)
    t.destroy()
    -- if the user just copy/pasted a memory record then don't check (bug workaround)
    if os.clock() - ctrlv_time < 0.5 then return end
    -- check if it's a memory viwer form
    if form.Name:find("MemoryBrowser") then createMenu(form) end
  end
  t.Interval = 300
end)
