local PR = CBW_PowerCards

-- Item Capsule
addHook("MobjThinker", function(mo)
	return PR.ItemCapsuleThinker(mo)
end, MT_POWERCARDCAPSULE)

addHook("TouchSpecial",function(...)
	return PR.ItemCapsuleTouchSpecial(...)
end, MT_POWERCARDCAPSULE)

addHook("MobjDeath", function(mo)
	return PR.ItemCapsuleDeath(mo)
end, MT_POWERCARDCAPSULE)

addHook("ShouldDamage", function(...)
	return PR.ItemCapsuleShouldDamage(...)
end, MT_POWERCARDCAPSULE)

addHook("MobjSpawn",function(mo)
	return PR.ItemCapsuleSpawn(mo)
end,MT_POWERCARDCAPSULE)

-- Power Card
addHook("MobjSpawn",function(mo)
	return PR.PowerCardSpawn(mo)
end,MT_POWERCARD)

addHook("MobjThinker",function(mo)
	return PR.PowerCardThinker(mo)
end,MT_POWERCARD)

addHook("TouchSpecial",function(...)
	return PR.PowerCardTouch(...)
end,MT_POWERCARD)

addHook("MobjDeath",function(mo)
	return PR.PowerCardDeath(mo)
end,MT_POWERCARD)

-- Power Card Death Prop
addHook("MobjSpawn",function(mo)
	return PR.DeathPropSpawn(mo)
end,MT_POWERCARDDEATHPROP)

addHook("MobjThinker",function(mo)
	return PR.DeathPropThinker(mo)
end,MT_POWERCARDDEATHPROP)