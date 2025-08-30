local module = {}

local PROFITFORM = string.char(1) .. " %d"
local RINGSFORM = string.char(2) .. " %d"
local RANKFORM = "[c:red]R [c:white]%d"

local function GetSpriteScale(sprite, targRes, scaleBy)
	local scale = FU

	if scaleBy == true then
		-- Scale down by the sprite's height.
		scale = FixedDiv(targRes, sprite.height)
	else
		-- Scale down by the sprite's width.
		scale = FixedDiv(targRes, sprite.width)
	end

	return scale
end

local function IsSpriteValid(skin, sprite, frame)
	local skin = skins[skin]
	local sprites = skin.sprites[sprite]
	local numframes = sprites.numframes

	if numframes
	and numframes > frame then -- B = 2 so, check if it has the B frame
		return true
	end

	return false
end


local function DrawText(v, x, y, string, flags, align, color, rich)
	FangsHeist.DrawString(v,
		x*FU,
		y*FU,
		FU,
		string,
		"FHTXT",
		align,
		flags,
		color,
		rich)
end

function module.draw(v, p)
	if FangsHeist.Net.pregame then return end
	if FangsHeist.Net.game_over then return end
	if not p.heist:isAlive() then return end
	
	local team = p.heist:getTeam()
	local pi = FangsHeist.getGamemode().preferredhud

	local strings = {
		{str = RINGSFORM:format(p.rings), on = pi.Rings},
		{str = PROFITFORM:format(team.profit), on = pi.Profit},
		{str = RANKFORM:format(team.place or 0), on = pi.Rank},
	}

	local multiplier = p.heist:getMultiplier()

	if multiplier > 1 then
		strings[2].str = $ .. " [c:yellow]"..multiplier.."x"
	end

	local y = pi.pos.y

	for k,data in ipairs(strings) do
		if not data.on then
			continue
		end

		DrawText(v, pi.pos.x, y, data.str, V_SNAPTORIGHT|V_SNAPTOTOP, "right", nil, true)
		y = $ + 11
	end
end

return module