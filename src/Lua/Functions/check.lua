function FH:IsMode()
	return FH.GametypeIDs[gametype] ~= nil
end

function FH:IsGameAnim()
	return FH_NET.game_over_ticker < FH_INT_GAME
end

function FH:IsResultsScreen()
	return not self:IsGameAnim() and FH_NET.game_over_ticker < FH_INT_RESULTS
end

function FH:IsMapVote()
	return not self:IsGameAnim() and not self:IsResultsScreen()
end