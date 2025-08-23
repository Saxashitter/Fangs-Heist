/*
Starting AFTER the Launch of Fang's Heist (in Favour of 2.2.16):

Ill make The NEW "EscPanel" HUD for the Gametype (As the 2.2.16 Launch Update)
Enjoy!
*/
local FH = FangsHeist
local tflogo = hud.cachePatch("TFRACTURE_LOGO")
local fhlogo = hud.cachePatch("FH_LOGO")
hud.add(function(v,x,y,w,h)
	if FH.isMode()
		v.drawScaled(x*FU+60*FU,y*FU+25*FU,FU/2,tflogo,nil)
		v.drawScaled(x*FU+150*FU,y*FU+5*FU,FU/4,fhlogo,nil)
		FH.Version.HUD(v,0)
		return true
	end
end,"escpanel")