--##### Copy Pointer Offsets for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw

local function findMenu(mi)
  while not mi.Menu do mi = mi.Parent end
  return mi.Menu
end
local del_mi = MainForm.Deletethisrecord1
local del_menu = findMenu(del_mi)

local mi = createMenuItem(del_menu)
mi.Caption = 'Print Offsets'

local function printOffsets(memrec)
  print(memrec.Description)
  local base,offsets=memrec.getAddress()
  print(base)
  if not offsets then return end
  local combined = ('['):rep(#offsets) .. base
  for i=#offsets, 1, -1 do
    local hex = ('%02X'):format(offsets[i])
    print(hex)
    combined = ('%s]+%s'):format(combined,hex)
  end
  print(combined)
  print('')
end

mi.OnClick = function()
  local al = getAddressList()
  local records = al.getSelectedRecords()
  for k,v in pairs(records) do
    if v.Type ~= vtAutoAssembler and not v.isGroupHeader then
      printOffsets(v)
    end
  end
end
del_menu.Items.insert(del_mi.MenuIndex, mi)

