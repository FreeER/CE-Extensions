--this script adds "Copy N Bytes to Clipboard option" 
-- based on http://forum.cheatengine.org/viewtopic.php?p=5735612#5735612

local mv=getMemoryViewForm() 

local oldmemorypopuponpopup 
if miCopyNBytes~=nil then 
  miCopyNBytes.destroy() 
  miCopyNBytes=nil 
  mv.memorypopup.OnPopup=oldmemorypopuponpopup 
  oldmemorypopuponpopup=nil 
end 

miCopyNBytes=createMenuItem(mv.memorypopup) 
miCopyNBytes.Name="miCopyNBytes" 
miCopyNBytes.Caption="Copy N Bytes to clipboard" 
miCopyNBytes.ShortCut=textToShortCut("Ctrl+Shift+B")
miCopyNBytes.OnClick=function() 
  local hv=mv.HexadecimalView 
  -- start at current selection
  local start = inputQuery('Start', 'Starting address', ('%X'):format(mv.HexadecimalView.SelectionStart))
  if not start then return end

  -- start with current selection or 32
  local numbytes = mv.HexadecimalView.SelectionStop-mv.HexadecimalView.SelectionStart
  if not numbytes or numbytes == 0 then numbytes = 32 end
  numbytes = inputQuery('Number of Bytes', 'Number of Bytes', numbytes)
  if not numbytes then return end
  numbytes = tonumber(numbytes)
  if not numbytes then return end -- if it failed to convert

  local format = '%X '
  local bytes = readBytes(start, numbytes, true)
  if not bytes then print('failed to read bytes') return end
  writeToClipboard(format:rep(#bytes):format(unpack(bytes)))
end 

mv.memorypopup.Items.insert(mv.Cut1.MenuIndex-1, miCopyNBytes) 

oldmemorypopuponpopup=mv.memorypopup.OnPopup 
mv.memorypopup.OnPopup=function(s) 
  miCopyNBytes.Visible=true
  return oldmemorypopuponpopup(s) 
end 
