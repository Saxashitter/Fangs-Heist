states[freeslot "S_FH_TREASURE"] = {
	sprite = freeslot "SPR_TRES",
	frame = A,
	tics = -1,
	action = function(mo)
		local i = #FangsHeist.treasures
		mo.frame = ($ & ~FF_FRAMEMASK)|P_RandomKey(i)
	end
}

FangsHeist.treasures = {
	{
		name = "Franklin Badge",
		desc = "This MIGHT have been used in a kite experiment.",
	};
	{
		name = "Light Burden",
		desc = "You only have One Shot.",
	};
	{
		name = "Rainy Ukelele",
		desc = "...And his music was electric.",
	};
	{
		name = "Jet Lotus",
		desc = "He's RAMPING!!",
	};
	{
		name = "Tempest Ribbon",
		desc = "The girl faced endless conflict.",
	};
	{
		name = "Fatalis Ribbon",
		desc = "The girl was shrouded in unyielding light.",
	};
	{
		name = "Galactic Talisman",
		desc = "A symbol for cool guys and intergalactic armies alike!",
	};
	{
		name = "Writer's Mask",
		desc = "I just can't GET ENUF!",
	};
	{
		name = "Strongest Plush",
		desc = "Baka! Baka!",
	};
	{
		name = "Saint's Knife",
		desc = "The Fickle Princess left the Hero with nothing but hate in his heart.",
	};
}

local function OnCollect(mobj, pmo)
	local key = (mobj.frame & FF_FRAMEMASK)+1
	local data = FangsHeist.treasures[key]

	pmo.player.heist.treasure_name = data.name
	pmo.player.heist.treasure_desc = data.desc
	pmo.player.heist.treasure_time = 3*TICRATE

	S_StartSound(pmo, sfx_kc30)
	FangsHeist.playVoiceline(pmo.player, "treasure")
end

local function CanPickUp(p)
	local gamemode = FangsHeist.getGamemode()

	return not gamemode:treasureblacklist()
end

return {
	radius = 8*FU,
	height = 16*FU,
	profit = 160,
	state = S_FH_TREASURE,
	onPickUp = OnCollect,
	canPickUp = caCanPickUp
}