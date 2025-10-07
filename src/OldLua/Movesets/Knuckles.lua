-- Knuckles changes for Fang's Heist
-- Script by RubyTheMii, Fang's Heist gamemode by Saxashitter (and many other lovely people!)
-- Forgive my peabrain coding
-- SAXA: dw i got you

FangsHeist.makeCharacter("knuckles", {
	pregameBackground = "FH_PREGAME_KNUCKLES",
	skins = {
		-- {name = "UglyKnux"},
	},
})

addHook("PlayerThink", function(player)
	if not (FangsHeist.isMode()
	and player.heist
	and player.heist:isAlive()
	and player.mo.skin == "knuckles") then
		if player.mo and player.mo.knuckles then
			player.mo.knuckles = nil
		end

		return
	end

	-- SAXA: put everything into the players mo lmao
	if not player.mo.knuckles then
		player.mo.knuckles = {
			knoktime = 0,
			climbtime = 175
		}
	end

	-- Climbing timer
	if player.climbing == 1
	and player.mo.knuckles.climbtime > 0 then
		player.mo.knuckles.climbtime = $ - 1
	end

	--reset it a different way so you don't get neon knuckles
	player.mo.colorized = false
	player.mo.color = player.skincolor
	if player.mo.knuckles.climbtime <= 70 then
		-- Indicator for Knuckles... getting tired? Yeah let's go with that
		if (leveltime % 4 == 0) then
			player.mo.colorized = true
			player.mo.color = skincolors[player.skincolor].invcolor
			S_StartSound(player.mo, sfx_pudpud)
		end
	end

	-- Wasted your precious climb time?
	if player.mo.knuckles.climbtime == 0
	and player.climbing == 1 then 
		player.charability = CA_NONE
		player.climbing = 0
		P_InstaThrust(player.mo, player.mo.angle, -5*player.mo.scale)
		P_SetObjectMomZ(player.mo, 5*player.mo.scale, false)
		player.mo.state = S_PLAY_PAIN
		S_StartSound(player.mo, sfx_s3k51)
	end

	-- Land on the ground to recover
	if player.mo.eflags & MFE_JUSTHITFLOOR
	or P_IsObjectOnGround(player.mo) then
		player.mo.knuckles.climbtime = 175
		player.charability = CA_GLIDEANDCLIMB
	end
end)

local function resetPlayer(p)
	if not (p.mo and p.mo.knuckles) then return end

	p.climbing = 0
	p.mo.knuckles.climbtime = 175
end

FangsHeist.addHook("PlayerAirDodge", resetPlayer)