local B = CBW_Battle
local CV = B.Console
local I = B.Item

local cyclespeed = TICRATE*3

local itemsprite = function(mo)
	--Blink Frames
	if mo.fuse > 0 and mo.fuse&1 and mo.fuse < TICRATE*2 then
		if (mo.tracer and mo.tracer.valid) then mo.tracer.flags2 = $|MF2_DONTDRAW end
		mo.flags2 = $|MF2_DONTDRAW
	return end
	--Draw
	if (mo.tracer and mo.tracer.valid) then mo.tracer.flags2 = $&~MF2_DONTDRAW end
	mo.flags2 = $&~MF2_DONTDRAW
	--Sprite orientation
	if mo.flags2&MF2_OBJECTFLIP then
		mo.eflags = $|MFE_VERTICALFLIP
		if (mo.tracer and mo.tracer.valid) then mo.tracer.eflags = $|MFE_VERTICALFLIP end
	end
	--Get item frame
	local i = 1
	if mo.item == 0 then i = S_RING end
	if mo.item == 1 then i = S_RING_ICON1 end
	if mo.item == 2 then i = S_PITY_ICON1 end
	if mo.item == 3 then i = S_WHIRLWIND_ICON1 end
	if mo.item == 4 then i = S_FORCE_ICON1 end
	if mo.item == 5 then i = S_ELEMENTAL_ICON1 end
	if mo.item == 6 then i = S_ATTRACT_ICON1 end
	if mo.item == 7 then i = S_ARMAGEDDON_ICON1 end
	if mo.item == 9 then i = S_BUBBLEWRAP_ICON1 end
	if mo.item == 10 then i = S_FLAMEAURA_ICON1 end
	if mo.item == 11 then i = S_THUNDERCOIN_ICON1 end
	P_SetMobjStateNF(mo,i)
end

local itemroulette = function(mo)
	mo.roulettetics = $+1
	local timer = cyclespeed
	--Shield Rotate
	if mo.roulettetype == 1 and mo.roulettetics >= timer then
		mo.roulettetics = 0
		--Standard
		if mo.item >= 3 and mo.item < 7 then
			mo.item = $+1
		elseif mo.item == 7 then
			mo.item = 3
		end
		--Sonic 3
		if mo.item == 9 or mo.item == 10 then
			mo.item = $+1
		elseif mo.item == 11 then
			mo.item = 9
		end
	end
	--Hyper Rotate
	if mo.roulettetype == 2 and mo.roulettetics >= 2 then
		mo.roulettetics = 0
		mo.item = $+1
		if mo.item == 8 then mo.item = 9 end
		if mo.item > 11 then
			mo.item = 0
		end
	end
end

I.ItemReward = function(mo,player)
	if player.isjettysyn or B.PreRoundWait() then return end
	
	--"Monitor bounce" but weaker
	if not P_PlayerInPain(player)
		local ab = abs(player.mo.momz)
		local threshold = 14 * player.mo.scale
		local mom
		if ab > threshold
			local excess = (abs(player.mo.momz) - threshold) / 4
			mom = threshold + excess
		else
			mom = ab
		end
		if (player.mo.flags2 & MF2_OBJECTFLIP)
			player.mo.momz = min(-mom, $)
		else
			player.mo.momz = max(mom, $)
		end
		if ((player.powers[pw_shield] & SH_NOSTACK) == SH_BUBBLEWRAP) and (player.pflags & PF_SHIELDABILITY)
			P_DoBubbleBounce(player)
		end
	end
 	S_StartSoundAtVolume(player.mo,sfx_cdfm16,150)
 	S_StartSoundAtVolume(player.mo,sfx_pop,160)
	
	--Visual effects
	local i = mo.item
	I.BubbleBurst(mo)
	P_SpawnMobj(mo.x,mo.y,mo.z,MT_SPARK)
	
	--Ring
	if i == 0 then
		player.rings = $+1
		S_StartSound(player.mo,sfx_itemup)
	return end
	--Super Ring
	if i == 1 then
		player.rings = $+10
		S_StartSound(player.mo,sfx_itemup)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_RING_ICON)
	return end
	-- Shield Max -1
	if player.shieldmax < 0
		P_GivePlayerRings(player, 50)
		S_StartSound(player.mo, sfx_s3kb3)
	return end
	--Add to shield reserves
	if player.powers[pw_shield] and player.shieldmax then
		B.UpdateShieldStock(player,1)
	end
	--Shield
	if i == 2 then
		P_SwitchShield(player, SH_PITY)
		S_StartSound(player.mo,sfx_shield)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_PITY_ICON)
	return end
	if i == 3 then
		P_SwitchShield(player, SH_WHIRLWIND)
		S_StartSound(player.mo,sfx_wirlsg)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_WHIRLWIND_ICON)
	return end
	if i == 4 then
		P_SwitchShield(player, SH_FORCE|1)
		S_StartSound(player.mo,sfx_forcsg)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_FORCE_ICON)
	return end
	if i == 5 then
		P_SwitchShield(player, SH_ELEMENTAL)
		S_StartSound(player.mo,sfx_elemsg)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_ELEMENTAL_ICON)
	return end
	if i == 6 then
		P_SwitchShield(player, SH_ATTRACT)
		S_StartSound(player.mo,sfx_attrsg)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_ATTRACT_ICON)
	return end
	if i == 7 then
		if not(player.powers[pw_shield]&SH_NOSTACK == SH_ARMAGEDDON) then
			P_SwitchShield(player, SH_ARMAGEDDON)
		end
		S_StartSound(player.mo,sfx_armasg)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_ARMAGEDDON_ICON)
	return end
	if i == 9 then
		P_SwitchShield(player, SH_BUBBLEWRAP)
		S_StartSound(player.mo,sfx_s3k3f)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_BUBBLEWRAP_ICON)
	return end
	if i == 10 then
		P_SwitchShield(player, SH_FLAMEAURA)
		S_StartSound(player.mo,sfx_s3k3e)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_FLAMEAURA_ICON)
	return end
	if i == 11 then
		P_SwitchShield(player, SH_THUNDERCOIN)
		S_StartSound(player.mo,sfx_s3k41)
		P_SpawnMobjFromMobj(mo,0,0,0,MT_THUNDERCOIN_ICON)
	return end
