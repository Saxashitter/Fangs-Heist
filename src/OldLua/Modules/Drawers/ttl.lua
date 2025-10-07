local module = {}

local leftSide = {}
local rightSide = {}
local tics = 0
local enabled = false

local duration = 5*TICRATE
local textSlideTics = TICRATE

local topString = "2 teams left..."
local bottomString = "1 to take it all home!"

function FangsHeist.doTTLHUD()
	enabled = true
	tics = 0
end

function module.init()
	enabled = false
	tics = 0
	leftSide = {}
	rightSide = {}
end

function module.draw(v)
	if not enabled then return end
	if tics == duration then return end

	tics = $+1

	local textT = min(FixedDiv(tics, textSlideTics), FU)

	if textT == FU
	and ((tics/3) % 2) == 1 then
		return
	end

	local bottomStringWidth = FangsHeist.GetStringWidth(v, bottomString, FU, "FHTXT")
	local topStringWidth = FangsHeist.GetStringWidth(v, topString, FU, "FHTXT")

	local screenWidth = v.width() * FU / v.dupx()
	local screenHeight = v.height() * FU / v.dupy()

	local topX = ease.linear(textT, -topStringWidth/2, screenWidth/2)
	local bottomX = ease.linear(textT, screenWidth + bottomStringWidth/2, screenWidth/2)

	FangsHeist.DrawString(v, topX, 8*FU, FU, topString, "FHTXT", "center", V_SNAPTOLEFT, v.getStringColormap(V_REDMAP))
	FangsHeist.DrawString(v, bottomX, 8*FU + 10*FU, FU, bottomString, "FHTXT", "center", V_SNAPTOLEFT, v.getStringColormap(V_REDMAP))
end

return module