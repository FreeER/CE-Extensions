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

local ignoreDirs = {['ceshare']=1}
local ignoreFiles = {}

for _,dir in pairs(scandir(ap)) do
  if not ignoreDirs[dir] then
    --print('scanning', dir)
    local full = ('%s\\%s'):format(ap,dir)
    local files = scandir(full,true,'lua')
    if files['init.lua'] then
       require(full..'\\init.lua')
    else
      for _,file in pairs(files) do
        local f = ('%s\\%s'):format(full,file)
        --print('  ', 'requiring ', f)
        dofile(f)
      end
    end
  end
end


