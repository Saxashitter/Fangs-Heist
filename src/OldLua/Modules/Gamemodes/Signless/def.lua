local copy = FangsHeist.require "Modules/Libraries/copy"
local gamemode = copy(FangsHeist.Gamemodes[FangsHeist.Solo])

local path = "Modules/Gamemodes/Signless/"
local super = FangsHeist.Gamemodes[FangsHeist.Solo]

gamemode.super = super
gamemode.name = "Signless"
gamemode.desc = "Truly a collectathon."
gamemode.id = "SIGNLESS"
gamemode.teamlimit = 1
gamemode.twoteamsleft = false
gamemode.treasures = true

local SS_NOANIM = 0
local SS_AIRANIM = 1
local SS_GRNDANIM = 2

function gamemode:init(map)
	super.init(self, map)

	FangsHeist.Net.escape_opengoal = 0
end

function gamemode:update()
	super.update(self)

	local sign = FangsHeist.Net.sign

	if not FangsHeist.Net.escape then
		for p in players.iterate do
			if not p.heist then continue end
			if not p.heist:isAlive() then continue end

			if p.mo.subsector.sector == sign.subsector.sector then
				self:startEscape(p)
				break
			end
		end
	end

	if sign.signstate == SS_AIRANIM
	and P_IsObjectOnGround(sign) then
		sign.state = S_SIGNPLAYER
		sign.angle = sign.resetangle
		sign.signstate = SS_GRNDANIM
	end
end

function gamemode:spawnSign()
	local pos = self:getSignSpawn()
	local sign = P_SpawnMobj(pos[1], pos[2], pos[3], MT_SIGN)
	sign.angle = pos[4]
	sign.signstate = SS_NOANIM

	--[[local board = P_SpawnMobjFromMobj(sign, 0, 0, 0, MT_OVERLAY)
	board.target = sign
	board.state = S_SIGNBOARD
	board.movedir = ANGLE_90
	sign.tracer = board

	local bust = P_SpawnMobjFromMobj(board, 0, 0, 0, MT_OVERLAY)
	bust.target = board
	bust.state = S_EGGMANSIGN
	board.tracer = bust]]

	FangsHeist.Net.sign = sign
end

function gamemode:startEscape(p)
	super.startEscape(self, p)

	p.heist:gainProfit(650)

	local sign = FangsHeist.Net.sign
	sign.target = p.mo

	P_SetObjectMomZ(sign, 12*FRACUNIT, false)
	sign.resetangle = sign.angle
	sign.state = S_SIGNSPIN1
	sign.signstate = SS_AIRANIM

	if (sign.info.seesound) then
		S_StartSound(sign, sign.info.seesound)
	end
end

return FangsHeist.addGamemode(gamemode)