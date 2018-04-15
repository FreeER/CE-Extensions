--##### Duplicate Pointer for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a context menu option to duplicate pointers
]]

local function findMenu(mi)
  while not mi.Menu do mi = mi.Parent end
  return mi.Menu
end
local del_mi = MainForm.Deletethisrecord1
local del_menu = findMenu(del_mi)

local mi = createMenuItem(del_menu)
mi.Caption = 'Duplicate Pointer'

local function duplicateMR(main, appendTo)
  local properties = {'Description', 'Address', 'CustomTypeName', 'Script',
    'Active', 'Color', 'ShowAsHex', 'ShowAsSigned', 'AllowIncrease',
    'AllowDecrease', 'Collapsed', 'Async', 'AsyncProcessing',
    'AsyncProcessingTime', 'OnActivate', 'OnDeactivate', 'OnDestroy',
  'OnGetDisplayValue', 'DontSave'}

  local mr = (AddressList or getAddressList()).createMemoryRecord()
  for _,p in ipairs(properties) do
    mr[p] = main[p]
  end

  if main.Type == vtString then
    mr.String.Size = main.String.Size
    mr.String.Unicode = main.String.Unicode
    mr.String.Codepage = main.String.Codepage
  elseif main.Type == vtBinary then
    mr.Binary.Startbit = main.Binary.Startbit
    mr.Binary.Size = main.Binary.Size
  elseif main.Type == vtByteArray then
    mr.Aob.Size = main.Aob.Size
  end

  mr.OffsetCount = main.OffsetCount
  for i=0,main.OffsetCount-1 do
    mr.OffsetText[i] = main.OffsetText[i]
  end
  for i=0,main.HotkeyCount-1 do
    mr.Hotkey[i] = main.Hotkey[i]
  end

  someGlobalWorkAroundForDuplicateMR = appendTo
  for i=0,main.Count-1 do
    local c = duplicateMR(main.Child[i], mr)
    -- appendTo is nil in here for some f*ing reason....
    if someGlobalWorkAroundForDuplicateMR then
      c.appendToEntry(someGlobalWorkAroundForDuplicateMR)
    end
  end
  --if main.IsReadable then mr.Value = main.Value end
  return mr
end

mi.OnClick = function()
  local al = AddressList or getAddressList()
  -- only main selected, doesn't really make sense to copy multiple since offsets would likely be different
  local mr = al.getSelectedRecord()
  if not mr then return end -- not sure how that would happen but :)
  if mr.Type == vtAutoAssembler or mr.Type == vtGroupHeader then return end

  local numCopies = inputQuery('How many copies', 'Copies:', '1')
  numCopies = tonumber(numCopies)
  if not numCopies or numCopies == 0 then return end
  if mr.OffsetCount < 1 then -- plain address / not a pointer
    local offsetDiff     = inputQuery('How much to change by', 'How much to change by', '4')
    offsetDiff       = tonumber(offsetDiff,16)
    if not offsetDiff then
      showMessage('Invalid offset difference, was not a number')
      return
    end
    local newOffset = offsetDiff
    for i=1,numCopies do
      local copy = duplicateMR(mr)
      copy.Address = copy.Address .. (' %s %X'):format(newOffset>0 and'+'or'-',math.abs(newOffset))
      newOffset = newOffset + offsetDiff
    end
  else
    local offsetToChange = inputQuery('Offset Index to change', 'Offset Index to change', '0')
    local offsetDiff     = inputQuery('How much to change by', 'How much to change by', '4')
    offsetToChange = tonumber(offsetToChange)
    offsetDiff     = tonumber(offsetDiff,16)
    if not offsetDiff or not offsetToChange then
      showMessage('Invalid offset index or difference was not a number')
      return
    elseif offsetToChange >= mr.OffsetCount then
      showMessage('offset index was too large!')
      return
    end

    for i=1,numCopies do
      local copy = duplicateMR(mr)
      local newOffset = copy.Offset[offsetToChange] + offsetDiff
      if(tonumber(copy.OffsetText[offsetToChange],16)) then
        newOffset = ('%s%X'):format(newOffset>0 and'+'or'-',math.abs(newOffset))
      else
        newOffset = copy.OffsetText[offsetToChange] .. (' %s %X'):format(newOffset>0 and'+'or'-',math.abs(newOffset))
      end
      copy.OffsetText[offsetToChange] = newOffset
    end
  end
end
del_menu.Items.insert(del_mi.MenuIndex, mi)
