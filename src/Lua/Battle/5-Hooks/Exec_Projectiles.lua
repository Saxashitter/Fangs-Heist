local B = CBW_Battle
local PR = CBW_PowerCards

--Player v player projectile
addHook("MobjMoveCollide", function(...)
	return B.PlayerVSProjectileCollide(...)
end, MT_PLAYER)
addHook("MobjCollide", function(...)
	return B.PlayerVSProjectileCollide(...)
end, MT_PLAYER)

for mt = 1, #mobjinfo-1 do
	if mobjinfo[mt].flags&MF_MISSILE then
		mobjinfo[mt].flags = $ &~ MF_NOBLOCKMAP -- Allow AI to read projectile positions from the blockmap
		addHook("MobjThinker",function(mo)
			--NOTE: Projectiles added after BattleMod will need their own checks!
			return B.BattleMissileThinker(mo)
		end,mt)
	end
end

--Tails Projectiles
addHook("MobjThinker",function(mo)
	B.SonicBoomThinker(mo)
end,MT_SONICBOOM)

--Amy love hearts
addHook("MobjMoveCollide", function(mover,collide) if collide and (collide.battleobject or not(collide.flags&MF_SOLID)) then return end end, MT_PIKOWAVE)
addHook("MobjMoveBlocked", function(mo)
	--mo.fuse = max(1, $ - 9)
	S_StartSound(mo,sfx_nbmper)
end, MT_PIKOWAVE)
addHook("MobjThinker", function(mo)
	if mo.grow
		mo.scale = $ + FRACUNIT/45
	end
	mo.momx = $ * mo.friction / 100
	mo.momy = $ * mo.friction / 100
	mo.momz = $ - (P_MobjFlip(mo) * mo.scale)
end, MT_PIKOWAVEHEART)
addHook("MobjThinker", B.PikoWaveThinker, MT_PIKOWAVE)


--Piko tornado
addHook("TouchSpecial",B.DustDevilTouch,MT_DUSTDEVIL)
addHook("MobjMoveCollide",function(mover,collide)
	if not(collide.battleobject) then return end
	B.DustDevilTouch(mover,collide)
end,MT_DUSTDEVIL)
addHook("MobjThinker",B.DustDevilThinker, MT_DUSTDEVIL_BASE)
addHook("MobjSpawn",B.SwirlSpawn,MT_SWIRL)
addHook("MobjThinker",B.SwirlThinker, MT_SWIRL)
addHook("MobjSpawn",B.DustDevilSpawn,MT_DUSTDEVIL_BASE)

-- Fang cork
addHook("MobjSpawn",function(mo)
	return true -- Prevent the enabling of MF2_SUPERFIRE
end, MT_CORK)

addHook("MobjThinker",function(mo)
	if mo.flags&MF_MISSILE and mo.target and mo.target.player then
		local ghost = P_SpawnGhostMobj(mo)
		ghost.destscale = ghost.scale*4
		if not(gametyperules&GTR_FRIENDLY)
			ghost.colorized = true
			ghost.color = mo.target.player.skincolor
		end
	end
end,MT_CORK)

-- Fang Bomb
addHook("MobjFuse",B.FBombDetonate,MT_FBOMB)
addHook("MobjMoveCollide",B.BombCollide,MT_FBOMB)
addHook("MobjSpawn",B.FBombSpawn,MT_FBOMB)
addHook("MobjThinker",B.FBombThink,MT_FBOMB)



--Metal Sonic
addHook("MobjSpawn",B.DashSlicerSpawn,MT_DASHSLICER)
addHook("MobjThinker",B.DashSlicerThinker,MT_DASHSLICER)
addHook("MobjThinker",function(mo)
	mo.flags2 = $^^MF2_DONTDRAW
end,MT_SLASH)

-- Robo Missile
for n = MT_CRAWLAMISSILE,MT_JETJAWMISSILE
	addHook("MobjDeath",B.RoboMissileResetCarry,n)
	addHook("MobjRemoved",B.RoboMissileResetCarry,n)
	addHook("MobjSpawn",B.RoboMissileSpawn,n)
	addHook("MobjMoveCollide",B.RoboMissileCollide,n)
	addHook("MobjThinker",B.RoboMissileThinker,n)
	addHook("MobjFuse",B.RoboMissileFuse,n)
end

--Other
addHook("MobjThinker",B.RockBlastObject, MT_ROCKBLAST)
addHook("MobjThinker",function(mo) if P_IsObjectOnGround(mo) then P_RemoveMobj(mo) return true end end,MT_ROCKCRUMBLE2)

addHook("MobjThinker", B.TeamFireTrail, MT_SPINFIRE)
addHook("MobjSpawn", PR.ParticleSpawn, MT_TUMBLEPARTICLE)