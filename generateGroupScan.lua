--##### Generate Group Scan for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds a function to generate a group scan based on selected records and a context menu option to call it with the selected records
]]

local function findMenu(mi)
  while not mi.Menu do mi = mi.Parent end
  return mi.Menu
end
local del_mi = MainForm.Deletethisrecord1
local del_menu = findMenu(del_mi)
local mi = createMenuItem(del_menu)
mi.Caption = 'Generate Group Scan'

local function getMRTypeSize(mr)
  local typesizes = {[vtByte]=1, [vtWord]=2, [vtDword]=4,[vtSingle]=4,[vtDouble]=8,[vtPointer]=targetIs64Bit()and 8 or 4}
  local size = typesizes[mr.Type]
  if size then return size else
    if mr.type == vtString or mr.type == vtUnicodeString then
      return mr.String.Size
      elseif mr.type == Binary then return math.ceil(mr.Binary.Size/8) -- ?? not sure if this makes sense
      elseif mr.type == vtByteArray then return mr.Aob.Size
      elseif mr.type == vtAutoAssembler then return nil
      else error(("Unable to determine size for record of type %s"):format(mr.VarType),2)
    end
  end
end
local function GetVTName(vt)
  for k,v in pairs(_G) do
    if k:find('vt',1) and v == vt then return k end
  end
end
local groupType = {vtByte=1, vtWord=2, vtDword=4, vtSingle='f', vtDOuble='d', vtString='s', vtUnicodeString='su', vtPointer='p', skip = 'w'}
setmetatable(groupType, {__index = function(t,k) local v=rawget(t,k) if v then return v else error(('Unknown type %s'):format(k)) end end})

function generateGroupScan(records)
  if not records then return end
  local orderedRecords = {}
  for k,v in pairs(records) do table.insert(orderedRecords, v) end
  table.sort(orderedRecords, function(a,b) return a.CurrentAddress < b.CurrentAddress end)
  local info = {}
  local last = nil
  for k, mr in ipairs(orderedRecords) do
    if k > 1 then
      local offset = mr.CurrentAddress - last.CurrentAddress
      local lastsize = getMRTypeSize(last)
      if lastsize and offset > lastsize then info[#info+1] = ('w:%d'):format(offset - lastsize) end
    end
    local function formatValue(vt, value) if vt == vtString or vt == vtUnicodeString then return ("'%s'"):format(value) else return value end end
    if mr.Type == vtByteArray then
      info[#info+1] = 'arrayStart'
      for byte in mr.value:gmatch('(%x%x)') do
        info[#info+1] = ('%s:%s'):format(groupType.vtByte, ('0x%s'):format(byte))
      end
      info[#info+1] = 'arrayEnd'
    elseif mr.Type == vtAutoAssembler then -- do nothing
    else
      info[#info+1] = ('%s:%s'):format(groupType[mr.VarType], formatValue(mr.Type,mr.Value))
    end
    last = mr
  end
  return table.concat(info,' ')
end

mi.OnClick = function()
  print(generateGroupScan(AddressList.getSelectedRecords()))
end
del_menu.Items.insert(del_mi.MenuIndex, mi)

