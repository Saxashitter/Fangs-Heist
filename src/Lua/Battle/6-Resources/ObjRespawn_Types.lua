-- you only need to make this assertion if using AddObjectTypeRespawn,
-- custom FOF checks can be loaded in any order
assert(AddObjectTypeRespawn, "This must be loaded after respawn.lua!")


-- more complicated example: spikes and wall spikes

-- this is used for shouldrespawnfunc
-- forces either type of spike to always respawn
local function SpikeShouldRespawn()
	return true
end

-- this is used for timerfunc
-- forces either type of spike to respawn in 3 seconds
local function SpikeTimer()
	return 10*TICRATE
end

AddObjectTypeRespawn(
	-- objecttype
	MT_SPIKE,

	-- shouldrespawnfunc
	SpikeShouldRespawn,

	-- timerfunc
	SpikeTimer,

	-- spawnfunc (use default RegularSpawn)
	nil,

	-- setupfunc
	function(spawnpoint, mo)
		if not (spawnpoint and spawnpoint.valid and mo and mo.valid) then return end

		mo.angle = FixedAngle(spawnpoint.angle << FRACBITS)

		-- Use per-thing collision for spikes if the deaf flag isn't checked.
		if not (spawnpoint.options & MTF_AMBUSH)
			mo.flags = ($ & ~(MF_NOBLOCKMAP|MF_NOGRAVITY|MF_NOCLIPHEIGHT)) | MF_SOLID
		else
			mo.flags2 = $|MF2_AMBUSH
		end

		-- Pop up spikes!
		if spawnpoint.options & MTF_OBJECTSPECIAL
			mo.flags = $ & ~MF_SCENERY

			local fuseduration = spawnpoint.angle + mo.info.speed
			mo.fuse = ((16 - spawnpoint.extrainfo)*fuseduration/16)-((leveltime+3)%(2*fuseduration)) -- 'fast forward' the spike to where it should be at this leveltime

			local switchstate = false
			while mo.fuse <= 0 -- negative fuse means we're on the next half of the cycle
				mo.fuse = $ + fuseduration
				switchstate = not $
			end

			if spawnpoint.options & MTF_EXTRA -- one more flip for MTF_EXTRA
				switchstate = not $
			end

			if switchstate -- okay !
				mo.state = mo.info.meleestate
			end
		end

		if spawnpoint.options & MTF_OBJECTFLIP
			mo.eflags = $|MFE_VERTICALFLIP
			mo.flags2 = $|MF2_OBJECTFLIP
		end
	end
)

AddObjectTypeRespawn(
	-- objecttype
	MT_WALLSPIKE,

	-- shouldrespawnfunc
	SpikeShouldRespawn,

	-- timerfunc (use default RegularTimer)
	SpikeTimer,

	-- spawnfunc (use default RegularSpawn)
	nil,

	-- setupfunc
	function(spawnpoint, mo)
		if not (spawnpoint and spawnpoint.valid and mo and mo.valid) then return end

		mo.angle = FixedAngle(spawnpoint.angle << FRACBITS)

		-- Use per-thing collision for spikes if the deaf flag isn't checked.
		if not (spawnpoint.options & MTF_AMBUSH)
			mo.flags = ($ & ~(MF_NOBLOCKMAP|MF_NOCLIPHEIGHT)) | MF_SOLID
		else
			mo.flags2 = $|MF2_AMBUSH
		end

		if spawnpoint.options & MTF_OBJECTFLIP
			mo.eflags = $|MFE_VERTICALFLIP
			mo.flags2 = $|MF2_OBJECTFLIP
		end

		-- Pop up spikes!
		if spawnpoint.options & MTF_OBJECTSPECIAL
			mo.flags = $ & ~MF_SCENERY

			local fuseduration = spawnpoint.angle + mo.info.speed
			mo.fuse = ((16 - spawnpoint.extrainfo)*fuseduration/16)-((leveltime+3)%(2*fuseduration)) -- 'fast forward' the spike to where it should be at this leveltime

			local switchstate = false
			while mo.fuse <= 0 -- negative fuse means we're on the next half of the cycle
				mo.fuse = $ + fuseduration
				switchstate = not $
			end

			if spawnpoint.options & MTF_EXTRA -- one more flip for MTF_EXTRA
				switchstate = not $
			end

			if switchstate -- okay !
				mo.state = mo.info.meleestate
			end
		end

		-- spawn base
		local mobjangle = mo.angle
		local baseradius = mo.radius - mo.scale
		local base = P_SpawnMobjFromMobj(mo,
			P_ReturnThrustX(mo, mobjangle ^^ ANGLE_180, baseradius),
			P_ReturnThrustY(mo, mobjangle ^^ ANGLE_180, baseradius),
			0, MT_WALLSPIKEBASE)
		base.angle = mobjangle + ANGLE_90
		base.target = mo
		mo.tracer = base
	end
)