--##### Save Dissect Code Lua Script for Cheat Engine
--##### Author: FreeER (based on DB code snippet)
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw

-- START OF USER CONFIG --
local useGroupMenu = true
-- END OF CONFIG --

-- START OF EXT TEMPLATE CONFIG --
local extGroupMenuCaption = 'FreeER\'s Extensions'
local extItemCaption = 'Save Dissect Code'
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

local function saveDissectCode(dc)
  local fd = createSaveDialog(nil)
  fd.Filter = 'DisectCode|*.DC|All Files|*.*'
  local picked = fd.Execute()
  if not picked then return false end
  dc.saveToFile(fd.FileName)
  fd.destroy()
end

local function loadDissectCode(dc)
  local fd = createOpenDialog(nil)
  fd.Filter = 'DisectCode|*.DC|All Files|*.*'
  local picked = fd.Execute()
  if not picked then return false end
  dc.loadFromFile(fd.FileName)
  fd.destroy()
end

extMenuItem.OnClick = function()
  local dc = getDissectCode()
  if dc.getReferencedFunctions() == nil and dc.getReferencedStrings() == nil then
    loadDissectCode(dc)
  else
    res = inputQuery('Save, load, or clear?', 'save, load, or clear: ', 'save')
    if not res then return end -- quit if canceled
    res = res:lower()
    if res == 'save' then
      saveDissectCode(dc)
    elseif res == 'load' then
      loadDissectCode(dc)
    elseif res == 'clear' then
      dc.Clear()
    else
      showMessage(res .. ' is not save, load, or clear!')
    end
  end
end
