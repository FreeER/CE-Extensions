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
local extItemShortcut = 'ctrl+]'
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'F&reeER\'s Extensions'
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
extMenuItem.Shortcut = extItemShortcut
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

local settings  = getSettings('FreeER-RandomMoviePlayer') --HKCU\Software\Cheat Engine\FreeER-RandomMoviePlayer
local movieMask = settings.Value['movieMask']
if not movieMask or movieMask == '' then
  movieMask = '*.m4v;*.mp4;*.m4a;*.avi;*.wmv;*.mkv;*.flv'
  settings.Value['movieMask'] = movieMask
end
local args      = settings.Value['args']
if not args or args == '' then
  args = '"%s"' -- simple quote of file name
  settings.Value['args'] = args
end
local command   = settings.Value['command'] --eg. 'vlc.exe' -- path to program to use for all files

local pathsep   = package.config:sub(1,1)

local function pickFile(path)
  path = path:gsub('[/\\]',pathsep)
  local list = getFileList(path, movieMask, true)
  --print(path, #list)
  if #list < 1 then error('No files to pick from!', 2) end
  local file = list[math.random(#list)]
  return file
end

extMenuItem.OnClick = function()
  local path = settings.Value['movieDirectory']
  if not path or path == '' then
    path = ('%s%s%s'):format(os.getenv('userprofile'),pathsep,'Videos')
  end
  path = inputQuery('Movie Path', 'Movie Path', path)
  if not path or path:gsub(' ','') == '' then return end

  if not command or command == '' then
    shellExecute(pickFile(path)) -- let windows use the default
  else
    shellExecute(command, args:format(pickFile(path)))
  end
  settings.Value['movieDirectory'] = path
end
