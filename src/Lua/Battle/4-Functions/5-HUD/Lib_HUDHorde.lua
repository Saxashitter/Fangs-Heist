local B = CBW_Battle
local fighters = {}
B.HordeHUD = function(v,player,cam)
	if not(B.BattleCampaign() and B.Horde)
		return
	end
	local xo = 160
	local yo = 6
	v.drawString(xo,yo,"VS",V_HUDTRANS|V_SNAPTOTOP,"center")
	if leveltime%TICRATE == 0
		fighters = {}
		-- Get queued fighters
		for n = 1, #B.QueueFighters do
			local fighter = B.QueueFighters[#B.QueueFighters-n+1]
			if fighter.team == 1
				table.insert(fighters, fighter)
			end
		end
		-- Get current fighters
		local n = 31
		while n >= 0 do
			local player = players[n]
			n = $-1
			if player and player.bot and player.lives and player.ctfteam != 2 --We'll just assume specating bots will join red
				local mo = player.mo or player.realmo
				local t = {
					skin = mo.skin,
					color = player.skincolor,
					flags = player.battlespflags
				}
				table.insert(fighters, t)
			end
		end
	end
	
	if fighters and #fighters
		v.drawString(xo,yo+8,tostring(#fighters),V_HUDTRANS|V_SNAPTOTOP,"small-center")
		
		-- Draw fighter icons
		local w = 4 -- Icon spacing
		local M = 6 -- Icons per column
		for n, fighter in pairs(fighters) do
			n = $-1
			local patch = v.getSprite2Patch(fighter.skin, SPR2_LIFE)
			local colormap = fighter.flags & BSP_SHADOW and TC_RAINBOW or fighter.skin
			local color = v.getColormap(colormap, fighter.color)
			local x = (n%M)*w + xo + w/2 - w*M/2
			local y = (n/M)*w + yo + 16
			v.drawScaled(x*FRACUNIT, y*FRACUNIT, FRACUNIT>>2, patch, V_HUDTRANS, color)
		end
	end
end