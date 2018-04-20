--##### Disable Mono Lua Script for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a menu option to disable mono in the Mono menu
]]

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extItemCaption = 'Disable'
-- START OF EXT TEMPLATE CONFIG --

-- menu code --
local extMenuItem = createMenuItem(extMenu)
extMenuItem.Caption = extItemCaption

local t = createTimer()
t.Interval = 1000
t.OnTimer = function(t)
  if not miMonoTopMenuItem then return end
  extMenu = miMonoTopMenuItem
  extMenu.add(extMenuItem)
  t.destroy()
end
-- menu code --

extMenuItem.OnClick = function()
  monopipe.destroy()
  monopipe = nil
end
