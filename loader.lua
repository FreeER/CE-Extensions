--##### Autorun Lua Script Loader for Cheat Engine
--##### Author: FreeER
--##### Github: https://github.com/FreeER
--##### Website: https://www.facebook.com/groups/CheatTheGame
--##### YouTube: https://www.youtube.com/channel/UCLy60mbqc3rSvh42jkpCDxw
--[[
  Tries to load all lua files in subdirectories of CE's autorun folder for easier extension management
  if autorun/package/init.lua exists only that file will be loaded instead of every file for custom management
]]
local ignoreDirs = {['ceshare']=1}

-- tweaked function from internet search
function scandir(path, files, ext)
    local t, popen = {}, io.popen
    local cmd = ('dir "%s\\%s" /b %s'):format(path, ext and ('*.%s'):format(ext) or "", files and "" or "/ad")
    --print(cmd)
    for filename in popen(cmd):lines() do
        t[filename] = filename
    end
    return t
end

local ap = getAutorunPath()
for _,dir in pairs(scandir(ap)) do
  if not ignoreDirs[dir] then
    --print('scanning', dir)
    local full = ('%s\\%s'):format(ap,dir)
    local files = scandir(full,true,'lua')
    if files['init.lua'] then
       dofile(full..'\\init.lua')
    else
      for _,file in pairs(files) do
        local f = ('%s\\%s'):format(full,file)
        --print('  ', 'requiring ', f)
        dofile(f)
      end
    end
  end
end


