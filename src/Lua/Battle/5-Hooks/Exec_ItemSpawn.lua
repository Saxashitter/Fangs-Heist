local B = CBW_Battle
local I = B.Item

--Item Bubbles
addHook("MobjSpawn", function(mo)
	I.ItemBubbleCreate(mo)
end,MT_ITEM_BUBBLE)

addHook("MobjRemoved",function(mo)
	I.ItemBubbleRemoved(mo)
end,MT_ITEM_BUBBLE)

addHook("TouchSpecial", function(mo,pmo)
	I.ItemReward(mo,pmo.player)
end,MT_ITEM_BUBBLE)

addHook("MobjThinker", function(mo)
	I.ItemBubbleThinker(mo)
end,MT_ITEM_BUBBLE)

addHook("MobjMoveBlocked",function(mo)
	if mo.fragile then P_RemoveMobj(mo) end
end,MT_ITEM_BUBBLE)

--Item Spawn Events

for n = MT_ITEM_SPAWN,MT_STRONGRANDOM_FLURRY do
	addHook("MobjThinker",function(mo)
		return I.SpawnThinker(mo)
	end, n)
	addHook("MobjSpawn",function(mo) 
		return I.SpawnSettings(mo)
	end, n)
	addHook("MobjFuse",function(mo)
		return I.ItemSpawnFuse(mo)
	end, n)
end


addHook("MobjThinker",function(mo)
	return I.ItemPrespawnThinker(mo)
end,MT_ITEM_PRESPAWN)

--Item Spawn Map Things
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"global") end,MT_GLOBAL_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"ring") end,MT_RING_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"superring") end,MT_SUPERRING_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"pity") end,MT_PITY_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"whirlwind") end,MT_WHIRLWIND_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"force") end,MT_FORCE_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"elemental") end,MT_ELEMENTAL_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"attraction") end,MT_ATTRACTION_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"armageddon") end,MT_ARMAGEDDON_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"roulette") end,MT_ROULETTE_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"s3bubble") end,MT_S3BUBBLE_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"s3flame") end,MT_S3FLAME_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"s3lightning") end,MT_S3LIGHTNING_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"s3roulette") end,MT_S3ROULETTE_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"hyperroulette") end,MT_HYPERROULETTE_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"weakrandom") end,MT_WEAKRANDOM_SPAWN)
addHook("MapThingSpawn",function(mo,thing) I.StandardSpawnerSettings(mo,thing,"strongrandom") end,MT_STRONGRANDOM_SPAWN)

--Carousel Spawn Events
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"ring") end,MT_RING_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"superring") end,MT_SUPERRING_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"pity") end,MT_PITY_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"whirlwind") end,MT_WHIRLWIND_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"force") end,MT_FORCE_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"elemental") end,MT_ELEMENTAL_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"attraction") end,MT_ATTRACTION_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"armageddon") end,MT_ARMAGEDDON_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"roulette") end,MT_ROULETTE_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"s3bubble") end,MT_S3BUBBLE_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"s3flame") end,MT_S3FLAME_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"s3lightning") end,MT_S3LIGHTNING_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"s3roulette") end,MT_S3ROULETTE_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"hyperroulette") end,MT_HYPERROULETTE_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"weakrandom") end,MT_WEAKRANDOM_CAROUSEL)
addHook("MapThingSpawn",function(mo,thing) I.CarouselSettings(mo,thing,"strongrandom") end,MT_STRONGRANDOM_CAROUSEL)

--Flurry Spawn Events
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"ring") end,MT_RING_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"superring") end,MT_SUPERRING_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"pity") end,MT_PITY_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"whirlwind") end,MT_WHIRLWIND_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"force") end,MT_FORCE_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"elemental") end,MT_ELEMENTAL_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"attraction") end,MT_ATTRACTION_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"armageddon") end,MT_ARMAGEDDON_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"roulette") end,MT_ROULETTE_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"s3bubble") end,MT_S3BUBBLE_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"s3flame") end,MT_S3FLAME_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"s3lightning") end,MT_S3LIGHTNING_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"s3roulette") end,MT_S3ROULETTE_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"hyperroulette") end,MT_HYPERROULETTE_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"weakrandom") end,MT_WEAKRANDOM_FLURRY)
addHook("MapThingSpawn",function(mo,thing) I.FlurrySettings(mo,thing,"strongrandom") end,MT_STRONGRANDOM_FLURRY)