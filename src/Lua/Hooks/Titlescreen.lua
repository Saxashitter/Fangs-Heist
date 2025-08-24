local FH = FangsHeist
local ShakeSine = function(v,scale)
	local randomkey = (v != nil) and v.RandomKey or P_RandomKey
	local randomfixed = (v != nil) and v.RandomFixed or P_RandomFixed
	local ang = randomkey(360)*ANG1
	local rng = 3*randomfixed()/2
	local xx = FixedMul(rng,FixedMul(cos(ang),scale))
	local xy = FixedMul(rng,FixedMul(sin(ang),scale))
	return xx,xy
end

local titlescreen = false
--Team Fracture Logo
local FirstLoaded = false
local Intro = {pressed = false,timer = 10}

--Title Screen
local bs_alpha = 0
local ws_alpha = 0
local logo_bounces = 1
local logo_dy = 0
local logo_y = 0
local logo_animated = true
local logo_delay = 13
local logo_shake = 0
local logo_tics = 0

addHook("ThinkFrame", do
	if not titlemapinaction then
		titlescreen = false

		bs_alpha = 0
		ws_alpha = 0
		logo_bounces = 1
		logo_dy = 0
		logo_y = 0
		logo_animated = true
		logo_delay = 13
		logo_shake = 0
		logo_tics = 0
		FirstLoaded = true
		return
	end
	titlescreen = true
end)
addHook("KeyDown",function(key)
	if titlemapinaction then
		if not FirstLoaded then
			if key.num == input.gameControlToKeyNum(GC_CONSOLE) then
				return
			end

			if (key.num == input.gameControlToKeyNum(GC_JUMP) or key.name == "enter")
			and leveltime >= 20
			and not Intro.pressed then
				S_FadeMusic(0,FixedMul(1000,tofixed("0.20")))
				Intro.pressed = true
			end

			return true --All Keys Are Disabled During Mod Warning or During Bounce
		end
	end
end)
addHook("MusicChange", function(old, new)
	if new == "_title" then
		if not FirstLoaded then
			S_StopMusic()
			return true
		end
	end
end)
local function randomizeString(str)
	if type(str) ~= "string" then return nil end

	local new_string = ""

	for i = 1, #str do
		local val = abs(getTimeMicros()) % 96 + 31
		new_string = $..string.char(min(max(val, 31), 127))
	end

	return new_string
end
local function TeamFractureBG(v)
	local patch = v.cachePatch("TFRACTURE_BG")

	local sw = (v.width() / v.dupx()) * FU
	local sh = (v.height() / v.dupy()) * FU

	local y = -patch.height*FU + (leveltime*FU/2) % (patch.height*FU)
	local x = -patch.width*FU + (leveltime*FU/2) % (patch.width*FU)

	while y < sh do
		local x = x

		while x < sw do
			v.drawScaled(x, y, FU, patch, V_SNAPTOLEFT|V_SNAPTOTOP)
			x = $+patch.width*FU
		end
	
		y = $+patch.height*FU
	end
end
FH.Version.HUD = function(v,starttime) --Version HUD
	if starttime == nil
		starttime = 35
	end
	local ver = string.format("Version: %s",FH.Version.String)
	if FH.Version.Git == true
		ver = string.format("Git Commit Version: %s",FH.Version.Git.CommitVersion)
	end
	local texts = {
		{y = 192*FU,text = ver,flags=V_SNAPTOBOTTOM|V_SNAPTOLEFT,color=SKINCOLOR_YELLOW},
	}
	for k,d in ipairs(texts) do
		local i = k-1
		local xtics = max(0,min(FixedDiv(leveltime-starttime-i*5,35),FU))
		local xslide = ease.outback(xtics,-FH.GetStringWidth(v,d.text,FU/2,"FHFNT"),2*FU,FU/2)
		local color = d.color
		if d.color == "HeistColor"
			color = (leveltime%30) >= 15 and SKINCOLOR_MAUVE or SKINCOLOR_SHAMROCK
		end
		if d and type(d) == "table"
			FH.DrawString(v,xslide,d.y,FU/2,d.text,"FHFNT",nil,d.flags|V_50TRANS,v.getColormap(TC_DEFAULT,color))
		end
	end
