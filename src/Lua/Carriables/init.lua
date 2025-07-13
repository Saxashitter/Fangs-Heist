local Carriables = {
	instances = {},
	defs = {}
}

local PATH = "Modules/Carriables/"
local function _NIL() end

local STRUCTURE = {
	profit = 0, -- profit it gives and takes away
	priority = 0, -- higher = stack priority
	multiplier = 1, -- profit multiplier
	duration = 12, -- tics it takes to tween to the carriers head, 0 to disable
	easing = ease.outquad, -- easing it uses during tween duration
	transparentOnPickup = true, -- if picked up by consoleplayer, turns transparent
	respawnOnExit = false, -- chooses if item respawns when player exits, only works in escape
	giveToDamager = false, -- if damaged by a valid player, gives the carriable to them automatically.
	height = 24*FU, -- sets the height that the object is carried by or smth
	state = S_INVISIBLE, -- sets state upon spawn

	onSpawn = _NIL,
	onPickUp = _NIL,
	onDrop = _NIL,
	onUngrabThink = _NIL,
	onGrabThink = _NIL,
	onExit = _NIL,
	onRespawn = _NIL,
	onPostThink = _NIL,
	canPickUp = function() return true end
}
local COPY_LIST = {
	"profit",
	"priority",
	"multiplier",
	"duration",
	"transparentOnPickup",
	"respawnOnExit",
	"giveToDamager",
	"height",
	"state"
}

local UNGRABBED = MF_SPECIAL
local GRABBED = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_NOBLOCKMAP

mobjinfo[freeslot "MT_FH_CARRIABLE"] = {
	spawnstate = S_INVISIBLE,
	radius = 128*FU/2,
	height = 128*FU,
	flags = UNGRABBED
}

local function IsCarried(mobj)
	if not (mobj and mobj.valid) then return false end
	local target = mobj.settings.target

	if not (target and target.valid) then
		return false
	end

	return true
end

local function GetCarryList(mobj)
	if not IsCarried(mobj) then return end

	local pmo = mobj.settings.target

	return pmo.player.heist.pickup_list
end

local function CouldPickUp(p)
	return p
	and p.valid
	and p.heist
	and p.heist:isAlive()
	and not P_PlayerInPain(p)
	and not p.powers[pw_flashing]
	and not p.heist.exiting
end

local function ReleaseCarriable(mobj, launch, rmvFromPickUp, dontRmvProfit)
	--if not IsCarried(mobj) then print "NOT CARRIED" return end
	--print "carried"

	local def = Carriables.defs[mobj.settings.id]
	local pmo = mobj.settings.target

	if not (pmo and pmo.valid) then
		pmo = nil
	end

	if pmo and rmvFromPickUp then
		local list = GetCarryList(mobj)

		for k,v in ipairs(list) do
			if v ~= mobj.settings then continue end

			table.remove(list, k)
			break
		end
	end
	if pmo
	and not dontRmvProfit then
		pmo.player.heist:gainProfit(-mobj.settings.profit, true)
	end

	mobj.settings.target = nil
	mobj.flags = UNGRABBED

	if launch then
		local angle = FixedAngle(P_RandomRange(1, 360)*FU)

		P_InstaThrust(mobj, angle, 12*FU)
		P_SetObjectMomZ(mobj, 4*FU)
	end

	def.onDrop(mobj, launch, pmo)
end

local function PickUpCarriable(pmo, mobj)
	if IsCarried(mobj) then
		ReleaseCarriable(mobj, true, true)
	end

	local def = Carriables.defs[mobj.settings.id]

	mobj.settings.pickup_position = {
		x = mobj.x,
		y = mobj.y,
		z = mobj.z
	}
	mobj.settings.target = pmo
	mobj.settings.tics = 0

	mobj.flags = GRABBED
	mobj.momx = 0
	mobj.momy = 0
	mobj.momz = 0

	table.insert(GetCarryList(mobj), mobj.settings)
	pmo.player.heist:gainProfit(mobj.settings.profit, true)

	def.onPickUp(mobj, pmo)
end

local function RespawnCarriable(mobj) -- only intended for exit
	local pos = mobj.settings.original_position
	local def = Carriables.defs[mobj.settings.id]

	ReleaseCarriable(mobj, false, false, true)

	P_SetOrigin(mobj,
		pos.x,
		pos.y,
		pos.z)

	def.onRespawn(mobj)
end

local function SetCarriableSettings(mobj, x, y, z, id)
	local def = Carriables.defs[id]
	local settings = {}

	-- manually copy to prevent desynchs and shit
	for _, v in ipairs(COPY_LIST) do
		settings[v] = def[v]
	end

	settings.mobj = mobj
	settings.id = id

	settings.original_position = {
		x = x,
		y = y,
		z = z
	}
	settings.pickup_position = {
		x = 0,
		y = 0,
		z = 0
	}
	settings.current_position = {
		x = x,
		y = y,
		z = z
	}
	settings.tics = 0

	mobj.state = settings.state
	mobj.height = settings.height
	mobj.settings = settings
end

function Carriables:define(name, tbl)
	for k,v in pairs(STRUCTURE) do
		if tbl[k] == nil
		or type(tbl[k]) ~= type(v) then
			tbl[k] = v
		end
	end

	self.defs[name] = tbl
end

function Carriables:new(name, x, y, z, ...)
	if not self.defs[name] then return end

	local def = self.defs[name]
	local mobj = P_SpawnMobj(x, y, z, MT_FH_CARRIABLE)

	SetCarriableSettings(mobj, x, y, z, name)
	table.insert(self.instances, mobj.settings)

	def.onSpawn(mobj, x, y, z, ...)
	return mobj.settings
