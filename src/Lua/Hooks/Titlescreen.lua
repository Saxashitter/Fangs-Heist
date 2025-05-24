local titlescreen = false

local function approach(from, to, by)
	by = abs($)

	if from > to then
		return max(from-by, to)
	end

	return min(from+by, to)
end
local ShakeSine = function(v,scale)
	local randomkey = (v != nil) and v.RandomKey or P_RandomKey
	local randomfixed = (v != nil) and v.RandomFixed or P_RandomFixed
	local ang = randomkey(360)*ANG1
	local rng = 3*randomfixed()/2
	local xx = FixedMul(rng,FixedMul(cos(ang),scale))
	local xy = FixedMul(rng,FixedMul(sin(ang),scale))
	return xx,xy
end

local bs_alpha = 0
local ws_alpha = 0

local logo_bounces = 1
local logo_dy = 0
local logo_y = 0
local logo_animated = true
local logo_delay = 13
local logo_shake = 0

freeslot("sfx_fhwrn1","sfx_fhwrn2")

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

		return
	end

	titlescreen = true
end)

local function draw_alpha_patch(v, x, y, scale, alpha, patch, flags, color)
	if alpha >= 10 then
		return
	end

	local f = flags or 0
	f = $|(alpha*V_10TRANS)

	v.drawScaled(x, y, scale, patch, f, color)
end

addHook("HUD", function(v)
	if not titlescreen then
		return
	end

	local logo = v.cachePatch("FH_LOGO")
	local black = v.cachePatch("FH_BLACK")

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
			v.getColormap(TC_BLINK, SKINCOLOR_WHITE)
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
	local scale = FU

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
					logo_dy = $ + FU/3
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
		local y = 100*FU+FixedMul(10*scale,cos(ANG1*leveltime))
		--	Pulsing
		local tics = max(0,min(FixedDiv(leveltime%15,15),FU))
		local colorloop = (leveltime%30) >= 15 and SKINCOLOR_MAUVE or SKINCOLOR_GREEN
		local pulsescale = ease.outcubic(tics,scale,scale+2500)
		local pulsefade = ease.linear(tics,0,10)
		v.drawScaled(
			160*FU - logo.width*pulsescale/2 + ox,
			y - logo.height*pulsescale/2 + oy,
			pulsescale,
			logo,
			V_ADD|(pulsefade*V_10TRANS),v.getColormap(TC_BLINK,colorloop)
		)
		--Actual Logo
		v.drawScaled(
			160*FU - logo.width*scale/2 + ox,
			y - logo.height*scale/2 + oy,
			scale,
			logo)
	end

	local version = "Demo 2 Pre-Alpha"
	local texts = {
		{y = 192,text = "https://github.com/Saxashitter/Fangs-Heist"},
		{y = 182,text = "Version: "..version}, --For SRB2MB version or GitHub Commit Version
		{y = 172,text = "By Saxashitter"},
	}
	if not menuactive
		for k,d in ipairs(texts)
			local i = k-1
			local starttime = (6*35)+17
			local tics = max(0,min(FixedDiv(leveltime-starttime-i*5,10),FU))
			local fadeWIP = ease.linear(tics,10,5)
			local xtics = max(0,min(FixedDiv(leveltime-starttime-i*5,25),FU))
			local xslide = ease.outcubic(xtics,-v.stringWidth(d.text,nil,"thin")*FU,2*FU)
			if d and type(d) == "table"
				if fadeWIP != 10
					v.drawString(xslide,d.y*FU,d.text,V_PURPLEMAP|V_SNAPTOBOTTOM|V_SNAPTOLEFT|V_ALLOWLOWERCASE|(fadeWIP*V_10TRANS),"thin-fixed")
				end
			end
		end
	end
end, "title")