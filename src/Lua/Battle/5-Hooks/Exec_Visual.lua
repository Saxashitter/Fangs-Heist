local B = CBW_Battle

addHook("MobjThinker", B.BattleShieldThinker, MT_BATTLESHIELD)
addHook("MobjThinker", B.NegaShieldThinker, MT_NEGASHIELD)
addHook("MobjThinker", B.InstaFlip, MT_INSTASHIELD)
addHook("MobjThinker", B.StunBreakVFXThinker, MT_STUNBREAK)

addHook("MobjThinker",function(mo) B.EnergyGather(mo,mo.target,mo.extravalue1,mo.extravalue2) end,MT_ENERGYGATHER)
addHook("MobjThinker", B.TargetDummyThinker, MT_TARGETDUMMY)
addHook("MobjThinker",function(mo) B.MetalAura(mo,mo.target) end, MT_ENERGYAURA)

//Shields (yeah, this is pretty messy...)
local colorsh = function(mo, redcol, bluecol)
	B.OverlayHide(mo,mo.target)
	
	if mo.colorized return end
	local target = mo.target
	if target and target.valid and not target.player and target.target and target.target.player
		target = target.target
	end
	
	if B.BattleCampaign()
	or not (G_GametypeHasTeams() and target and target.valid and target.player and target.player.valid and target.player.ctfteam)
		return
	end
	
	if (target.player.ctfteam == 1) and redcol
		mo.color = redcol
		mo.colorized = true
		return
		
	elseif (target.player.ctfteam == 2) and bluecol
		mo.color = bluecol
		mo.colorized = true
		return
	end
end

local colorsh2 = function(mo)
	if mo.state >= S_ARMA1 and mo.state <= S_ARMB32
		colorsh(mo,nil,SKINCOLOR_PURPLE)
		return
	end
	if mo.state >= S_ZAPS1 and mo.state <= S_ZAPSB11
		colorsh(mo,SKINCOLOR_SUPERRED3,SKINCOLOR_SUPERSKY2)
		return
	end
	if mo.state >= S_FIRS1 and mo.state <= S_FIRSB10
		colorsh(mo,nil,SKINCOLOR_CYAN)
		return
	end
	if mo.state >= S_BUBS1 and mo.state <= S_BUBSB6
		colorsh(mo,SKINCOLOR_SUPERGOLD1,nil)
		return
	end
	B.OverlayHide(mo,mo.target)
end

addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_CRIMSON,nil) end,MT_ELEMENTAL_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_ORANGE,SKINCOLOR_VAPOR) end,MT_ATTRACT_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_FLAME,SKINCOLOR_SKY) end,MT_WHIRLWIND_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,nil) end,MT_FORCE_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,nil,SKINCOLOR_BLUE) end,MT_ARMAGEDDON_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,nil,SKINCOLOR_DUSK) end,MT_FLAMEAURA_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,nil) end,MT_BUBBLEWRAP_ORB)
addHook("MobjThinker", function(mo) colorsh(mo,SKINCOLOR_RED,SKINCOLOR_SAPPHIRE) end,MT_THUNDERCOIN_ORB)
addHook("MobjThinker", colorsh2,MT_OVERLAY)
addHook("MobjThinker",function(mo) 
	B.OverlayHide(mo,mo.target)
	if gametyperules&GTR_PITYSHIELD or G_GametypeHasTeams()
		local owner = mo.target
		if not(owner and owner.valid and owner.player and owner.player.valid) then return nil end
		mo.color = owner.player.skincolor
		mo.colorized = true
	else
		mo.color = SKINCOLOR_CERULEAN
	end
end,MT_PITY_ORB)