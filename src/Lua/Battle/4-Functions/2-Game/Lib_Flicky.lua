-- This fixes a 2.2.9 bug that crashes the game when players spawn too close to flickies. The script should be removed after 2.2.10 releases.

if VERSIONSTRING == "v2.2.9"
	A_FlickyCenter = function(mo, var1, var2)
		if leveltime < 5 
			mo.mapload = true
			return true
		else
			super(mo, var1, var2)
		end
	end


	for mt = MT_FLICKY_01, MT_SECRETFLICKY_02_CENTER
		addHook('MobjThinker',function(mo)
			if leveltime == 5 and mo.mapload
				P_SpawnMobjFromMobj(mo,0,0,0,mo.type)
				P_RemoveMobj(mo)
				return true 
			end
		end, mt)
	end
end