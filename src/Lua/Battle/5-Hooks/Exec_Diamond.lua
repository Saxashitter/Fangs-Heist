local B = CBW_Battle
local D = B.Diamond
addHook("TouchSpecial",function(mo,toucher)
	D.Collect(mo,toucher)
	return true
end,MT_DIAMOND)


addHook("MobjThinker",D.Thinker,MT_DIAMOND)

addHook("MobjFuse",function(mo)
	mo.flags = $|MF_SPECIAL
	return true
end,MT_DIAMOND)