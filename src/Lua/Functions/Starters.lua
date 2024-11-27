local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local orig = FangsHeist.require"Modules/Variables/player"

sfxinfo[freeslot "sfx_gogogo"].caption = "G-G-G-G-GO! GO! GO!"

FangsHeist.escapeThemes = {
	"SPRHRO",
	"THECUR",
	"WILFOR"
}
function FangsHeist.startEscape()
	if FangsHeist.Net.escape then return end

	local choice = P_RandomRange(1, #FangsHeist.escapeThemes)

	FangsHeist.Net.escape = true
	FangsHeist.Net.escape_theme = FangsHeist.escapeThemes[choice]

	S_StartSound(nil, sfx_gogogo)

	FangsHeist.changeBlocks()
	FangsHeist.doSignpostWarning(FangsHeist.playerHasSign(displayplayer))
end

function FangsHeist.startIntermission()
	if FangsHeist.Net.game_over then
		return
	end

	S_FadeMusic(0, MUSICRATE/2)

	for mobj in mobjs.iterate() do
		if not (mobj and mobj.valid) then return end

		mobj.flags = $|MF_NOTHINK
	end

	FangsHeist.Net.game_over = true
end

local oppositefaces = {
	--awake to asleep
	["JOHNBLK1"] = "JOHNBLK0",
	--asleep to awake
	["JOHNBLK0"] = "JOHNBLK1",
}

function FangsHeist.changeBlocks()
	for sec in sectors.iterate do
		for rover in sec.ffloors() do
			if not rover.valid then continue end
			local side = rover.master.frontside
			
			if not (side.midtexture == R_TextureNumForName("JOHNBLK1")
			or side.midtexture == R_TextureNumForName("JOHNBLK0")) then
			--or side.midtexture == R_TextureNumForName("TKISBKB1")
			--or side.midtexture == R_TextureNumForName("TKISBKB2"))
				continue
			end
			
			local oppositeface = oppositefaces[
				string.sub(R_TextureNameForNum(side.midtexture),1,8)
			]
				
			--???????
			if oppositeface == nil then continue end
			
			if rover.flags & FOF_SOLID
			--awake to asleep
				rover.flags = $|FOF_TRANSLUCENT|FOF_NOSHADE &~(FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS)
				rover.alpha = 128
			else
			--asleep to awake
				rover.flags = $|FOF_SOLID|FOF_CUTLEVEL|FOF_CUTSOLIDS &~(FOF_TRANSLUCENT|FOF_NOSHADE)
				rover.alpha = 255
			end
			side.midtexture = R_TextureNumForName(oppositeface)
		end
	end
end

function FangsHeist.makePlayerConscious(p)
	if not p.heist then return end

	p.heist.conscious_meter_heal = orig.conscious_meter_heal
	p.heist.conscious_meter = FU


	if p.mo.health then
		p.powers[pw_flashing] = TICRATE
		p.mo.state = S_PLAY_STND
	end
end

local function sac(name, caption)
	local sfx = freeslot(name)

	sfxinfo[sfx].caption = caption

	return sfx
end

FangsHeist.voicelines = {
	sonic = {
		pain = {
			sac("sfx_paiso1", "HM!");
			sac("sfx_paiso2", "OH NO!");
			sac("sfx_paiso3", "WOAH!");
			sac("sfx_paiso4", "EuWOAH!")
		},
		signgot = {
			sac("sfx_sgnso1", "Hey hey hey!");
			sac("sfx_sgnso2", "Hooray!");
			sac("sfx_sgnso3", "I better get outta here...");
			sac("sfx_sgnso4", "Now this is more like it!");
			sac("sfx_sgnso5", "I got it!!")
		},
		hit = {
			sac("sfx__hitso1", "You're no match for me!"),
			sac("sfx__hitso2", "Hey, this time you're not getting away!"),
			sac("sfx__hitso3", "You had your fun, now it's my turn!"),
			sac("sfx__hitso4", "Aw yeah!")
		}
	}
}

function FangsHeist.startVoiceline(p, sound)
	if not (p and p.mo) then return end

	if not FangsHeist.voicelines[p.mo.skin] then return end
	if not FangsHeist.voicelines[p.mo.skin][sound] then return end

	local data = FangsHeist.voicelines[p.mo.skin]
	local sounds = FangsHeist.voicelines[p.mo.skin][sound]
	local choice = P_RandomRange(1, #sounds)

	// stop all sounds currently playing
	for _,soundtbl in pairs(data) do
		for _,sound in pairs(soundtbl) do
			S_StopSoundByID(p.mo, sound)
		end
	end

	S_StartSound(p.mo, sounds[choice])
end

COM_AddCommand("fh_endgame", function(p)
	FangsHeist.startIntermission()
end, COM_ADMIN)