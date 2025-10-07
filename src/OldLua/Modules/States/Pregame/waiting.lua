local state = {}

state.ready = true

state.time_x = 0
state.time_y = FU

state.time_ox = 4*FU
state.time_oy = (0 - 12 - 4)*FU

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

/*
Just only This now..
no more lots of HUD Drawing
-RedFoxyBoy
*/
function state:draw(v, c, transparency)
	local FH = FangsHeist
	local y = 10*FU
	-- DUO AND TRIO GAMEMODES ARE SUPPORTED!
	if FH.getGamemode().teamlimit >= 2
		local team = self.heist:getTeam()
		FH.DrawString(v,160*FU, y,FU, "Team:","FHTXT","center", V_SNAPTOTOP|transparency)
		y = $+10*FU
		for i, p in ipairs(team) do
			if not (p and p.valid) then continue end

			FH.DrawString(v,160*FU,y,FU, p.name,"FHTXT","center", V_SNAPTOTOP|transparency, v.getStringColormap(skincolors[p.skincolor].chatcolor))
			
			y = $+10*FU
		end
	end
	FH.drawREADY(v,165,FU,v.cachePatch("FH_READYSELECT"),transparency,true)
	FH.DrawString(v,160*FU, 187*FU,FU, "Wating for Players...","FHTXT","center", V_SNAPTOBOTTOM|transparency, v.getStringColormap(V_YELLOWMAP))
end

return state