--##### Play Sound on BreakPoint
--##### Author: FreeER
--##### Website: http://forum.cheatengine.org/viewtopic.php?t=604314
--##### Github: https://github.com/FreeER
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[ Beeps on added breakpoints ]]

local menuCaption = 'SoundOnBP'
if getCEVersion() < 6.4 then
  error(menuCaption .. " requires CE >= 6.4, update CE!")
end

FreeER = FreeER or {}
FreeER.SoundOnBP = {}
FreeER.SoundOnBP.BPS = {}
FreeER.SoundOnBP.Sound = findTableFile('Activate') -- comes with CE

local bps = FreeER.SoundOnBP.BPS

local function hasBP(addr)
  addr = GetAddressSafe(addr)
  local list = debug_getBreakpointList()
  for _,ad in ipairs(list) do
    if ad == addr then return true end
  end
end

local oldDebugger_onBreakpoint=nil
if debugger_onBreakpoint then oldDebugger_onBreakpoint = debugger_onBreakpoint end
debugger_onBreakpoint = function(...)
  if not bps[EIP] then
    if oldDebugger_onBreakpoint then return oldDebugger_onBreakpoint(...) end
    return 0 -- not registered for sound and no other handler so just break and update
  end

  playSound(FreeER.SoundOnBP.Sound)
  if bps[EIP] == co_run then
    if oldDebugger_onBreakpoint then oldDebugger_onBreakpoint(...) end
    debug_continueFromBreakpoint(co_run)
    return not 0
  else
    if oldDebugger_onBreakpoint then return oldDebugger_onBreakpoint(...) end
    return 0 -- break and update interface
  end
end

local function createMenu(f)
  local items = f.menu.Items
  for j=0,items.Count-1 do
    if items[j].Caption == menuCaption then return end
  end
  local themenu = createMenuItem(f.Menu)
  themenu.Caption = menuCaption
  themenu.OnClick = function()
    local dis = f.DisassemblerView
    local addr = GetAddressSafe(dis.SelectedAddress)
    if not bps[addr] and not hasBP(addr) then
      debug_setBreakpoint(addr)
      bps[addr] = co_run
    else
      if bps[addr] == co_run then debug_removeBreakpoint(addr) end
      if debug_isBroken() and EIP == addr then debug_continueFromBreakpoint(co_run) end
      bps[addr] = false
    end
  end
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
