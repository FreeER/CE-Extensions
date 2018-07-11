--##### Auto Backup Script for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
------------- based on work by akumakuja28 and Dark Byte -------------
------ see http://forum.cheatengine.org/viewtopic.php?t=602701 -------
-- and http://forum.cheatengine.org/viewtopic.php?p=5468951#5468951 --
---------------------------------------------------------------------- 
]]


----------------------------------------------------------------------
--------------------------- START OF CONFIGURATION -------------------
----------------------------------------------------------------------
local numSaves = 5
local tableSaveTime = 5 -- every n seconds
local luaEngineDelay = 5 -- seconds since typing to save
local saveInFormDesigner = true -- seems to reset selected items and properties/events scrollbar
-- ^ alternative is to open lua engine and type FreeER.autosave.tableSaves.timer.enabled = false
-- that does however completely disable the table saves, not just when the FormDesigner is open
-- so do not forget to reenable them :)
-- you can also access the lua script timer with FreeER.autosave.luaSaves.timer
----------------------------------------------------------------------
---------------------------  END OF CONFIGURATION --------------------
----------------------------------------------------------------------
local mScript = getLuaEngine().Component[11]
local CE_D = getCheatEngineDir()
local FileToCheck = CE_D..[[Bak\Dir_Check.txt]]
local FileToOpen = io.open (FileToCheck)
local CE_Open_Time = (os.date ("%c"))
local Time = CE_Open_Time:gsub("/", "."):gsub(":", ".")
local luaSaves = {}
  luaSaves.current = 1
  for i=0,numSaves do
    luaSaves[i] = ('%s\\Bak\\%s-lua-%i.lua'):format(CE_D, Time, i)
  end
  luaSaves.next = function()
    local Bak = luaSaves[luaSaves.current]
    luaSaves.current = (luaSaves.current % #luaSaves) + 1
    return Bak
  end
  luaSaves.timer = createTimer(getMainForm(),false)
  luaSaves.timer.Interval = 50
  luaSaves.typedTime = 0
  
local tableSaves = {}
  tableSaves.current = 1
  for i=0,numSaves do
    tableSaves[i] = ('%s\\Bak\\%s-table-%i.ct'):format(CE_D, Time, i)
  end
  tableSaves.prev = function()
    local id = tableSaves.current - 1
    if id < 1 then id = numSaves end
    return tableSaves[id]
  end
  tableSaves.peek = function()
    local Bak = tableSaves[tableSaves.current]
    return Bak
  end
  tableSaves.next = function()
    local Bak = tableSaves[tableSaves.current]
    tableSaves.current = (tableSaves.current % #tableSaves) + 1
    return Bak
  end
  tableSaves.timer=createTimer(getMainForm())
  tableSaves.timer.Interval = tableSaveTime*1000

if FileToOpen == nil then
  -- print('No File Exist')
  local Chr = [[chdir XXX && mkdir Bak]]
  local DirMake = string.gsub(Chr,"XXX",getCheatEngineDir())
  os.execute(DirMake)
  local f = io.open(FileToCheck,"w")
  f:write("This file is to check if directory exists.")
  f:close()
end

---------------------------------------------------------------------
------------------------------ SAVING FUNCTIONS ---------------------
---------------------------------------------------------------------

local function Write_Lua_Bak()
  local Bak = luaSaves.next()
  local f = io.open(Bak,'w')
  --print('saving lua to', Bak)

  for l=0, mScript.Lines.Count do
    f:write(mScript.Lines[l].."\n")
  end

  f:close()
end

local function Update_Lua_Bak_Timer(t)
  local now = os.clock()
  --print(now - luaSaves.typedTime)
  if now - luaSaves.typedTime > luaEngineDelay then
    Write_Lua_Bak()
    t.Enabled = false
  end
end

local function getFormDesigner()
  for i=0,getFormCount()-1 do
    local f = getForm(i)
    if(f.name == 'FormDesigner') then return f end
  end
end

--[[
local function addMultiSelectedItems(t, items)
  for i=0,items.Count-1 do
    local it = items[i]
    if it.MultiSelected then t[#t+1] = it end
    if it.HasChildren and it.items then addMultiSelectedItems(t, it.items) end
  end
end
]]
  --[[ saveTable resets FormDesigner selection... save and restore it
  local Selected = nil
  local MultiSelected = {}
  if FormDesigner then
    local insp = FormDesigner.ObjectInspectorDlg
    local tree = insp.ComponentTree
    Selected = tree.getSelected()
    addMultiSelectedItems(MultiSelected, tree.Items)
  end]]

  --[[ restore selection
  if FormDesigner then
    local insp = FormDesigner.ObjectInspectorDlg
    local tree = insp.ComponentTree
    local first = tree.Items[0]
    first.Selected = false
    first.MultiSelected = false
    tree.Selected = Selected
    for _,item in ipairs(MultiSelected) do item.MultiSelected = true end
  end
  ]]

local function Write_Table_Bak()
  local Bak = tableSaves.peek()
  --print('saving table to', Bak)

  local FormDesigner = getFormDesigner()
  if FormDesigner and not saveInFormDesigner then return end

  saveTable(Bak)

  local prv = tableSaves.prev()
  -- if they are the same then next time just overwrite the same one
  local file = io.open(prv)
  local overwriteNextTime
  if file then
    overwriteNextTime = md5file(prv) ~= md5file(Bak)
    file:close()
  else
    overwriteNextTime = true
  end
  if overwriteNextTime then
    --print('moving to next')
    tableSaves.next()
  end
end

---------------------------------------------------------------------
------------------------------ SETUP EVENT HANDLERS -----------------
---------------------------------------------------------------------
--print('creating event handlers')
luaSaves.timer.OnTimer = Update_Lua_Bak_Timer
mScript.OnChange = function()
  luaSaves.typedTime = os.clock()
  luaSaves.timer.Enabled = true
  --print(luaSaves.timer.Enabled and 'enabled timer' or 'failed')
end

tableSaves.timer.OnTimer = Write_Table_Bak
FreeER.autosave = {}
FreeER.autosave.luaSaves = luaSaves
FreeER.autosave.tableSaves = tableSaves
