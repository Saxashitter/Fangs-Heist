local B = CBW_Battle
for n = 0, #mobjinfo-1 do
	if mobjinfo[n].flags&MF_SPRING
		addHook("MobjSpawn",function(mo)
			if twodlevel then
				mo.scale = B.TwoDFactor($)
			end
		end, n)
	end
end