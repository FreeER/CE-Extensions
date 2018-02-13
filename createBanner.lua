--##### Create BannerLua Function for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  provides a function called createBanner that tries to do this:

------------------------------------------------------------------------------------
------------------------- Cheat Engine Auto Backup Script --------------------------
-- based on http://forum.cheatengine.org/viewtopic.php?t=602701 and DB's autosave --
------------------------------------------------------------------------------------ 

or with something more complex: print(createBanner(lines, '_-~=~-'))
_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-
__-~=~-_-~=~-_-~=~-_-~=~- Cheat Engine Auto Backup Script _-~=~-_-~=~-_-~=~-_-~=~--~
_- based on http://forum.cheatengine.org/viewtopic.php?t=602701 and DB's autosave ~=
_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~-_-~=~- 

created as a test of the time delay for my autosave script
]]

FreeER = FreeER or {}

function createBanner(lines, fillStr)
  if type(lines) == 'string' then
    local it = lines:gmatch('[^\r\n]+')
    lines = {}
    for line in it do
      lines[#lines+1] = line
    end
  end
  local Infinity = 1e309
  local maxlength = -Infinity
  for _,line in ipairs(lines) do
    if #line > maxlength then maxlength = #line end
  end
  maxlength = maxlength + 4
  for k,line in ipairs(lines) do
    local needed = math.floor((maxlength - #line) / #fillStr / 2)
    local filler = fillStr:rep(needed)
    local needExtra = maxlength - (needed*2*#fillStr + #line)
    local extra = needExtra and fillStr:rep(math.ceil(needExtra/#fillStr)):sub(1,needExtra) or ''
    local frontExtra = extra:sub(1,math.floor(#extra / 2))
    local endExtra = extra:sub(math.floor(#extra / 2)+1)
    lines[k] = ('%s%s %s %s%s'):format(frontExtra, filler, line, filler, endExtra)
  end
  maxlength = maxlength + 2 -- +2 for spaces around line
  local filler = fillStr:rep(math.ceil((maxlength) / #fillStr)):sub(1,maxlength)
  table.insert(lines, 1, filler)
  lines[#lines+1] = filler
  return table.concat(lines,'\r\n')
end

FreeER.createBanner = createBanner
