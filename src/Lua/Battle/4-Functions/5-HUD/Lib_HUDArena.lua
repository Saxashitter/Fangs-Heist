local B = CBW_Battle
local A = B.Arena
local CV = B.Console

local testhud = 0

//Screen, team properties
local screenwidth,team_width,team_centergap

//Placement suffixes
local post = {"st","nd","rd","th","th","th","th","th","th","th"}

//Shield patches
local shpatch = function(n)
	if n==SH_WHIRLWIND then return "ARSHWIND" end
	if n==SH_ARMAGEDDON then return "ARSHARMG" end
	if n==SH_ELEMENTAL then return "ARSHELMT" end
	if n==SH_ATTRACT then return "ARSHATRC" end
	if n==SH_PINK then return "ARSHLOVE" end
	if n==SH_FLAMEAURA then return "ARSHFLAM" end
	if n==SH_BUBBLEWRAP then return "ARSHBUBL" end
	if n==SH_THUNDERCOIN then return "ARSHLITN" end
	if n&SH_FORCE then return "ARSHFORC" end
	if n != 0 then return "ARSHPITY" end //Default
end

local ringpatch = function(player)
	if (player.actionstate and player.rings)
		or (not(player.rings) and leveltime&4)
		return "ARRINGRD"
	end
	if not(player.actioncooldown)
		return "ARRINGYL"
	end
	return "ARRINGGR"
end


local f = FRACUNIT
local m = 1 //HUD size multiplier
//Set offsets
local xoffset = 0
local condensed = 0
local condense_threshold = 9 //We can only go up to this many players before the HUD becomes illegible with extra info
local condense_threshold2 = 13
local team_condense_threshold = 4
local team_condense_threshold2 = 6
local xshift1 = 10
local xshift2 = 10
local xshift3 = -4
local yoffset = 0
local xstart = 0
-- local xstart = 0
local left = 0
local right = 10
local bottom = 12
local color
local leftalign = "thin-right"
local rightalign = "thin"
local text = ""

local headw,headx,heady,heads,flags,
	livesx,livesy,livess,livesn,livesa,livesx2,livesy2,livesf,
	ringx,ringx2,ringy,rings,ringa,
	shieldw,shieldx,shieldy,shields,shieldf,shielda,
	stockx,stocky,stockn,stocks,stocka,
	scorex,scorey,scorea

local function setoffsets(player,m)
	flags = V_HUDTRANS|V_SNAPTOTOP//|V_PERPLAYER
	if not(player.mo and player.mo.health) then
		flags = V_SNAPTOTOP|V_HUDTRANSHALF//|V_PERPLAYER
	end
	//Head
	headw = 8*m
	headx = -headw/2
	heady = 6*m
	heads = f/2*m
	//Lives
	livess = f/3
	livesx = -headw/2-3
	livesy = 8*m+8
	livesy2 = 7*m
	if not(condensed) then
		livesy2 = $+3
	end
	livesx2 = -headw/2+1
	livesn = 6
	livesa = "small"
	livesf = V_HUDTRANS|V_SNAPTOTOP|V_FLIP//|V_PERPLAYER
	//Ring
	if not(condensed) then
		ringx = 1*m
		ringx2 = ringx + 6
	else
		ringx = 1
		ringx2 = ringx + 5
	end
	ringy = 2
	rings = f/2
	ringa = "small"
	//Shield
	shieldw = 4*m
-- 	shieldx = -2*m
	if not(condensed) then
		shieldy = headw/2-1
		shieldx = 1*m
	else
		shieldy = 6
		shieldx = 2
	end
	shields = f/2*m
	-- shieldf = V_SNAPTOTOP|V_PERPLAYER|V_HUDTRANSHALF
	shieldf = flags
	shielda = "left"
	//Shield Stock
	stockx = shieldw+shieldx+1
	stocky = shieldy
	stockn = 2
	stocks = f/2
	stocka = "left"
	//Score
	scorex = livesx-4
	scorey = livesy2
	scorea = "small"
end

