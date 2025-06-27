local B = CBW_Battle
local CV = B.Console

local function getshield(n)
	if n==SH_THUNDERCOIN return "TVZPICON" end
	if n==SH_BUBBLEWRAP return "TVBBICON" end
	if n==SH_FLAMEAURA return "TVFLICON" end
	if n==SH_ARMAGEDDON return "TVARICON" end
	if n==SH_ELEMENTAL return "TVELICON" end
	if n==SH_ATTRACT return "TVATICON" end
	if n==SH_WHIRLWIND return "TVWWICON" end
	if n==SH_PINK return "TVPPICON" end
	if n&SH_FORCE return "TVFOICON" end
	return "TVPIICON"	//Default
end

B.ShieldStockHUD = function(v, player, cam)
	if not (B.HUDMain) then return end
	if player.playerstate != PST_LIVE then return end
	if not(CV.ShieldStock.value) then return end
	if not(gametyperules&GTR_PITYSHIELD) then return end
	if not(player.shieldmax) then return end
	local blink = false
	local flags = V_HUDTRANS|V_SNAPTOBOTTOM|V_SNAPTORIGHT|V_PERPLAYER
	local align = "thin"
	local s = 4
	local t = 2
	
	local xoffset = hudinfo[HUD_POWERUPS].x+18	-- 288+18 = 306
	local yoffset = hudinfo[HUD_POWERUPS].y+6	-- 176+6 = 182
	local text = "Sh "..#player.shieldstock.."/"..player.shieldmax
	//Draw shield reserves

	local function drawshield(n,reduce)
		local patch = "MPTYICON"
		if player.shieldstock[n]
			and (not(P_PlayerInPain(player) or player.charmed) or #player.shieldstock > n or leveltime&1) //Reserve shield is about to be used (blinking)
			then
			patch = getshield(player.shieldstock[n])
		end
		v.drawScaled(xoffset<<16,yoffset<<16,FRACUNIT>>reduce,v.cachePatch(patch),flags)
	end
	
	local n = player.shieldmax
	yoffset = $-s*n/2
	xoffset = $+t*n/2
	while n > 0 do
		drawshield(n,2)
		yoffset = $+s
		xoffset = $-t
		n = $-1
	end
	//Test string
-- 	xoffset = $-48
-- 	v.drawString(xoffset,yoffset,text,flags,align)
-- 	print("!", "shield stock", unpack(player.shieldstock),"#")
end