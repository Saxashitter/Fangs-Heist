local state = {}

local INFO_X = 4
local INFO_INDENT = 6

state.ready = true

state.time_x = 0
state.time_y = FU

state.time_ox = 4*FU
state.time_oy = (0 - 12 - 4)*FU

local function DrawRoundInfo(v, y, flags)
	local gamemode = FangsHeist.getGamemode()
	local info = gamemode:info()

	if not (info and #info) then return end

	for _, tbl in ipairs(info) do
		for i, info in ipairs(tbl) do
			local x = INFO_X
			local f = flags|V_REDMAP

			if i > 1 then
				x = $ + INFO_INDENT
				f = ($|V_ALLOWLOWERCASE) & ~V_REDMAP
				info = "- "..$
			end
	
			v.drawString(x, y, info, f, "thin")
			y = $+10
		end
	end
end

function state:enter(last)
	self.heist.lastPregame = last
end

function state:exit()
	self.heist.lastPregame = nil
end

function state:tick()
	if self.heist.buttons & BT_SPIN
	and not (self.heist.lastbuttons & BT_SPIN) then
		S_StartSound(nil, sfx_alart, self)
		return self.heist.lastPregame
	end
end

function state:draw(v, c, transparency)
	--DrawRoundInfo(v, 4, V_SNAPTOTOP|V_SNAPTOLEFT|transparency)
	v.drawString(160, 200 - 12, "Waiting for players...", V_ALLOWLOWERCASE|V_SNAPTOBOTTOM|transparency, "thin-center")

	local team = self.heist:getTeam()

	v.drawString(160, 8, "Team:", V_SNAPTOTOP|transparency, "thin-center")
	local y = 8+10
	for i, p in ipairs(team) do
		if not (p and p.valid) then continue end

		local color = skincolors[max(0,p.skincolor)].chatcolor
		v.drawString(160, y, p.name, V_SNAPTOTOP|color|transparency, "thin-center")
		y = $+10
	end
end

return state