end
/*

4 Second Team Fracture Intro
This HUD Only Shows ONCE when the Addon is Loaded.

The Logo & the Presents graphics are made Neonie herself!

*/
FH.TeamFractureLogo = function(v,alternative)
	local FontDraw = function(v,x,y,scale,text,flags,align,color)
		return FH.DrawString(v,x,y,scale,text,"FHFNT",align,flags,v.getColormap(TC_DEFAULT,color))
	end

	TeamFractureBG(v)
	FH.Version.HUD(v,1) --Only shows Once for Version HUD too!

	--Sounds
	if leveltime == 10 then
		P_PlayJingle(nil,JT_1UP)
	end
	
	local sine = sin(FixedAngle(ease.linear(max(0,min(FixedDiv(leveltime-69,70),FU)),0,180)*FU))
	local tic = min(FixedDiv(abs(sine),FU/2),FU)
	local trans = ease.linear(tic,10,0)

	local logo = "TFRACTURE_LOGO"
	if type(alternative) == "boolean" and alternative == true then
		logo = $+"ALT" --Center Logo Design
	end

	local fracture = {timer = max(0,min(FixedDiv(leveltime-10,10),FU)),logo=v.cachePatch(logo)}
	local trans1 = ease.linear(fracture.timer,10,0)

	if leveltime >= 105 then
		trans1 = trans
	end

	FontDraw(v,320*FU,0,FU/2,"Press Jump or Enter To Skip...",V_70TRANS|V_SNAPTOTOP|V_SNAPTORIGHT,"right",SKINCOLOR_WHITE)	
	--Team Fracture

	if trans1 != 10 then
		local scale = ease.outquart(max(0,min(FixedDiv(leveltime-10,20),FU)),3*FU/2,FU)
		local x,y = 160*FU,100*FU

		v.drawScaled(x,y,scale,fracture.logo,trans1<<V_ALPHASHIFT,nil)

		local transtime = ease.linear(max(0,min(FixedDiv(leveltime-70,10),FU)),0,10)
		local sca2 = ease.outquad(max(0,min(FixedDiv(leveltime-70,15),FU)),scale,3*scale/2)

		if leveltime >= 70 and transtime != 10 then
			v.drawScaled(x,y,sca2,fracture.logo,transtime<<V_ALPHASHIFT,v.getColormap(TC_ALLWHITE))
		end
	end

	--Presents
	if trans != 10 then
		v.drawScaled(160*FU,155*FU,3*FU/2,v.cachePatch("FH_PRESENTS"),trans<<V_ALPHASHIFT)
	end

	--Fade
	local fade = ease.linear(min(FixedDiv(leveltime,10),FU),32,0)
	if leveltime >= 105 or Intro.pressed then
		if Intro.pressed then
			fade = ease.linear(FixedDiv(Intro.timer,10),32,0)
		else
			fade = ease.linear(tic,32,0)
		end
	end

	v.fadeScreen(0xFA00,fade)
end
/*

Title Screen Drawer itself.
All made by Saxashitter btw!

*/
FH.TitleScreenDrawer = function(v)
	local logo = v.cachePatch("FH_LOGO")
	local palletergb = string.format("~%03d",color.rgbToPalette(0,0,0)) 
	local black = v.cachePatch(palletergb) --please use this instead of FH_BLACK
	
	local wid = v.width()*FU/v.dupx()
	local hei = v.height()*FU/v.dupy()

	// Black and White Screen
	if ws_alpha < 10 then
		v.drawStretched(
			0, 0,
			FixedDiv(wid, black.width*FU),
			FixedDiv(hei, black.height*FU),
			black,
			V_SNAPTOLEFT|V_SNAPTOTOP|(ws_alpha*V_10TRANS),
			v.getColormap(TC_ALLWHITE, nil)
		)
	end
	if bs_alpha < 10 then
		v.drawStretched(
			0, 0,
			FixedDiv(wid, black.width*FU),
			FixedDiv(hei, black.height*FU),
			black,
			V_SNAPTOLEFT|V_SNAPTOTOP|(bs_alpha*V_10TRANS)
		)
	end

	if bs_alpha == 10 then
		ws_alpha = min($+1, 10)
	end

	// Logo
	local scale = tofixed("0.5")

	logo_shake = max(0, $-1)
	local s = FixedMul(FixedDiv(logo_shake, 12),12*FU)
	local ox,oy = ShakeSine(v,s)
	local target_y = hei/2 + logo.height*scale/2

	if logo_animated then
		if logo_delay then
			logo_delay = $-1

			if not logo_delay then
				S_StartSound(nil, sfx_s3k51)
			end
		else
			if not logo_shake then
				logo_y = $+logo_dy
				if logo_y < target_y then
					logo_dy = $ + tofixed("0.326")
				elseif logo_bounces then
					logo_bounces = $-1
					logo_dy = -$/2
					logo_y = target_y
					S_StartSound(nil, sfx_dmga3)
					logo_shake = 12
					bs_alpha = 10
				else
					logo_animated = false
					S_StartSound(nil, sfx_s3k4a)
					logo_shake = 6
				end
			end
			// are we still animated?
			if logo_animated then
				v.drawScaled(
					160*FU - logo.width*scale/2 + ox,
					logo_y - logo.height*scale + oy,
					scale,
					logo,
					V_SNAPTOTOP
				)
			end
		end
	end

	// are we not animated?
	if not logo_animated then
		if not logo_shake
			logo_tics = $+1
		end
		local time = FixedAngle(ease.linear(min(FixedDiv(logo_tics%200,200),FU),0,360)*FU)
		local y = 100*FU+FixedMul(10*scale,sin(time))
		--	Pulsing
		local tics = max(0,min(FixedDiv(logo_tics%15,15),FU))
		local colorloop = (logo_tics%30) >= 15 and SKINCOLOR_MAUVE or SKINCOLOR_GREEN
		local pulsescale = ease.outquart(tics,scale,scale+2500)
		local pulsefade = ease.linear(tics,0,10)*V_10TRANS
		v.drawScaled(
			160*FU - logo.width*pulsescale/2 + ox,
			y - logo.height*pulsescale/2 + oy,
			pulsescale,
			logo,
			V_ADD|pulsefade,v.getColormap(TC_BLINK,colorloop)
		)
		--Actual Logo
		v.drawScaled(
			160*FU - logo.width*scale/2 + ox,
			y - logo.height*scale/2 + oy,
			scale,
			logo)
	end
end
--Hud Handler
addHook("HUD", function(v)
	if not titlescreen then
		return
	end
	if not FirstLoaded then
		FH.TeamFractureLogo(v)

		if Intro.pressed then
			if not Intro.timer then
				S_ChangeMusic("_TITLE",true)
				FirstLoaded = true
			else
				Intro.timer = $-1
			end
		end

		if leveltime >= 140 then
			S_ChangeMusic("_TITLE",true)
			FirstLoaded = true
		end

		return
	end

	FH.TitleScreenDrawer(v)
end, "title")