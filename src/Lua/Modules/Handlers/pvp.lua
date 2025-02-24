local module = {}

function module.tick()
	pcall(function ()
		CBW_Battle.Gametypes.Battle[GT_FANGSHEIST] = true
	end)
end

return module