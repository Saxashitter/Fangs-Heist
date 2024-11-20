local module = {}

function module.think()
	if not FangsHeist.Net.escape then
		return
	end

	FangsHeist.Net.time_left = max(0, $-1)
	print "Decreasing..."

	if not (FangsHeist.Net.time_left) then
		print "Times up! Spawn Eggman and have him chase every player down."
	end
end

function module.manageEscape(p)
end

return module