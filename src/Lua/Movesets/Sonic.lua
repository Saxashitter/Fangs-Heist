local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end

-- first we modify the spring
addHook("MobjThinker", function(spring)
	if not spring.sonic_ability then return end

	local dur = 12
	local t = FixedDiv(min(dur, spring.fuse), dur)

	spring.alpha = t
end, MT_BLUESPRING)

--[[FangsHeist.makeCharacter("sonic1", {altSkin=true})
FangsHeist.makeCharacter("sonic2", {altSkin=true})
FangsHeist.makeCharacter("sonic3", {altSkin=true})]]
FangsHeist.makeCharacter("sonic", {
	pregameBackground = "FH_PREGAME_SONIC",
	skins = {
		{name = "Super Sonic"},
		--[[we will meet again
		{name = "SSNSonic"},
		{name = "Super SSNSonic"},
		{name = "F. Sonic"},
		{name = "Super F. Sonic"},
		{name = "Sonikku"},
		{name = "Xtreme Sonic"}, ]]
	},
	voicelines = {
		attack = {
			sac("sfx_sncat1", "Grunt"),
			sac("sfx_sncat2", "Grunt"),
			sac("sfx_sncat3", "Grunt"),
			sac("sfx_sncat4", "Grunt"),
			sac("sfx_sncat5", "Grunt")
		},
		death = {sac("sfx_sncdie", "death.wav")},
		escape = {sac("sfx_sncesc", "Something tells me something's not right here...")},
		hurt = {
			sac("sfx_snchr1", "Grunt"),
			sac("sfx_snchr2", "Grunt"),
			sac("sfx_snchr3", "Grunt"),
			sac("sfx_snchr4", "Grunt"),
			sac("sfx_snchr5", "Grunt"),
		},
		block = {
			sac("sfx_sncpy1", "Too slow!"),
			sac("sfx_sncpy2", "Try again!"),
			sac("sfx_sncpy3", "You thought that was gonna work?"),
		},
		shield = {
			sac("sfx_sncpa1", "Come at me!"),
			sac("sfx_sncpa2", "Try this on for size!"),
			sac("sfx_sncpa3", "You won't!"),
		},
		accept = {
			sac("sfx_sncsel", "Oh yeah!")
		},
		signpost = {
			sac("sfx_sncsg1", "I got it now, suckers!"),
			sac("sfx_sncsg2", "Heh heh!"),
			sac("sfx_sncsg3", "Catch me if you can... If you want it back!"),
		},
		treasure = {
			sac("sfx_snctr1", "Woah, what's this little thing?"),
			sac("sfx_snctr2", "This looks funny, I'm keeping it."),
		}
	}
})

local function check(p)
	return FangsHeist.isMode() and p and p.valid and p.mo and p.mo.health and p.mo.skin == "sonic"
end

local function thrustInDirection(p, maxSpeed, lerp)
	local thrustX = P_ReturnThrustX(nil, p.mo.angle, maxSpeed)
	local thrustY = P_ReturnThrustY(nil, p.mo.angle, maxSpeed)

	p.mo.momx = ease.linear(lerp, $, thrustX)
	p.mo.momy = ease.linear(lerp, $, thrustY)
end

local function directionThok(p)
	thrustInDirection(p, p.actionspd, FU/12)
	if p.cmd.buttons & BT_JUMP > 0 then
		p.mo.momz = ease.linear(FU/12, $, 0)
	end
end

addHook("AbilitySpecial", function(p)
	if not check(p) then return end
	if p.pflags & PF_THOKKED then return end

	P_SpawnThokMobj(p)
	S_StartSound(p.mo, sfx_thok)
	p.mo.sonic_thoktics = 12

	directionThok(p)
	p.pflags = $|PF_THOKKED
	return true
end)

addHook("JumpSpinSpecial", function(p)
	if not check(p) then return end
	if p.pflags & PF_THOKKED then return end
	if p.lastbuttons & BT_SPIN > 0 then return end

	local info = mobjinfo[MT_BLUESPRING]
	local spring = P_SpawnMobjFromMobj(p.mo, 0,0,-info.height/2, MT_BLUESPRING)

	p.mo.momz = 0
	spring.fuse = 2*TICRATE
	spring.sonic_ability = true
end)

addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not check(p) then return end

	if p.mo.sonic_thoktics
	and not P_PlayerInPain(p)
	and not P_IsObjectOnGround(p.mo)
	and p.pflags & PF_JUMPED then
		directionThok(p)
		p.mo.sonic_thoktics = $-1

		local thok = P_SpawnMobjFromMobj(p.mo, 0,0,0, MT_THOK)
		thok.scale = FU/2
		thok.destscale = FU/2
		thok.alpha = tofixed("0.25")
		thok.color = p.mo.color
	else
		p.mo.sonic_thoktics = nil
	end
end)