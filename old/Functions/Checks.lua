function FangsHeist.isMode()
	return FangsHeist.GametypeIDs[gametype] ~= nil
end

function FangsHeist.isServer()
	return isserver or isdedicatedserver
end

-- intermission
function FangsHeist.isGameAnim()
	return FangsHeist.Net.game_over_ticker < FangsHeist.GAME_TICS
end

function FangsHeist.isResultsScreen()
	return not FangsHeist.isGameAnim() and FangsHeist.Net.game_over_ticker < FangsHeist.RESULTS_TICS
end

function FangsHeist.isMapVote()
	return not FangsHeist.isGameAnim() and not FangsHeist.isResultsScreen()
end