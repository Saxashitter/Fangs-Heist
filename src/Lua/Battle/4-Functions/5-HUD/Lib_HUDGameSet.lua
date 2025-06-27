local B = CBW_Battle
local A = B.Arena
local CV = B.Console

//Game set!
local lerpamt = FRACUNIT
A.GameSetHUD = function(v,player,cam)
	if not (B.BattleGametype()) or not (B.Exiting) or not (B.HUDAlt)
	or B.FinalLevel()
		lerpamt = FRACUNIT
	return end
	local a = v.cachePatch("LTFNT065")
	local e = v.cachePatch("LTFNT069")
	local g = v.cachePatch("LTFNT071")
	local m = v.cachePatch("LTFNT077")
	local s = v.cachePatch("LTFNT083")
	local t = v.cachePatch("LTFNT084")
	local exclaim = v.cachePatch("LTFNT033")
	local text1 = {g,a,m,e}
	local x1 = 80
	local y1 = 80
	
	lerpamt = B.FixedLerp(0,FRACUNIT,$*90/100)
	local subtract = B.FixedLerp(0,180,lerpamt)
	local text2 = {s,e,t,exclaim}
	local x2 = 140
	local y2 = 100
	local spacing = 20
	for n = 1,#text1
		v.drawScaled(FRACUNIT*(x1+spacing*n-subtract),y1*FRACUNIT,FRACUNIT,text1[n],
			V_HUDTRANS)
		if text1[n] == m then
			x1 = $+8
		end
	end
	for n = 1,#text2
		v.drawScaled(FRACUNIT*(x2+spacing*n+subtract),y2*FRACUNIT,FRACUNIT,text2[n],
			V_HUDTRANS)
	end
end