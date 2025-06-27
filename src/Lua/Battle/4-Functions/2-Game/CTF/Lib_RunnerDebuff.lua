local B = CBW_Battle
local PR = CBW_PowerCards

B.GotFlagStats = function(player)
	local skin = skins[player.mo.skin]
	local skin0 = skins[0]
	//Check PowerCard status
	if player.gotpowercard and not(player.gotpowercard.valid and player.gotpowercard.target == player.mo)
		player.gotpowercard = nil
	end
	local card = player.gotpowercard
	local skin = skins[player.mo.skin]
	//Register debuff
	if (player.gotflag or player.gotcrystal or card and PR.Item[card.item].flags&PCF_RUNNERDEBUFF)
		player.gotflagdebuff = true
		player.secondjump = 0
		player.powers[pw_tailsfly] = 0
		if player.pflags&PF_GLIDING
			player.mo.state = S_PLAY_FALL
		end
		player.pflags = $&~(PF_BOUNCING|PF_GLIDING|PF_THOKKED)
		player.climbing = 0
		if player.actionstate and not(player.actionsuper) then
			player.actionstate = 0
			local zlimit = player.jumpfactor*10
			player.mo.momz = max(min($,zlimit),-zlimit)
		end
	end
	//Unregister debuff and apply normal stats
	if not(player.gotflag or player.gotcrystal) and player.gotflagdebuff == true then
		player.gotflagdebuff = false
		player.normalspeed = skin.normalspeed
		player.acceleration = skin.acceleration
		player.runspeed = skin.runspeed
		player.mindash = skin.mindash
		player.maxdash = skin.maxdash
		player.jumpfactor = skin.jumpfactor
		player.charflags = skins[player.mo.skin].flags
	end
	//Apply debuff
	if player.gotflagdebuff
		player.normalspeed	= min(skin0.normalspeed, skin.normalspeed*4/5)
		player.acceleration	= min(skin0.acceleration, skin.acceleration*5/6)
		player.runspeed		= min(skin0.runspeed, skin.runspeed*4/5)
		player.mindash		= min(skin0.mindash, skin.mindash*3/4)
		player.maxdash		= min(skin0.maxdash, skin.maxdash*4/5)
		player.jumpfactor	= min($, FRACUNIT)
-- 		player.dashmode = 0
		player.charflags = skins[player.mo.skin].flags & ~SF_RUNONWATER
	end
end