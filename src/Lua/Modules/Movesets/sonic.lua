local module = {}

module.isThok = function(p)
	return (skins[p.skin].ability == CA_THOK)
end

module.thokThinker = function(player)
	if not (module.isThok(player) and FangsHeist.isPlayerAlive(player)) then
		/*player.blocked = false
		player.hold = false
		player.airstoptics = 0*/
		return
	end

	if player.blocked then
        player.hold = false
        player.airstoptics = 0
    end

    if (player.cmd.buttons & BT_JUMP) and player.hold and (player.pflags & PF_THOKKED) 
    and not P_IsObjectOnGround(player.mo) then
        P_InstaThrust(player.mo, player.holdangle or player.mo.angle, player.actionspd)
        player.airstoptics = 0
    end
    
    if (player.lastbuttons & BT_JUMP) and not (player.cmd.buttons & BT_JUMP) 
    and player.hold and (player.pflags & PF_THOKKED) then
        S_StartSound(player.mo, sfx_3db16)
        P_SpawnMobjFromMobj(player.mo, 0, 0, 0, MT_THOK)
        player.airstoptics = 10
        --player.mo.momx = 0
        --player.mo.momy = 0
        --player.mo.momz = 0

        player.hold = false
    end

    if player.airstoptics then
        player.mo.momx = FixedDiv($, FU + FU/5)
        player.mo.momy = FixedDiv($, FU + FU/5)
        --player.mo.momz = FixedDiv($, FU + FU/10)
        
        player.airstoptics = $ - 1
    end
end

module.doThok = function(player)
	if not (player.pflags & PF_THOKKED) then
		player.hold = true
		player.holdangle = player.mo.angle
		S_StartSound(player.mo, sfx_thok)
		P_SpawnMobjFromMobj(player.mo, 0, 0, 0, MT_THOK)
		

		player.pflags = $ | PF_THOKKED
	end
end

return module