A.HUD = function(v,player,cam)
	if not (B.HUDMain) then return end
	if not(B.ArenaGametype()) then 
		hud.enable("score")
	return end
	hud.disable("score")
	if splitscreen then return end
	local count, rcount, bcount
	
	if not(gametyperules & GTR_CAMPAIGN)
		count = #A.Survivors
		rcount = #A.RedSurvivors
		bcount = #A.BlueSurvivors
	else
		count = #A.Fighters
		rcount = #A.RedFighters
		bcount = #A.BlueFighters	
	end
	if count and testhud then 
		count = CV.SurvivalStock.value
		rcount = CV.SurvivalStock.value
		bcount = CV.SurvivalStock.value
	end
	local lerp_max = count+1
	local red_lerp_max = rcount+1
	local blue_lerp_max = bcount+1
	local r = 0
	local b = 0	
	local teams = G_GametypeHasTeams()
	//Draw all survivors
	for n = 1, count
		local p = A.Survivors[n]
		if not(G_GametypeUsesLives()) then
			p = A.Placements[n]
		elseif B.BattleCampaign()
			p = A.Fighters[n]
		end
		if testhud then
			p = A.Survivors[1]
		end
		if not(p and p.valid and p.mo and p.mo.valid) then continue end
		//Do condensation and boundaries/stretch
		condensed = 0
		screenwidth = 340
		team_centergap = 40
		yoffset = 0
		if (teams and p.ctfteam == 1 and rcount >= team_condense_threshold2)
			or (teams and p.ctfteam == 2 and bcount >= team_condense_threshold2)
			or (count >= condense_threshold2)
			then condensed = 2
			screenwidth = 320
			team_centergap = 64
			yoffset = 4
		elseif (teams and p.ctfteam == 1 and rcount >= team_condense_threshold)
			or (teams and p.ctfteam == 2 and bcount >= team_condense_threshold)
			or (count >= condense_threshold)
			then condensed = 1
			yoffset = 4
		end	
		team_width = (screenwidth-team_centergap)/2
		local lerp_amt 
		//FFA offsets
		if not(teams) then
			//Figure out how far along we are
			lerp_amt = f*n/lerp_max
			xoffset = screenwidth*lerp_amt/f+xstart			
		end
		//Team offsets
		if teams then
			//Blue Team
			if p.ctfteam == 2 then 
				b = $+1
				lerp_amt = f*b/blue_lerp_max
				xoffset = team_width*lerp_amt/f+xstart
			end
			//Red Team
			if p.ctfteam == 1 then
				r = $+1
				lerp_amt = f*r/red_lerp_max
				xoffset = team_width+team_centergap-xstart
					+team_width*lerp_amt/f
			end
			//This should never happen, but in case it does...
			if p.ctfteam != 1 and p.ctfteam != 2 then
			continue end
		end
		if condensed == 0
			xoffset = $-xshift1
			setoffsets(p,2)
		elseif condensed == 1
			xoffset = $-xshift2
			setoffsets(p,1)
		elseif condensed == 2
			xoffset = $-xshift3
			setoffsets(p,1)
		end		
		
		//Get some vars
		local headflags = flags
		local ouchy = 0
		local blink = 0
		//Add shake if the player is taking damage
		if P_PlayerInPain(p) then
			local choose = {-1,1}
			ouchy = choose[(leveltime&1+1)]
			headflags = V_HUDTRANSHALF|V_SNAPTOTOP//|V_PERPLAYER
		end
		//Blink frames for invuln players
		if not(P_PlayerInPain(p)) and p.powers[pw_flashing] and not(B.PreRoundWait()) then
			blink = leveltime&1
		end
		//Transparency for dead/respawning players
		if p.playerstate != PST_LIVE then
			headflags = V_HUDTRANSHALF|V_SNAPTOTOP//|V_PERPLAYER
		end
		
		//Draw debug
-- 		v.drawString(xoffset,yoffset,"P"..n,flags,"small")
		//Draw head
		if not(blink) then
			local ctrans = p.battlespflags & BSP_SHADOW and TC_RAINBOW
				or p.mo.skin
			v.drawScaled((xoffset+headx)*f, (yoffset+heady+ouchy)*f, heads, v.getSprite2Patch(p.mo.skin, SPR2_LIFE),
				headflags, v.getColormap(ctrans, p.mo.color)
			)
		end

		//Do shield
		local sh = shpatch(p.powers[pw_shield&SH_NOSTACK])
		if not(condensed == 2) and sh
			v.drawScaled((xoffset+shieldx)*f,(yoffset+shieldy+ouchy)*f,shields,
				v.cachePatch(sh),shieldf)
		end
		
		
		//Get rings
		if not(condensed == 2)
			local patch = ringpatch(p)
			v.drawScaled((xoffset+ringx)*f,(yoffset+ringy)*f,rings,
				v.cachePatch(patch),flags)
			//Text color
			if patch == "ARRINGYL" then
				text = "\x80"
			elseif patch == "ARRINGRD" then
				if p.rings then
					text = "\x82"
				else
					text = "\x85"
				end
			else
				text = "\x86"
			end
			//Text symbols
			if condensed and p.rings > 99 then
				text = $.."**"
			else
				text = $..p.rings
			end
			v.drawString(xoffset+ringx2,yoffset+ringy,text,flags,ringa)
		end
		
		//Get shield stock
		if not(condensed == 2) and CV.ShieldStock.value then
			local n = #p.shieldstock
			while n >= 1 do
				v.drawScaled((xoffset+stockx+stockn*(n-1))*f,(yoffset+stocky)*f,stocks,
					v.cachePatch(shpatch(p.shieldstock[n])),flags)
				n = $-1
			end
		end

		//Get lives/score
		if G_GametypeUsesLives() and netgame //not(gametyperules & GTR_CAMPAIGN) then
			if condensed == 0 then
				if p.lives < 6 then
					for n = 1,p.lives
						v.drawScaled((xoffset+livesx+livesn*(n-1))*f,(yoffset+livesy)*f,livess,
							v.getSprite2Patch(p.mo.skin, SPR2_LIFE),
							livesf, v.getColormap(p.mo.skin, p.skincolor))
					end
				else
					v.drawScaled((xoffset+livesx)*f,(yoffset+livesy)*f,livess,
						v.getSprite2Patch(p.mo.skin, SPR2_LIFE),
						livesf, v.getColormap(p.mo.skin, p.skincolor))
					text = p.lives
					livesy2 = $
					v.drawString(xoffset+livesx2,yoffset+livesy2,text,livesf,livesa)
				end
			else
				text = p.lives
				livesy2 = $
				v.drawString(xoffset+livesx2,yoffset+livesy2,text,livesf,livesa)
			end
		elseif gametyperules & GTR_CAMPAIGN 
			local t =
				p.ctfteam == 1 and "\x86\CPU"
				or p.bot and "\x81\Ally"
				or "\x82\P"..tostring(#p+1)
			v.drawString(xoffset+scorex,yoffset+scorey,t,flags,scorea)
		elseif (not(condensed == 2) or p.rank < 4) and p.rank then
			local t = p.rank

			if t == 1 then
				text = "\x82"..t
			elseif t == 2 then
				text = "\x8c"..t
			elseif t == 3 then
				text = "\x87"..t
			else
				text = "\x86"..t
			end
			while t > 10
				t = $-10
			end
			text = $..post[t]
			
			v.drawString(xoffset+scorex,yoffset+scorey,text,flags,scorea)
		end
	end
end