end

addHook("NetVars", function(sync)
	Carriables.instances = sync($)
end)

addHook("MapChange", do
	Carriables.instances = {}
end)

local function CarriableSpecial(car, pmo)
	if not FangsHeist.isMode() then return end
	if not (pmo and pmo.valid and pmo.health) then return end
	if not (car and car.valid and car.health) then return end
	if pmo.type ~= MT_PLAYER then return end

	if IsCarried(car) then return end

	local def = Carriables.defs[car.settings.id]

	if not (pmo and pmo.player and pmo.player.heist) then return end
	if not CouldPickUp(pmo.player) then return end
	if not def.canPickUp(pmo.player) then return end

	PickUpCarriable(pmo, car)
end

addHook("TouchSpecial", function(special, pmo)
	if not FangsHeist.isMode() then return end
	CarriableSpecial(special, pmo)
	return true
end, MT_FH_CARRIABLE)

local function OnHit(pmo, _, source)
	if not FangsHeist.isMode() then return end
	if not (pmo and pmo.valid) then return end
	if not (pmo and pmo.player and pmo.player.heist) then return end

	local give

	if source
	and source.valid
	and source.type == MT_PLAYER
	and source.player
	and source.player.heist
	and source.player.heist:isAlive() then
		give = source.player
	end

	for i = #pmo.player.heist.pickup_list, 1, -1 do
		local v = pmo.player.heist.pickup_list[i]
		local def = Carriables.defs[v.id]

		if give
		and v.giveToDamager
		and def.canPickUp(source.player) then
			PickUpCarriable(source, v.mobj)
		else
			ReleaseCarriable(v.mobj, true, false)
		end

		table.remove(pmo.player.heist.pickup_list, i)
	end
end

addHook("MobjDamage", OnHit, MT_PLAYER)
addHook("MobjDeath", OnHit, MT_PLAYER)
addHook("PlayerQuit", function(p)
	if not FangsHeist.isMode() then return end
	if not p.heist then return end
	print "running..."

	for i = #p.heist.pickup_list, 1, -1 do
		local v = p.heist.pickup_list[i]
		local def = Carriables.defs[v.id]

		ReleaseCarriable(v.mobj, true, false)
		table.remove(p.heist.pickup_list, i)
	end
end)

addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for i = #Carriables.instances, 1, -1 do
		local car = Carriables.instances[i]
		local def = Carriables.defs[car.id]

		if not (car.mobj and car.mobj.valid) then
			-- re-define mobj if it was suddenly killed
			local mobj = P_SpawnMobj(car.original_position.x, car.original_position.y, car.original_position.z, MT_FH_CARRIABLE)

			mobj.settings = car
			mobj.state = car.state
			mobj.height = car.height
			car.mobj = mobj

			def.onSpawn(mobj, car.original_position.x, car.original_position.y, car.original_position.z)
		end

		if IsCarried(car.mobj) then
			local twn = FU
			local pickPos = car.pickup_position
			local curPos = {
				x = car.target.x,
				y = car.target.y,
				z = car.target.z+car.target.height
			}
			local list = GetCarryList(car.mobj)
	
			for _, cry in ipairs(list) do
				if cry == car then break end
	
				curPos.z = $ + cry.height
			end

			if car.duration > 0 then
				twn = FixedDiv(min(car.tics, car.duration), car.duration)
			end

			car.tics = $+1

			local x = def.easing(twn, pickPos.x, curPos.x)
			local y = def.easing(twn, pickPos.y, curPos.y)
			local z = def.easing(twn, pickPos.z, curPos.z)

			P_MoveOrigin(car.mobj, x, y, z)

			def.onGrabThink(car.mobj, car.target)
		end

		car.current_position = {
			x = car.mobj.x,
			y = car.mobj.y,
			z = car.mobj.z,
		}

		if not IsCarried(car.mobj) then
			def.onUngrabThink(car.mobj)
		end
	end
end)

addHook("PostThinkFrame", do
	if not FangsHeist.isMode() then return end

	for i = #Carriables.instances, 1, -1 do
		local car = Carriables.instances[i]
		local def = Carriables.defs[car.id]

		if car.transparentOnPickup
		and car.mobj
		and car.mobj.valid then
			if IsCarried(car.mobj)
			and car.target.player
			and car.target.player == consoleplayer then
				car.mobj.frame = $|FF_TRANS80
			else
				car.mobj.frame = $ & ~FF_TRANS80
			end
		end

		def.onPostThink(car.mobj)
	end
end)

Carriables:define("Treasure", dofile(PATH.."Treasures"))
Carriables:define("Sign", dofile(PATH.."Sign"))

Carriables.ReleaseCarriable = ReleaseCarriable
Carriables.PickUpCarriable = PickUpCarriable
Carriables.RespawnCarriable = RespawnCarriable
Carriables.FindCarriables = function(name)
	local carriables = {}

	for _, v in ipairs(Carriables.instances) do
		if v.id == name then
			table.insert(carriables, v)
		end
	end

	return carriables
end
Carriables.RemoveCarriable = function(carriable)
	for i, v in ipairs(Carriables.instances) do
		if v == carriable then
			ReleaseCarriable(v)

			if v.mobj and v.mobj.valid then
				P_RemoveMobj(v.mobj)
			end

			table.remove(Carriables.instances, i)
			return true
		end
	end

	return false
end

FangsHeist.Carriables = Carriables