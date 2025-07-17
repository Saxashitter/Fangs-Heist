-- Knuckles changes for Fang's Heist
-- Script by RubyTheMii, Fang's Heist gamemode by Saxashitter (and many other lovely people!)
-- Forgive my peabrain coding
-- SAXA: dw i got you

-- Initiate the Knok (why is it called the Knok? 'cause you can Knok some people out with it)
addHook("AbilitySpecial", function(player)
	if not (FangsHeist.isMode()
	and player.heist
	and player.heist:isAlive()
	and player.mo.skin == "knuckles"
	and player.pflags & PF_THOKKED == 0
	and player.mo.knuckles) then
		return
	end

	P_InstaThrust(player.mo, player.mo.angle, 30*player.mo.scale)
	P_SpawnThokMobj(player)
	S_StartSound(player.mo, sfx_thok)
	player.pflags = $|(PF_GLIDING|PF_THOKKED) -- wasnt this the intended one? -pac
end)
		
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
	
	-- Knok stuff - pretty simple, really
	if player.pflags & PF_THOKKED
	and not (player.pflags & PF_SHIELDABILITY) -- we don't want shield abilities triggering it -pac
	and player.mo.knuckles.knoktime <= 35 then
		player.mo.state = S_PLAY_GLIDE
		P_InstaThrust(player.mo, player.mo.angle, 30*player.mo.scale)
		player.mo.momz = 0
		player.drawangle = player.mo.angle
		player.mo.knuckles.knoktime = $ + 1

		if player.pflags & PF_JUMPDOWN == 0 then 
			player.mo.state = S_PLAY_JUMP
			player.mo.knuckles.knoktime = 36
			player.pflags = $ & ~(PF_GLIDING|PF_THOKKED)
		end
	elseif player.pflags & PF_THOKKED
	and not (player.pflags & PF_SHIELDABILITY) -- we don't want shield abilities triggering it -pac
	and player.mo.knuckles.knoktime > 35 then
		player.mo.state = S_PLAY_JUMP
		player.pflags = $ & ~(PF_GLIDING|PF_THOKKED)
	end

	-- Climbing timer
	if player.climbing == 1
	and player.mo.knuckles.climbtime > 0 then
		player.mo.knuckles.knoktime = 0
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
		player.mo.knuckles.knoktime = 0
		player.mo.knuckles.climbtime = 175
		player.charability = CA_GLIDEANDCLIMB
	end
end)