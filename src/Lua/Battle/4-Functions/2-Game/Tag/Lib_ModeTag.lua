local B = CBW_Battle

B.HideTime = function()
	if (server) then
		if G_TagGametype() then
			COM_BufInsertText(server,"hidetime 30")
		elseif B.BattleCampaign()
			COM_BufInsertText(server,"hidetime 10")
		else
			COM_BufInsertText(server,"hidetime 15")
		end
	end
end

B.TagCam = function(player, runner)
	if (runner and runner.valid)
		if G_TagGametype()
		and not (runner.pflags&PF_TAGIT)
			return false
		end
	end
end