local module = {}

local sglib = FangsHeist.require "Modules/Libraries/sglib"
local fracformat = FangsHeist.require "Modules/Libraries/fracformat"

local SIGHT_RANGE = (4096*FU)*4
local SIGHT_TRANSSTART = 1024*FU*3
local TRACK_RANGE = 1024*FU

local tracked = {}

function FangsHeist.PlayerPreset() end
function FangsHeist.SignPreset() end

function FangsHeist.trackObject(mo, args, func)
	table.insert(tracked, {
		mo = mo,
		args = args,
		func = func
	})
end

addHook("PreThinkFrame", do
	tracked = {}
end)

function module.draw(v, p, c)
	if not (p.mo and p.mo.valid) then return end

	for k,t in ipairs(tracked) do
		if not (t.mo and t.mo.valid) then
			continue
		end

		local y = 0
		local track = sglib.ObjectTracking(v,p,c, t.mo)

		if not track.onScreen
		or P_CheckSight(p.mo, t.mo) then
			continue
		end

		local dist = R_PointToDist2(t.mo.x, t.mo.y, p.mo.x, p.mo.y)
		local fd = FixedDiv -- oh boy...
		local trans = 0

		--[[local trans = max(
			ease.linear(
				fd(max(0, min(dist-OFFSET_RANGE, SIGHT_RANGE)), SIGHT_RANGE),
				0,
				10
			),
			ease.linear(
				fd(max(0, min(dist, TRACK_RANGE)), TRACK_RANGE),
				10,
				0
			)
		)*V_10TRANS]]

		if dist <= TRACK_RANGE then
			trans = ease.linear(
				fd(max(0, min(dist, TRACK_RANGE)), TRACK_RANGE),
				10,
				0
			)
		elseif dist >= SIGHT_TRANSSTART then
			trans = ease.linear(
				min(fd(dist-SIGHT_TRANSSTART, SIGHT_RANGE-SIGHT_TRANSSTART), FU),
				0,
				10
			)
		end
		trans = V_10TRANS*trans

		if trans == V_10TRANS*10 then continue end -- 100 transparency

		t:func(v, p, c, track, trans)

		local arrow = v.cachePatch("FH_ARROW"..(leveltime/2 % 6))
		local arrow_scale = FU/2
		local color

		if t.args.color then
			color = v.getColormap(nil, t.args.color)
		end

		track.y = $ - arrow.height*arrow_scale
		v.drawScaled(track.x - arrow.width*arrow_scale/2, track.y, arrow_scale, arrow, trans, color)

		track.y = $ - 8*FU
		v.drawString(track.x, track.y, fracformat(dist), V_ALLOWLOWERCASE|trans, "thin-fixed-center")

		if not t.args then continue end

		for k = 1, #t.args do
			local i = t.args[k]
	
			track.y = $ - 8*FU
			v.drawString(track.x, track.y, i, V_ALLOWLOWERCASE|trans, "thin-fixed-center")
		end
	end
end

return module