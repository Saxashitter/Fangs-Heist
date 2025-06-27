local B = CBW_Battle

B.GetPlayerText = function(player)
	if not(player and player.name) then return ("\x82".."<invalid player>".."\x80") end
	local t = player.name
	if G_GametypeHasTeams() then
		if player.ctfteam == 1 then t = "\x85"..$.."\x80" end
		if player.ctfteam == 2 then t = "\x84"..$.."\x80" end
	end
	return t
end

B.PrintGameFeed = function(player1,string1,player2,string2)
	if not(netgame) return end
	local text = ""
	if player1 then
		text = $+B.GetPlayerText(player1)
	end
	if string1 then
		text = $+string1
	end
	if player2 then
		text = $+B.GetPlayerText(player2)
	end
	if string2 then
		text = $+string2
	end
	print(text)
end

B.CustomHurtMessage = function(player,source,bullettext,hurttext,killtext)
	//Defining playertext
	local playertext = B.GetPlayerText(player)
	//Defining sourcetext
	local sourcetext = "<sourcetext>"
	if source and source.player then 
		sourcetext = B.GetPlayerText(source.player)
	elseif source and not(source.player) then
		if source.name then
			sourcetext = source.name.."\x80"
		else
			source = nil
		end
	end
	//Defining damagetext
	if hurttext == nil then hurttext = "hit" end
	if killtext == nil then killtext = "killed" end
	//Which do we choose?
	local choosehurttext
	if (player.mo.health) then
		choosehurttext = hurttext
	else
		choosehurttext = killtext
	end
	local text = ""
	//If no sourceplayer
	if source == nil then
		text = playertext.." was "..choosehurttext
		if (bullettext) then
			text = $.." by a stray "..bullettext.."."
		end
	//If attacking player
	else
		text = sourcetext
		if (bullettext) then
			text = $.."'s "..bullettext
		end	
		text = $.." "..choosehurttext.." "..playertext.."."
	end
	return text
end
