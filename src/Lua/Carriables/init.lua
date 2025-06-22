local Carriables = {
	instances = {},
	defs = {}
}

local PATH = "Carriables/Objects/"
local function _NIL() end

local STRUCTURE = {
	profit = 0, -- profit it gives and takes away
	priority = 0, -- higher = stack priority
	multiplier = 1, -- profit multiplier
	duration = 12, -- tics it takes to tween to the carriers head, 0 to disable
	easing = ease.outquad, -- easing it uses during tween duration
	transparentOnPickup = true, -- if picked up by consoleplayer, turns transparent
	respawnOnExit = false, -- chooses if item respawns when player exits, only works in escape
	height = 24*FU, -- sets the height that the object is carried by or smth
	state = S_INVISIBLE, -- sets state upon spawn

	onSpawn = _NIL,
	onPickUp = _NIL,
	onDrop = _NIL,
	onUngrabThink = _NIL,
	onGrabThink = _NIL,
	onExit = _NIL,
	onRespawn = _NIL
}
local COPY_LIST = {
	"profit",
	"priority",
	"multiplier",
	"duration",
	"transparentOnPickup",
	"respawnOnExit",
	"height",
	"state"
}

mobjinfo[freeslot "MT_FH_CARRIABLE"] = {
	spawnstate = S_INVISIBLE,
	radius = 128*FU/2,
	height = 128*FU,
	flags = 0
}

local function IsCarried(mobj)
	local target = mobj.settings.target

	if not (target and target.valid and target.health) then
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
end

local function ReleaseCarriable(mobj, launch, rmvFromPickUp)
	if not IsCarried(mobj) then return end

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

	mobj.settings.target = nil

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

	table.insert(GetCarryList(mobj), mobj.settings)

	def.onPickUp(mobj, pmo)
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
end

addHook("NetVars", function(sync)
	Carriables.instances = sync($)
end)

addHook("MapChange", do
	Carriables.instances = {}
end)

addHook("MobjMoveCollide", function(car, pmo)
	if not FangsHeist.isMode() then return end
	if not (pmo and pmo.valid and pmo.health) then return end
	if not (car and car.valid and car.health) then return end
	if pmo.type ~= MT_PLAYER then return end
	print "valid health checks"

	if IsCarried(car) then return end
	print "its not carried"

	if not (pmo and pmo.player and pmo.player.heist) then return end
	if not CouldPickUp(pmo.player) then return end
	print "could pick up"

	if pmo.z > car.z+car.height then return end
	if car.z > pmo.z+pmo.height then return end

	PickUpCarriable(pmo, car)
end, MT_FH_CARRIABLE)

addHook("MobjDamage", function(pmo)
	if not FangsHeist.isMode() then return end
	if not (pmo and pmo.valid) then return end
	if not (pmo and pmo.player and pmo.player.heist) then return end

	for k, v in ipairs(pmo.player.heist.pickup_list) do
		ReleaseCarriable(v.mobj, true, false)
		table.remove(pmo.player.heist.pickup_list, k)
	end
end, MT_PLAYER)

addHook("PostThinkFrame", do
	if not FangsHeist.isMode() then return end

	for i = #Carriables.instances, 1, -1 do
		local car = Carriables.instances[i]
		local def = Carriables.defs[car.id]

		if not (car.mobj and car.mobj.valid) then
			-- re-define mobj if it was suddenly killed
			local mobj = P_SpawnMobj(car.x, car.y, car.z, MT_FH_CARRIABLE)

			def.onSpawn(mobj)

			mobj.settings = car
			car.mobj = mobj
		end

		if IsCarried(car.mobj) then
			local twn = FU
			local pickPos = car.pickup_position
			local curPos = {
				x = car.target.x,
				y = car.target.y,
				z = car.target.z+car.target.height
			}

			-- iterate thru rest of carry objects and see where this mf lies

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

Carriables:define("Treasure", dofile(PATH.."Treasures"))

FangsHeist.Carriables = Carriables