end

local floorbounce = function(mo)
	if mo.balltype == 1 then return end
	if mo.momz_last == nil then mo.momz_last = mo.momz return end
	local threshold = mo.scale*3/2
	if (mo.eflags&MFE_JUSTHITFLOOR) and abs(mo.momz_last) > threshold then
		local spd = -mo.momz_last
		if mo.balltype == 2 then spd = $*3/5 end --Ball bounce
		if mo.balltype == 3 then spd = $*9/10 end --Rubber ball bounce
		mo.momz = spd
	end
	mo.momz_last = mo.momz
end

local sloperoll = function(mo)
	if not(mo.standingslope)
		then return end
	local slope = mo.standingslope
	
	P_Thrust(mo,slope.xydirection,slope.zdelta*2)
end

local waterfloatA = function(mo)
	if not(mo.buoyancy) then 
		if mo.eflags&MFE_TOUCHWATER then
			local m = mo.scale*2
			mo.momz = max(-m,min(m,$))
		end
	return end
	if mo.eflags&MFE_TOUCHWATER
		mo.momz = $*9/10
	end
	if mo.eflags&(MFE_UNDERWATER|MFE_TOUCHWATER)
		P_SetObjectMomZ(mo,FRACUNIT,1)
	end
end

local featherweight = function(mo,cap)
	--Restrict z velocity
	cap = mo.scale*$
	mo.momz = max(-cap,min(cap,$))
end

local waterfloatB = function(mo)
	--Raise Object if MF_NOGRAVITY is checked
	if mo.flags&MF_NOGRAVITY then
		P_SetObjectMomZ(mo,FRACUNIT,0)
	end
	--Raise Object while underwater
	if not(mo.flags&MF_NOGRAVITY) and ((mo.eflags&MFE_TOUCHWATER or mo.eflags&MFE_UNDERWATER) and P_MobjFlip(mo)*mo.momz < 0)
		then
		mo.momz = -$/2
	end
end

--Stationary physics
local physics_typeA = function(mo)
	local unit = mo.scale
	local accel = unit/4
	local thres = 32*unit
	local gap = 16*unit
	local spd = mo.scale*2
	if mo.z < max(mo.floorz+thres,mo.startheight-gap)
		mo.momz = $+accel
	end
	if mo.z > min(mo.ceilingz-thres-mo.height,mo.startheight+gap)
		mo.momz = $-accel
	end
	mo.momz = min(spd,max(-spd,$))
end

--Ball physics
local physics_typeB = function(mo)
	mo.friction = FRACUNIT*99/100
	floorbounce(mo)
	sloperoll(mo)
	waterfloatA(mo)
end

--Feather/drift physics
local physics_typeC = function(mo)
	featherweight(mo,2)
	waterfloatB(mo)
end

