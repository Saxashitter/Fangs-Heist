local modifier = {name = "Double Time"}

function modifier:tick()
	if FangsHeist.Net.time_left then
		FangsHeist.Net.time_left = max(1, $-1)
		FangsHeist.setTimerTime(FangsHeist.Net.time_left, FangsHeist.Net.max_time_left)
	end
end

return modifier