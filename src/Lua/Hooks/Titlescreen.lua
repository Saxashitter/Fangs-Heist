local titlescreen = false

local function approach(from, to, by)
	by = abs($)

	if from > to then
		return max(from-by, to)
	end

	return min(from+by, to)
end

local warning = true

local warning_sec1 = 3*TICRATE
local warning_sec1alpha = 0

local warning_sec2 = 3*TICRATE
local warning_sec2alpha = 10

local bs_alpha = 0
local ws_alpha = 0

local logo_bounces = 1
local logo_dy = 0
local logo_y = 0
local logo_animated = true
local logo_delay = 13
local logo_shake = 0

addHook("ThinkFrame", do
	if not titlemapinaction then
		titlescreen = false
		warning = true
		warning_sec1 = 3*TICRATE
		warning_sec1alpha = 0
		warning_sec2 = 3*TICRATE
		warning_sec2alpha = 10
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

	if warning then
		if warning_sec1 then
			warning_sec1 = max(0, $-1)

			if not warning_sec1 then
				
			end
		end

		if not warning_sec1
		and warning_sec2 then
			warning_sec2 = max(0, $-1)

			if not warning_sec2 then
				warning = false
			end
		end
	end
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

	local warning = v.cachePatch("FH_WARNING")
	local someassets = v.cachePatch("FH_SOMEASSETS")
	local satmf = v.cachePatch("FH_SATMF")
	local logo = v.cachePatch("FH_LOGO")
	local black = v.cachePatch("FH_BLACK")

	local wid = v.width()*FU/v.dupx()
	local hei = v.height()*FU/v.dupy()

	// Manage (low taper) fades
	if not warning_sec1 then
		warning_sec1alpha = min($+1, 10)
	end

	if warning_sec2
	and not warning_sec1
	and warning_sec1alpha == 10 then
		warning_sec2alpha = max(0, $-1)
	else
		warning_sec2alpha = min($+1, 10)
	end

	if not warning_sec1
	and not warning_sec2
	and warning_sec1alpha == 10
	and warning_sec2alpha == 10
	and bs_alpha == 10 then
		ws_alpha = min($+1, 10)
	end

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

	// Logo
	local scale = FU/2

	logo_shake = max(0, $-1)
	local s = FixedDiv(logo_shake, 12)

	local ox = v.RandomRange(-12*s, 12*s)
	local oy = v.RandomRange(-12*s, 12*s)

	if not warning_sec1
	and not warning_sec2 then
		local target_y = hei/2 + logo.height*scale/2

		if logo_animated then
			if logo_delay then
				logo_delay = $-1

				if not logo_delay then
					S_StartSound(nil, sfx_s3k51)
				end
			else
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
			v.drawScaled(
				160*FU - logo.width*scale/2 + ox,
				100*FU - logo.height*scale/2 + oy,
				scale,
				logo)
		end
	end

	// WARNING:
	local scale = FU/2
	draw_alpha_patch(v,
		wid/2 - warning.width*scale/2,
		hei/2 - warning.height*scale/2,
		scale,
		warning_sec1alpha,
		warning,
		V_SNAPTOLEFT|V_SNAPTOTOP)

	// Some assets taken from...
	local scale = FU/2
	local tolhei = someassets.height+satmf.height

	draw_alpha_patch(v,
		wid/2 - someassets.width*scale/2,
		hei/2 - tolhei*scale/2,
		scale,
		warning_sec2alpha,
		someassets,
		V_SNAPTOLEFT|V_SNAPTOTOP)

	draw_alpha_patch(v,
		wid/2 - satmf.width*scale/2,
		hei/2 - tolhei*scale/2 + someassets.height*scale,
		scale,
		warning_sec2alpha,
		satmf,
		V_SNAPTOLEFT|V_SNAPTOTOP)
end, "title")