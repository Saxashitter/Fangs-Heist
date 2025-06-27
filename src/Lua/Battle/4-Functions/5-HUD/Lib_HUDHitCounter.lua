local B = CBW_Battle

B.HitCounterHUD = function(v,player,cam)
	if B.HitCounter == 0
	or B.TrainingDummy == nil
	return end
	local xo = 160
	local yo = 160
	if (B.ArenaGametype() and #B.Arena.Survivors > 3) then
		yo = $+20
	end
	v.drawString(xo,yo,"Hits",V_HUDTRANS|V_SNAPTOBOTTOM|V_PERPLAYER,"center")
	v.drawString(xo,yo+8,tostring(B.HitCounter),V_HUDTRANS|V_SNAPTOBOTTOM|V_PERPLAYER,"center")
end