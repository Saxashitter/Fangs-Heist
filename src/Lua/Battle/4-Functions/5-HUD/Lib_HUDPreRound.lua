local B = CBW_Battle

local white = "\x80"
local gray = "\x86"
local yellow = "\x82"

B.PreRoundHUD = function(v,player,cam)
	local roulette_x = player.roulette_x
	if (roulette_x == nil) return end
	
	local lockedin = (leveltime + 17 >= CV_FindVar("hidetime").value*TICRATE)
	if lockedin then roulette_x = 0 end
	
	if (B.HUDAlt) and B.PlayerCanRoulette(player) then
		local x, y = 160, 72
		local flags = V_HUDTRANS|V_SNAPTOTOP|V_PERPLAYER|V_ALLOWLOWERCASE
		-- Display pre-round hint: We can change characters during this period.
		if not (splitscreen) then v.drawString(x, y, gray.."Waiting for players...", flags, "thin-center") end
		v.drawString(x, y + 8, yellow.."Select a character!", flags, "center")
		
		if (leveltime <= 60) return end
		
		-- Display pre-round character roulette. Show previous and next characters we're gonna change into.
		for n = -5, 5 do
			local blink = (leveltime % 2 and leveltime + 35 >= CV_FindVar("hidetime").value*TICRATE)
			if (n != 0 and (lockedin or blink))
				continue
			end
			
			local cflags = V_SNAPTOTOP|V_PERPLAYER
			local trans = V_10TRANS * max(0, abs(n*2) - 1)
			local scale = (n==0) and FRACUNIT*3/2 or FRACUNIT
			local xoffs = (x-8)*FRACUNIT + roulette_x + ((40*FRACUNIT)*n)
			local yoffs = (y+36)*FRACUNIT
			
			local character = (player.skin) and #skins[player.skin] or 0
			local tocharacter = 0
			repeat
				if (n > 0)
					character = $+1
					tocharacter = $+1
					if character >= #skins then character = 0 end
					if R_SkinUsable(player, character) == false
						n = $+1
					end
				elseif (n < 0)
					character = $-1
					tocharacter = $-1
					if character < 0 then character = #skins-1 end
					if R_SkinUsable(player, character) == false
						n = $-1
					end
				elseif (n == 0)
					break
				end
			until tocharacter == n
			
			if lockedin
				scale = $ + max(0, ((CV_FindVar("hidetime").value*TICRATE) - leveltime - 12)*FRACUNIT/8)
			end
			
			yoffs = $ + scale*3
			
			v.drawScaled(
				xoffs+(8*FRACUNIT), yoffs, scale, v.getSprite2Patch(character, SPR2_LIFE), cflags|trans,
				v.getColormap(character, skins[character].prefcolor)
			)
		end
		v.draw(160-16, 100-9, v.cachePatch("M_FSEL"), V_HUDTRANSHALF|V_SNAPTOTOP|V_PERPLAYER)
	end
end