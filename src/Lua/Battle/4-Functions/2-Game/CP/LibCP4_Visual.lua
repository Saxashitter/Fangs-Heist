local B = CBW_Battle
local CP = B.ControlPoint
local CV = B.Console
freeslot('spr_cpsp')


--*** Misc functions
local function randomcolor(mo) 
	return G_GametypeHasTeams() and mo.color
		or SKINCOLOR_SUPERSILVER5 + P_RandomRange(0,8)*5 
end

local function createSet(mo, flip, floor, radius, quadrants, teamcolor, makeghosts)
	for n = 1, quadrants and 4 or 8 do
		local angle = n*FRACUNIT*90
		if n > 4
			angle = $-FRACUNIT*45
		end
		angle = FixedAngle($)
		local fx = P_SpawnMobj(mo.x + P_ReturnThrustX(mo, angle, radius), mo.y + P_ReturnThrustY(mo, angle, radius), floor, MT_CPBONUS)
		table.insert(mo.fx, fx)
		fx.tracer = mo
		fx.teamcolor = teamcolor or false
		fx.angle = angle
		fx.distance = radius
		fx.ghosts = makeghosts
		fx.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS
		if flip == -1 
			fx.flags2 = $|MF2_OBJECTFLIP 
			fx.eflags = $|MFE_VERTICALFLIP
		end
		if quadrants and n >= 4 then break end
	end
end

local function createSplat(mo, flip, floor, radius, quadrants, teamcolor, makeghosts)
	for n = 1, quadrants and 4 or 8 do
		local angle = n*FRACUNIT*90
		if n > 4
			angle = $-FRACUNIT*45
		end
		angle = FixedAngle($)
		local fx = P_SpawnMobj(mo.x + P_ReturnThrustX(mo, angle, radius), mo.y + P_ReturnThrustY(mo, angle, radius), floor, MT_CPBONUS)
		table.insert(mo.fx, fx)
		fx.sprite = SPR_THOK
		fx.tracer = mo
		fx.teamcolor = teamcolor or false
		fx.angle = angle
		fx.distance = radius
		fx.ghosts = makeghosts
		fx.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_FLOORSPRITE
		if flip == -1 
			fx.flags2 = $|MF2_OBJECTFLIP 
			fx.eflags = $|MFE_VERTICALFLIP
		end
		if quadrants and n >= 4 then break end
	end
	
	
-- 	local fx = P_SpawnMobj(mo.x, mo.y, floor, MT_CPBONUS)
-- 	table.insert(mo.fx, fx)
-- 	fx.sprite = SPR_CPSP
-- 	fx.frame = FF_TRANS70
-- 	fx.renderflags = $|RF_FULLBRIGHT|RF_NOCOLORMAPS|RF_FLOORSPRITE
-- 	fx.spritexscale = radius/128
-- 	fx.spriteyscale = radius/128
-- 	fx.distance = 0
-- 	fx.teamcolor = true
-- 	fx.target = mo
end


local createFull = function(mo)
	--Get CP attributes
	local radius
	local height
	if CV.CPRadius.value > 0 then --Calculate radius
		radius = CP.CalcRadius(CV.CPRadius.value)
	else
		radius = mo.cp_radius
	end
	if CV.CPHeight.value > 0 then --Calculate height
		height = CP.CalcHeight(CV.CPHeight.value)
	elseif CV.CPHeight.value == -1 then
		height = mo.ceilingz - mo.floorz
	elseif mo.cp_height > 0 then
		height = mo.cp_height
	else
		height = mo.ceilingz - mo.floorz
	end

	--Get Orientation and surfaces
	local flip = P_MobjFlip(mo)
	local floor
	local ceil
	if flip == 1 then
		floor = mo.floorz
		ceil = mo.ceilingz
	else
		floor = mo.ceilingz
		ceil = mo.floorz
	end

	-- Create object sets
	createSet(mo,	flip,	floor,					radius,		false,	false,	true)
	createSet(mo,	flip,	floor+flip*height/4,	radius/8,	true,	true,	false)
	createSet(mo,	flip,	floor+flip*height/8,	radius/16,	true,	true,	false)
	createSet(mo,	flip,	flip*height+floor,		radius,		false,	false,	true)
	createSet(mo,	flip,	flip*height*3/4+floor,	radius/8,	true,	true,	false)
	createSet(mo,	flip,	flip*height*7/8+floor,	radius/16,	true,	true,	false)
	-- Create splats
	createSplat(mo,	flip,	flip*height+floor,				radius,		false,	false,	true)
	createSplat(mo,	flip,	flip*height+floor+mo.scale*4,	radius,		false,	false,	true)
	createSplat(mo,	flip,	floor,							radius,		false,	false,	true)
	createSplat(mo,	flip,	floor+mo.scale*4,				radius,		false,	false,	true)
