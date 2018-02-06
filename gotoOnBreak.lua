--##### gotoOnBreak Script
--##### Author: FreeER
--##### Website: 
--##### Github: https://github.com/FreeER
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  
  note: settings are global, they affect all disassemblers not just the one it was done from
]]

-- BGR
--local staticColor = 0xAE33AE
local menuCaption = 'gotoOnBreak'
if getCEVersion() < 6.4 then
  error(menuCaption .. " requires CE >= 6.4, update CE!")
end

local function setBreakpointFunction()
  local input = inputQuery(menuCaption, 'What address do you want to go to?', targetIs64Bit() and "RAX" or "EAX")
  -- if cancel then do nothing
  if not input then return end

  -- if 0 or empty string then disable
  if input == "0" or input:gsub("%s","") == "" then
    debugger_onBreakpoint = nil
    return
  end

  debugger_onBreakpoint = function()
    local straddr = input:upper() -- making uppercase shouldn't break anything since symbols are case insensitive
    -- apparently getAddress doesn't support registers...
    for _,reg in pairs({'%u?AX','%u?BX','%u?CX','%u?DX','%u?SI','%u?DI','%u?BP','%u?SP','%u?IP','R8%u?','R9%u?','R10%u?','R11%u?','R12%u?','R13%u?','R14%u?','R15%u?'}) do
      local match = straddr:match(reg)
      local val = _G[match] -- get register value
      if val then
        straddr = straddr:gsub(reg, ('%X'):format(val))
      end
    end
    local addr = getAddressSafe(straddr)
    if addr then getMemoryViewForm().HexadecimalView.Address = addr end
  end
end

local function createMenu(f)
  local items = f.menu.Items
  for j=0,items.Count-1 do
    if items[j].Caption == menuCaption then return end
  end
  local themenu = createMenuItem(f.Menu)
  themenu.Caption = menuCaption
  themenu.OnClick = setBreakpointFunction
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
