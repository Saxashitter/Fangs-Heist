local dialogue = FangsHeist.require "Modules/Handlers/dialogue"

local fangdiag = {}

fangdiag.portrait = "FH_DIALOGUE_FANG_DEFAULT"

fangdiag["escapestart_nosign"] = {
	"EY! Someone took the signpost! Don't you DARE leave without it! Do ya know how valuable it is!?",
	"HEY! Get that signpost!",
	"What do ya think you're doin, slowpoke!? Get my sign!",
	"If ya don't get my sign, I'll rip the fur off of ya. Get it! NOW!"
}

fangdiag["escapestart_sign"] = {
	"You got my sign? Great. Make it back to the beginning, don't let anyone snatch it from ya.",
	"Good job, now head back before anyone gets ya.",
	"You're doin' great. Make it back to where 'ya came from."
}

fangdiag["start"] = {
	"I got a client who wants some goods real bad. Get a good supply, and I'll give you a cut.",
	"Alright, your mission is simple. Get me my money, and I'll consider sharing it with ya.",
}

fangdiag["death"] = {
	"NO! No, no, no!! We lost 'em!",
	"DAAAAAAH!! Now I'll never get my money!!",
	"Aw... There go those sweet profits."
}

return fangdiag