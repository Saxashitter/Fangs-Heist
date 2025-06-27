local B = CBW_Battle

local white = "\x80"
local yellow = "\x82"
local red = "\x85"
local gray = "\x86"

B.PinchHUD = function(v, player, cam)
	if not (B.PinchTics) then return end
	if not (B.HUDAlt) then return end
	
	local x, y = 160, 80
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_ALLOWLOWERCASE|V_PERPLAYER
	
	local tlimit = (timelimit*60)
	local ltime = (leveltime/TICRATE)
	local pinchtime = tlimit-ltime
	
	if not (B.SuddenDeath) then
		if (leveltime&6) then
			v.drawString(x, y-10, red+"HURRY UP", flags, "center")
			v.drawString(x, y, yellow+(pinchtime)+white+" seconds left!", flags, "center")
		end
	else
		local color = {"\x80","\x82","\x81","\x80"}
		local c = color[leveltime&3+1]
		if (leveltime&3) then
			v.drawString(x, y, c+"Sudden Death!!", flags, "center")
		end
	end
end