-- 	createSplat(mo,	floor+mo.scale*flip, radius)
-- 	createSplat(mo, flip*height+floor-mo.scale*flip, radius)
end

-- Setup visuals for Active CP
CP.ActivateFX = function(mo)
	mo.flags2 = $&~MF2_SHADOW
	if #mo.fx
		return
	end
	
	-- Construct visual objects table
	createFull(mo)
end

-- Reset visuals for deactivated CP
CP.ResetFX = function(mo)
	mo.flags2 = $|MF2_SHADOW
	mo.color = SKINCOLOR_CARBON
	-- Clean up the visual objects table
	while #mo.fx do
		local fx = mo.fx[1]
		if fx and fx.valid
			P_RemoveMobj(fx)
		end
		table.remove(mo.fx, 1)
	end
end

-- CP object hovering
CP.PointHover = function(mo, floor, flip, height)
	local hover_amount = flip*height/2-mo.height/2
	local hover_speed = mo.scale*4
	local hover_accel = hover_speed/12
	if mo.z > hover_amount+floor then
		mo.momz = max(-hover_speed,$-hover_accel)
	end
	if mo.z < hover_amount+floor then	
		mo.momz = min(hover_speed,$+hover_accel)
	end
	
	--Twirl the object
	local spd = mo.capture_status > CP_ACTIVE and ANG20 or ANG1
	mo.angle = $ + spd
	
	-- Glitter
	if mo.capture_status != CP_INERT and not(leveltime % 12)
		local r = mo.radius/FRACUNIT
		local h = mo.height/FRACUNIT
		local fx = P_SpawnMobjFromMobj(mo,
			P_RandomRange(-r, r)*FRACUNIT,
			P_RandomRange(-r, r)*FRACUNIT,
			P_RandomRange(0, h)*FRACUNIT,
			MT_BOXSPARKLE)
		P_SetObjectMomZ(fx, FRACUNIT)
	end
end

-- Ticframe visual thinker
CP.UpdateFX = function(mo)
	for n, fx in ipairs(mo.fx) do
		if not(fx.valid)
			table.remove(mo.fx, n)
			return
		end
		if fx.extravalue1 and fx.fuse
			if not(fx.target and fx.target.valid and fx.tracer and fx.tracer.valid)
				P_RemoveMobj(fx)
				return
			end
			local frac = FRACUNIT*fx.fuse/fx.extravalue1
			local x = B.FixedLerp(fx.target.x, fx.tracer.x, frac)
			local y = B.FixedLerp(fx.target.y, fx.tracer.y, frac)
			local z = B.FixedLerp(fx.target.z + fx.target.height/2, fx.tracer.z + fx.tracer.height/2, frac)
			P_TeleportMove(fx, x, y, z)
			return
		end
		
		-- Update color
		fx.color = fx.teamcolor and mo.color or randomcolor(mo)
		-- Update position
		if fx.sprite == SPR_CPBS
			fx.angle = $ + FixedAngle(FRACUNIT*2)
		else
			fx.angle = $ - FixedAngle(FRACUNIT*2)
		end
		P_TeleportMove(fx,
			mo.x + P_ReturnThrustX(nil, fx.angle, fx.distance),
			mo.y + P_ReturnThrustY(nil, fx.angle, fx.distance),
			fx.z)
		-- Make ghost mobj
		if fx.ghosts
			local ghost = P_SpawnGhostMobj(fx)
			ghost.color = fx.color
			ghost.renderflags = fx.renderflags
			ghost.frame = fx.frame
		end
	end
end