local bubblephysics = function(mo)
	local standard = (mo.flags&MF_NOGRAVITY) and not(mo.buoyancy)
	--Standard
	if standard then
		physics_typeA(mo)
	end
	--Balltype
	if mo.balltype then
		physics_typeB(mo)
	end
	--Feather/Drift
	if not(mo.balltype) and not(standard) then
		physics_typeC(mo)
	end
	--Fragile
	if mo.flags&MF_NOCLIPHEIGHT and (mo.z < mo.floorz or mo.z+mo.height > mo.ceilingz) then
		P_RemoveMobj(mo)
	end
end

--Color fills for bubble overlay
local overlaycolors = {
	SKINCOLOR_GOLD, --Ring
	SKINCOLOR_MOSS, --Pity
	SKINCOLOR_WHITE, --Whirlwind
	SKINCOLOR_PURPLE, --Force
	SKINCOLOR_BLUE, --Elemental
	SKINCOLOR_COPPER, --Attraction
	SKINCOLOR_CRIMSON, --Armageddon
	0, --Rotation
	SKINCOLOR_COBALT, --S3Bubble
	SKINCOLOR_FLAME, --S3Flame
	SKINCOLOR_YELLOW, --S3Lightning
}

local bubbleoverlay = function(mo)
	if not(mo and mo.valid and mo.tracer and mo.tracer.valid) then return end
	local overlay = mo.tracer
	overlay.scale = mo.scale
	local zoffset 
	if P_MobjFlip(mo) == 1 then
		zoffset = FixedMul(mo.scale,-FRACUNIT*12)
	else
		zoffset = FixedMul(mo.scale,FRACUNIT*12)+mo.height
	end
	P_TeleportMove(overlay,mo.x+mo.momx,mo.y+mo.momy,mo.z+mo.momz+zoffset)
	--Color
	local i = mo.item
	if overlaycolors[i] then
		overlay.colorized = true
		overlay.color = overlaycolors[i]
	else
		overlay.colorized = false
	end
end

local bubblecarousel = function(mo)
	local t = mo.target
	if not(t) or not(t.carouselwidth) then return end
	local w = t.carouselwidth*mo.scale
	
	if not(t.carouselorientation) --Standard carousel
		local x = t.x+P_ReturnThrustX(mo,t.angle,w)
		local y = t.y+P_ReturnThrustY(mo,t.angle,w)
		P_TeleportMove(mo,x,y,mo.z)
	else --2D carousel
		local x = t.x+P_ReturnThrustX(mo,t.angle,w)
		local z = t.z+P_ReturnThrustY(mo,t.angle,w)
		P_TeleportMove(mo,x,t.y,z)
	end
end

local debugview = function(mo,spawner)
	if not(CV.Debug.value&DF_ITEM) then return end
	if spawner and spawner.valid then
		mo.colorized = true
		mo.color = SKINCOLOR_JET
		if not(spawner.localized) then
			mo.color = SKINCOLOR_BLUE
		elseif not(spawner.carouselwidth or spawner.flurrytype) then
			mo.color = SKINCOLOR_RED
		elseif spawner.flurrytype then
			mo.color = SKINCOLOR_YELLOW
		elseif spawner.carouselwidth then
			mo.color = SKINCOLOR_GREEN
		end
	end
end


--Spawn body
I.ItemBubbleCreate = function(mo)
	mo.tracer = P_SpawnMobj(mo.x,mo.y,mo.z,MT_ITEM_BUBBLE_OVERLAY)
	mo.item = 0
	mo.shadowscale = FRACUNIT>>1
	mo.startheight = mo.height/2+mo.z
	P_SetObjectMomZ(mo,5*FRACUNIT)
	mo.balltype = 0 --0 = bubble; 1 = marble; 2 = ball; 3 = rubber ball
	mo.fragile = false --true = remove object on surface collision
	mo.roulettetype = 0 --0 = static. 1 = shield roulette. 2 = hyper roulette
	mo.roulettetics = 0
	mo.buoyancy = 0 --Floats on water (if MF_GRAVITY, continuously rises)
end

--Thinker body
I.ItemBubbleThinker = function(mo)
	if not(mo and mo.valid) then return end
	if B.SuddenDeath then 
		P_RemoveMobj(mo)
	return end
	
	bubblephysics(mo)
	if not(mo and mo.valid) then return end
	itemroulette(mo)
	itemsprite(mo)
	bubblecarousel(mo)
	bubbleoverlay(mo)
	if not(mo and mo.valid and mo.tracer and mo.tracer.valid and mo.target and mo.target.valid) then return end
	debugview(mo.tracer,mo.target)
	if mo.target.fusetime then mo.target.fuse = mo.target.fusetime end
end

--Item bubble removed
I.ItemBubbleRemoved = function(mo)
	if mo.tracer and mo.tracer.valid P_RemoveMobj(mo.tracer) end
end