--##### Attach To Most Memory Process for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a menu option to try and attach to the process with the most memory (based on exe name)
]]

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'F&reeER\'s Extensions'
local extItemCaption = 'attachToMostMemoryProcess'
local requiredVersion = 6.4 -- requirement for inputQuery
-- START OF EXT TEMPLATE CONFIG --

if getCEVersion() < requiredVersion then
    error(("%s requires CE >= %d, update CE!"):format(extItemCaption, requiredVersion))
end

-- menu code --
local mf = getMainForm()
local mm = mf.Menu
local extMenu = nil

if useGroupMenu then
  -- look for existing group menu
  for i=0,mm.Items.Count-1 do
      if mm.Items.Item[i].Caption == extGroupMenuCaption then
          extMenu = mm.Items.Item[i]
          break
      end
  end
  if not extMenu then -- not found so create it
      extMenu = createMenuItem(mm)
      extMenu.Caption = extGroupMenuCaption
      mm.Items.add(extMenu)
  end
else
  extMenu = mm.Items
end

local extMenuItem = createMenuItem(extMenu)
extMenuItem.Caption = extItemCaption
extMenu.add(extMenuItem)
-- menu code --

local function getMemory(procname)
  local cmd = ('tasklist /FI "IMAGENAME eq %s" /NH'):format(procname)
  local h = io.popen(cmd)
  local res = h:read('*a')
  h:close()
  --print(res:gsub('\n','\r\n'))
  if res:find('No tasks are running') then error(('No tasks named %s found'):format(procname), 2) end

  local list = {}
  local factorTable = {M=1024*1024,K=1024,G=1024*1024*1024,B=1}
  for info in res:gmatch('[^\n]+') do
    local pid, mem = info:match('.+%s+(%d+)%s+.+%s+%d+%s+(.+%s%a)')
    local pid = tonumber(pid)
    local mfactor = factorTable[mem:sub(-1)] or 1
    local num = mem:sub(1,-2):gsub(',', '')
    --print(mem)
    --print(num, mfactor)
    local nmem = tonumber(num) * mfactor / 1024
    list[pid] = nmem
  end
  return list
end

local function findmax(list)
  local maxPID, maxMem = 0, 0
  for pid, mem in pairs(list) do
    if mem > maxMem then
      maxMem = mem
      maxPID = pid
    end
  end
  return maxPID, maxMem
end

extMenuItem.OnClick = function()
  local name = InputQuery('Process Name + .exe', "What's the process name?", 'chrome.exe')
  openProcess(findmax(getMemory(name)))
end
