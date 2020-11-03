--##### Remove Hotkeys Lua Script for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a menu option to remove all hotkeys from memory records
  note: this does not remove/destroy any hotkeys created by lua code only the gui
]]

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'Autosaves'
local extItemCaption = 'Open autosaves'
local requiredVersion = 7.2 -- DB added autosave in 7.2
-- START OF EXT TEMPLATE CONFIG --

if getCEVersion() < requiredVersion then
    error(("%s requires CE >= %d, update CE!"):format(extItemCaption, requiredVersion))
end
if not autosave then print("Uh... looks like autosave data has changed. Sorry but I can't do my job :(") end

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
extMenuItem.Caption = 'Open Autosaves'
extMenuItem.OnClick = function()
  shellExecute(autosave.getPath() .. 'Cheat Engine AutoSave')
end
extMenu.add(extMenuItem)

extMenuItem = createMenuItem(extMenu)
extMenuItem.Caption = 'Save state'
extMenu.add(extMenuItem)
extMenuItem.OnClick = function()
  autosave.saveState()
end

extMenuItem = createMenuItem(extMenu)
extMenuItem.Caption = 'Load state'
extMenu.add(extMenuItem)
extMenuItem.OnClick = function()
  autosave.loadState()
end


extMenuItem = createMenuItem(extMenu)
extMenuItem.Caption = 'Toggle Autosaving'
if autosave.Timer and autosave.Timer.Enabled then
  extMenuItem.Caption = 'Toggle Autosaving (ON)'
end
extMenu.add(extMenuItem)
extMenuItem.OnClick = function()
  if not autosave.Timer then
    autosave.applySettings() -- enable timer based on settings
    if autosave.Timer then
      extMenuItem.Caption = 'Toggle Autosaving (ON)'
    end
  else
    extMenuItem.Caption = 'Toggle Autosaving (OFF)'
    autosave.Timer.Enabled = not autosave.Timer.Enabled
  end
end

