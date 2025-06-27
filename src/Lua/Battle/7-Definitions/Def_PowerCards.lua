local PR = CBW_PowerCards

/*-- Enable this item to test default power card functionality.
table.insert(CBW_PowerCardQueue,{
	name 		= nil,
	chance		= nil,
	health		= nil,
	flags		= nil,
	state		= nil,
	mapthing	= nil,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= nil,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil,
})
*/

table.insert(CBW_PowerCardQueue,{
	name 		= "Capsule",
	chance		= 4,
	flags		= PCF_CUSTOM|PCF_CONTAINER,
	mobj		= MT_POWERCARDCAPSULE,
	mapthing	= MT_POWERCARDCAPSULE_SPAWNPOINT,
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Blessing",
	chance		= 1,
	health		= TICRATE*3+15,
	flags		= PCF_HUDWARNING,
	state		= S_POWERCARD_BLESSING,
	mapthing	= MT_POWERCARDSPAWN_BLESSING,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= PR.BlessingHoldFunc,
	func_touch	= PR.HealCardSFX,
	func_drop 	= nil,
	func_expire	= nil,
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Disable",
	chance		= 4,
	health		= TICRATE*2,
	flags		= PCF_HUDWARNING|PCF_EVENT,
	state		= S_POWERCARD_DISABLE,
	mapthing	= MT_POWERCARDSPAWN_DISABLE,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= PR.DisableHoldFunc,
	func_touch	= PR.HealCardSFX,
	func_drop 	= nil,
	func_expire	= nil,
})

table.insert(CBW_PowerCardQueue,{
		name 		= "Hyper",
		chance		= 10,
		health 		= TICRATE*12,
		flags		= 0,
		state		= S_POWERCARD_HYPER,
		mapthing	= MT_POWERCARDSPAWN_HYPER,
		func_spawn	= nil,
		func_idle 	= nil,
		func_hold	= PR.HyperHoldFunc,
		func_touch	= PR.HyperTouchFunc,
		func_drop 	= PR.HyperUnsetFunc,
		func_expire	= PR.HyperUnsetFunc,
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Meltdown",
	chance		= 4,
	health		= TICRATE*3+10,
	flags		= PCF_HUDWARNING|PCF_EVENT,
	state		= S_POWERCARD_MELTDOWN,
	mapthing	= MT_POWERCARDSPAWN_MELTDOWN,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= PR.MeltdownHoldFunc,
	func_touch	= PR.HealCardSFX,
	func_drop 	= nil,
	func_expire	= nil,
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Particles",
	chance		= 6,
	health		= TICRATE*12,
	flags		= 0,
	state		= S_POWERCARD_PARTICLES,
	mapthing	= MT_POWERCARDSPAWN_PARTICLES,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= PR.ParticlesHoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil,
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Ringslinger",
	chance		= 5,
	health		= 16*6,
	flags		= PCF_NOSPIN|PCF_RUNNERDEBUFF|PCF_RINGSLINGER,
	state		= S_POWERCARD_RINGSLINGER,
	mapthing	= MT_POWERCARDSPAWN_RINGSLINGER,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= PR.RingslingerHoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil,
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Ring-Up",
	chance		= 7,
	health		= 32*12,
	flags		= 0,
	state		= S_POWERCARD_RINGS,
	mapthing	= MT_POWERCARDSPAWN_RINGS,
	func_spawn	= nil,
	func_idle 	= PR.RingUpIdleFunc,
	func_hold	= PR.RingUpHoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil, 
})

table.insert(CBW_PowerCardQueue, {
	name 		= "Spite",
	chance		= 4,
	health		= TICRATE*6 + 10,
	flags		= PCF_HUDWARNING|PCF_EVENT,
	state		= S_POWERCARD_SPITE,
	mapthing	= MT_POWERCARDSPAWN_SPITE,
	func_spawn	= nil,
	func_idle 	= nil,
	func_hold	= PR.SpiteHoldFunc,
	func_touch	= nil,
	func_drop 	= nil,
	func_expire	= nil,
})