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
local extGroupMenuCaption = 'F&reeER\'s Extensions'
local extItemCaption = 'Remove Hotkeys'
local requiredVersion = 6.4 -- Not actually sure what the requirement is... possibly whenever CE added the new OOP syntax
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

extMenuItem.OnClick = function()
  -- http://lazarus-ccr.sourceforge.net/docs/lcl/dialogs/tmsgdlgbuttons.html
  if messageDialog('Remove hotkeys?', 3, 0,1) ~= mrYes then return end
  local al = getAddressList()
  local get_mr = al.getMemoryRecord
  for i=0, al.Count-1 do
    local mr = get_mr(i)
    for h=mr.HotkeyCount-1, 0, -1 do
      mr.Hotkey[h].destroy()
    end
  end
  showMessage('remember to save!') -- offering the prompt is probably more than it's really worth
end
