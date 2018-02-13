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
local tableSaveTime = 10 -- every n seconds
local luaEngineDelay = 5 -- seconds since typing to save
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

local function Write_Table_Bak()
  local Bak = tableSaves.next()
  --print('saving table to', Bak)
  saveTable(Bak)
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
