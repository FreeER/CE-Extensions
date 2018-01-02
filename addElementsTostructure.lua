--##### Add Elements To Structure Lua Function for Cheat Engine
--##### Author: FreeER (based on https://github.com/cheat-engine/cheat-engine/issues/243 by rcg4u)
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  adds addElementsToStructure function to let you add multiple elements to a struction, eg. 30 byte elements
  see function comment for more info
]]
local function getStructureIDByName(name)
  local lname = name:lower()
  local casematch = nil
  local count = getStructureCount()-1
  for i=0, count do
    local struct = getStructure(i)
    -- if there are two structs with the exact same name, not my problem if you get the wrong one!
    if struct.Name == name then return i
    elseif struct.Name:lower() == lname then
      if casematch == nil then casematch = i
        -- potentially misses case where exact match exists after two caseinsensitive matches
        -- ... can fix easily enough with two loops but... people probably should have that many
        -- structures with the same name right? right? I'll find out I guess lol
      else return nil, "more than one structure matches when ignoring case" end
    end
  end
  if casematch then return casematch else return nil, ("No structure with the name '%s' exists"):format(name) end
end

local function getStructureByName(name)
  local id, errmsg = getStructureIDByName(name)
  if not id then return nil, errmsg
  else return getStructure(id) end
end

function getStructureByIdent(ident)
  if type(ident) == 'number' then return getStructure(ident)
  elseif type(ident) == 'string' then return getStructureByName(ident)
  else return nil end
end

-- if vtType is basic returns appropriate size else size arg
local function vtTypeSize(vtType, size)
      if vtType == vtByte then return 1
  elseif vtType == vtWord then return 2
  elseif vtType == vtDword then return 4
  elseif vtType == vtQword then return 8
  elseif vtType == vtSingle then return 4
  elseif vtType == vtDouble then return 8
  elseif vtType == vtString then return size
  elseif vtType == vtUnicodeString then return size
  elseif vtType == vtByteArray then return size
  elseif vtType == vtBinary then return size
  elseif vtType == vtAutoAssembler then return nil
  elseif vtType == vtPointer then return targetIs64Bit() and 8 or 4
  elseif vtType == vtCustom then return size
  elseif vtType == vtGrouped then return size
  else return error("Unknown varType", 2) end
end

--[[
ident is structure or index/name of structure
starting offset to begin adding elements at
info table of Vartype and optionally ChildStruct, ChildStructStart, ByteSize, displayMethod
  ChildStruct may be either an ident or the struct itself
  displayMethod may be either 'dtHexadecimal', 'dtSignedInteger' or 'dtUnSignedInteger'
numElems is number of elements to add
if endOffset is provided that's used instead of numElems
]]
function addElementsToStructure(ident,startOffset,info,numElems,endOffset)
  local struct
  if type(ident) == 'userdata' then
    if ident.ClassName ~= 'TDissectedStruct' then error(ident.ClassName .. ' is not a valid structure!')
    else struct = ident end
  else struct = getStructureByIdent(ident) end
  if not struct then error("no valid structure given!", 2) end

  local elementSize = vtTypeSize(info.Vartype, info.ByteSize)

  local cs = info.ChildStruct
  if cs and (type(cs) == 'number' or type(cs) == 'string') then cs = getStructureByIdent(cs)
  elseif cs and type(cs) == 'userdata' then
    if cs.ClassName ~= 'TDissectedStruct' then cs = '' end
  elseif cs then cs = '' end

  endOffset = endOffset or startOffset+(numElems-1)*elementSize

  for offset=startOffset, endOffset, elementSize do
    local se = struct.addElement()
    se.Offset = offset
    -- hm... maybe use a loop to add anything in the table?
    se.Vartype = info.Vartype
    se.ChildStruct = cs
    se.ChildStructStart = info.ChildStructStart
    se.ByteSize = info.ByteSize
    se.displayMethod = info.displayMethod
  end
end

