local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end

FangsHeist.makeCharacter("metalsonic", {
	pregameBackground = "FH_PREGAME_METAL",
	voicelines = {
		escape = {sac("sfx_mtlesc", "This is just like the time where I told that dumbass Egg-head to start digging in his butt.")},
		hurt = {
			sac("sfx_mtlhr1", "I don't feel pain."),
			sac("sfx_mtlhr2", "Try all you want, you can't stop Mecha-Killer."),
			sac("sfx_mtlhr3", "Bring it on, cock-sucker."),
			sac("sfx_mtlhr4", "I swear to God."),
			sac("sfx_mtlhr5", "Try me."),
		},
		block = {
			sac("sfx_mtlpy1", "Hahaha! C'mon, you want some more?"),
			sac("sfx_mtlpy2", "Oh, you're really bad at this."),
		},
		shield = {
			sac("sfx_mtlpa1", "Go on, I dare you."),
			sac("sfx_mtlpa2", "Six, Seven."),
			sac("sfx_mtlpa3", "Bitch-ass ain't catching me, dead or alive."),
		},
		accept = {
			sac("sfx_mtlsel", "Time to chew ass and kick gum. But first, I need to find ass to chew.")
		},
		signpost = {
			sac("sfx_mtlsg1", "Fuck you, bitch. This shit is mine now, bitch."),
			sac("sfx_mtlsg2", "I'm moving like Von."),
			sac("sfx_mtlsg3", "Bitches hate me, cause they ain't me."),
		},
		treasure = {
			sac("sfx_mtltr1", "What is this?"),
			sac("sfx_mtltr2", "What the fuck am I looking at?"),
		}
	}
})

freeslot "spr_msud"
freeslot "S_X3UPDASH"
freeslot "sfx_msupds"
states[S_X3UPDASH] = {
	sprite = SPR_MSUD,
	frame = A|FF_ANIMATE|FF_FULLBRIGHT,
	var1 = 8,
	var2 = 1,
	tics = 9,
	nextstate = S_NULL
	}
//Some values to modify it!

//DRIFT TURN SPEED!
local DTS = ANG10

//MINIMUN SPEED FOR DRIFT!
local MINSPEED = FU * 15

//It's easy to comprehend.
local DASHMODETICS = 35*2

//Minimum speed for getting dash mode!
local MINDASHMODE = 26 * FU

//Drift speed loss over time! 
local DSLOT = FU / 5
local DSMAX = FU * 46

local DMBASESPEED = 36 * FU
local DMSPEEDUP = FU/8
local DMMAXSPEED = 46 * FU

local AIRDASHSPEEDZ = 0
local AIRDASHSPEEDXY = 30 * FU

local DASHFLAGS = STR_WALL|STR_CEILING|STR_SPIKE|STR_ATTACK

local MetalSlams = {}
addHook("NetVars", function(sync)
	MetalSlams = sync($)
end)

local function Valid(p)
	return FangsHeist.isMode(p)
	and p
	and p.valid
	and p.heist
	and p.heist:isAlive()
	and p.mo
	and p.mo.valid
	and p.mo.skin == "metalsonic"
end

local function DashModeDisable(p)
	if not p.mo.metalsonic.dmt then return end

	p.mo.metalsonic.dmt = 0
	p.mo.color = p.skincolor
	p.mo.metalsonic.dmspeed = DMBASESPEED
	p.powers[pw_strong] = $ & ~DASHFLAGS
end

local function DashModeTick(p)
	if (P_IsObjectOnGround(p.mo) and p.speed < MINDASHMODE)
	or P_PlayerInPain(p)
	or not (p.mo and p.mo.health) then
		if p.mo
		and p.mo.health
		and p.mo.metalsonic.dmt >= DASHMODETICS then
			S_StartSound(p.mo, sfx_kc65)
		end

		DashModeDisable(p)
		return
	end

	if P_IsObjectOnGround(p.mo)
	and not p.mo.metalsonic.drift then
		p.mo.metalsonic.dmt = $ + 1
	
		if p.mo.metalsonic.dmt == DASHMODETICS+1 then
			S_StartSound(p.mo, sfx_cdfm40)
		end
	end

	if p.mo.metalsonic.dmt > DASHMODETICS then
		p.powers[pw_strong] = $|DASHFLAGS
		p.mo.metalsonic.dmspeed = min($ + DMSPEEDUP, DMMAXSPEED)

		if p.mo.state == S_PLAY_RUN then
			p.mo.state = S_PLAY_DASH
		end

		if leveltime%4 < 2 then
			p.mo.color = skincolors[p.skincolor].invcolor
		else
			p.mo.color = p.skincolor + leveltime%2
		end
	end
end

addHook("PlayerThink", function(p)
	if not Valid(p) then
		if p.mo and p.mo.valid then
			p.mo.metalsonic = nil
		end
		return
	end

	p.dashmode = 0

	if not p.mo.metalsonic then
		p.mo.metalsonic = {
			dmt = 0,
			dmspeed = DMBASESPEED,
		}
	end

	DashModeTick(p)
end)

addHook("MobjDamage", function(mo)
	if not Valid(mo.player) then return end
	if not mo.metalsonic then return end

	DashModeDisable(mo.player)
end, MT_PLAYER)

addHook("AbilitySpecial", function(p)
	if not Valid(p) then return end
	if not p.mo.metalsonic then return end
	if p.pflags & PF_THOKKED then return end

	-- double jump
	p.pflags = $ & ~PF_JUMPED
	P_DoJump(p, false)
	p.mo.state = S_PLAY_SPRING
	S_StartSound(p.mo, sfx_s3k45)
	p.pflags = $|PF_THOKKED
end)

addHook("JumpSpinSpecial", function(p)
	if not Valid(p) then return end
	if not p.mo.metalsonic then return end
	if p.pflags & PF_THOKKED then return end
	if p.lastbuttons & BT_SPIN then return end

	-- double jump
	local momz = p.mo.momz
	local flip = P_MobjFlip(p.mo)

	p.pflags = $ & ~PF_JUMPED
	P_DoJump(p, false)
	p.mo.state = S_PLAY_FALL
	S_StartSound(p.mo, sfx_s3k45)

	p.mo.momz = min(-$*flip, (momz*flip)*3/2)*flip
	p.pflags = $|PF_THOKKED
end)