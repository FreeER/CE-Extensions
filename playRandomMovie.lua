--##### Remove Play Random Movie for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a menu option to play a random movie (based on registry settings - HKCU\Software\Cheat Engine\FreeER-RandomMoviePlayer)
]]

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'FreeER\'s Extensions'
local extItemCaption = 'Play Random Movie'
local requiredVersion = 6.4
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

math.randomseed(os.time())

local function findAllExtensions(path)
  local exts = {}
  for i,p in ipairs(getFileList(path, '', true)) do
    exts[p:match('.*%.(.*)')] = true
  end
  return exts
end
--[[
for k,v in pairs(findAllExtensions(path)) do
  print(k)
end
]]

local settings = getSettings('FreeER-RandomMoviePlayer') --HKCU\Software\Cheat Engine\FreeER-RandomMoviePlayer
local movieMask = settings.Value['movieMask']
local command = settings.Value['command']
local args = settings.Value['args']
if not movieMask or movieMask == '' then
  movieMask = '*.m4v;*.mp4;*.m4a;*.avi;*.wmv;*.mkv;*.flv'
  settings.Value['movieMask'] = movieMask
end
if not command or command == '' then
  command = 'vlc.exe'
  settings.Value['command'] = command
end
if not args or args == '' then
  args = '"%s"'
  settings.Value['args'] = args
end
local pathsep = package.config:sub(1,1)

local function pickFile(path)
  path = path:gsub('[/\\]',pathsep)
  local list = getFileList(path, movieMask, true)
  --print(path, #list)
  if #list < 1 then error('No files to pick from!', 2) end
  local file = list[math.random(#list)]
  local _,ending = file:find(path)
  local name,_ = file:sub(ending+2,#file-4):gsub('[%.%-_]', ' ')
  return file, name
end

extMenuItem.OnClick = function()
  local path = settings.Value['movieDirectory']
  if not path or path == '' then
    path = ('%s%s%s'):format(os.getenv('userprofile'),pathsep,'Videos')
  end
  path = inputQuery('Movie Path', 'Movie Path', path)
  if not path or path:gsub(' ','') == '' then return end
  settings.Value['movieDirectory'] = path

  shellExecute(command, args:format(pickFile(path)))
end
