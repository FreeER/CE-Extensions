-- thanks to EXOR
-- https://discord.com/channels/350750090463281172/350754184267694081/798965420173557781
function file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end
local gvim = "C:/Program Files (x86)/Vim/vim82/gvim.exe"
if file_exists(gvim) then
  getMainForm().Help1[1].setOnClick( 
    function () shellExecute(gvim,'celua.txt',getCheatEngineDir()) end) 
end
