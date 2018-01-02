--##### Convert Struct Display (type) Lua Function for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  provides a function called convertStructDisplay that takes the name of a
  struct, the display type to change, and the new displa type
  all elements of the first given type will be changed to the second given type
    valid display types = 'dtHexadecimal', 'dtUnSignedInteger', and 'dtSignedInteger'
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
      else return nil, "more than one structure matches when ignoring case"
      end
    end
  end
  if casematch then return casematch else return nil, ("No structure with the name '%s' exists"):format(name) end
end

local function getStructureByName(name)
  local id, errmsg = getStructureIDByName(name)
  if not id then
    return nil, errmsg
  else
    return getStructure(id)
  end
end

-- valid display types = 'dtHexadecimal', 'dtUnSignedInteger', and 'dtSignedInteger'
function convertStructDisplay(structName, displayToChange, newDisplay)
  local s = getStructureByName(structName)
  for i=0, s.Count-1 do
    local e = s.Element[i]
    if e.DisplayMethod == displayToChange then e.DisplayMethod = newDisplay end
  end
end
