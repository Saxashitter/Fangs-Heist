local B = CBW_Battle
local CV = B.Console

B.ActionHUD=function(v, player, cam)
	if not (B.HUDMain) then return end
	if not hud.enabled("rings") then return end
	if player.playerstate != PST_LIVE then return end
	if not(CV.Actions.value) then return end
	if G_TagGametype() and (leveltime < CV_FindVar("hidetime").value*TICRATE) then return end
	local TF_GRAY = 1
	local TF_YELLOW = 2
	local TF_RED = 3
	local blink = false
	local xoffset = hudinfo[HUD_RINGS].x -- 16
	local flags = V_HUDTRANS|V_SNAPTOTOP|V_SNAPTOLEFT|V_PERPLAYER
	local align = "thin"
	
	if player.actionallowed != true and not player.gotflag then
		if P_PlayerInPain(player)
		and (player.mo.state == S_PLAY_PAIN or player.mo.state == S_PLAY_STUN)
		and not player.isjettysyn
		and (CV.Guard.value)
			local patch = v.cachePatch("PARRYBT")
			local text = "Stun Break"
			local textcolor = "\x86"
			local yoffset = hudinfo[HUD_RINGS].y+14
			if player.rings >= 20
				if leveltime % 3 == 0
					textcolor = ""
				elseif leveltime % 3 == 1
					textcolor = "\x83"
				else
					textcolor = "\x87"
				end
			end
			text = "\x82" .. 20 .. textcolor .. " " .. $
			v.draw(xoffset,yoffset,patch,flags)
			v.drawString(xoffset+10,yoffset,text,flags,align)
		end
		return
	end
	
	//Action 1 text
	local yoffset = hudinfo[HUD_RINGS].y+14 -- 42+14 = 56
	local text = player.actiontext
	local textflags = player.actiontextflags
	local gotflag = player.gotflag
	local gotcrystal = player.gotcrystal
	//Item text
	if gotflag or gotcrystal then
		if gotflag then
			text = "Got flag!"
		elseif gotcrystal then
			text = "Got crystal!"
		end
		if leveltime&4 then
			text = "\x82"+$
		end
		local patch = v.cachePatch("TOSSFLAG")
		v.draw(xoffset,yoffset,patch,flags)
		v.drawString(xoffset+12,yoffset,text,flags,align)
	return end //Don't draw anything more if we're holding an item
	if text and not(player.actioncooldown and leveltime&1) then 
		if player.actioncooldown or player.actionallowed != true then
			textflags = TF_GRAY
			text = "Cooldown "..G_TicsToSeconds(player.actioncooldown).."."..G_TicsToCentiseconds(player.actioncooldown)
		elseif textflags == nil then
			textflags = 0
			if (player.actionstate == 0 and player.actionrings > player.rings) then
				textflags = $|TF_GRAY
			end		
			if player.actionstate then
				textflags = $|TF_YELLOW
			end
		end
		if textflags == TF_GRAY then
			text = "\x86"+$
		elseif textflags == TF_YELLOW then
			text = "\x82"+$
		elseif textflags == TF_RED then
			text = "\x85"+$
		else
			text = "\x80"+$
		end
		if player.actionrings and not(player.actioncooldown) then 
			text = "\x82"+player.actionrings+"\x80 "+$
		end
		//Draw
		local patch = v.cachePatch("THRWRING")
		v.draw(xoffset,yoffset,patch,flags)
		v.drawString(xoffset+12,yoffset,text,flags,align)
	end
	//Action 2 text
	text = player.action2text
	textflags = player.action2textflags
	if not(player.gotflag) and text and not(player.actioncooldown) then 
		yoffset = $+10
		if textflags == nil then
			textflags = 0
			if (player.actionstate == 0 and player.action2rings > player.rings) then
				textflags = $|TF_GRAY
			end		
			if player.actionstate then
				textflags = $|TF_YELLOW
			end
		end
		if textflags == TF_GRAY then
			text = "\x86"+$
		elseif textflags == TF_YELLOW then
			text = "\x82"+$
		elseif textflags == TF_RED then
			text = "\x85"+$
		else
			text = "\x80"+$
		end
		if player.action2rings then 
			text = "\x82"+player.action2rings+"\x80 "+$
		end
		//Draw
		local patch = v.cachePatch("TOSSFLAG")
		v.draw(xoffset,yoffset,patch,flags)
		v.drawString(xoffset+12,yoffset,text,flags,align)
	end
	
	if not CV.Guard.value
		return
	end
	
	if not (player.mo and player.mo.valid) return end
	
	yoffset = $+10
	local patch = v.cachePatch("PARRYBT")
	local textcolor = 0
	local canguard = (player.canguard and not player.actionstate)
	local candodge = (player.canguard
		and player.mo.state != S_PLAY_PAIN
		and player.mo.state != S_PLAY_STUN
		and player.airdodge == 0
		and player.playerstate == PST_LIVE
		and not player.exiting
		and not player.actionstate
		and not player.climbing
		and not player.armachargeup
		and not player.isjettysyn
		and not player.revenge
		and not player.powers[pw_nocontrol]
		and not player.powers[pw_carry]
		and not P_IsObjectOnGround(player.mo))
	
	textcolor = "\x80"
	if P_IsObjectOnGround(player.mo)
		if not canguard return end
		text = "Guard"
	else
		if not candodge return end
		text = "Air Dodge"
	end
	text = textcolor .. " " .. $
	v.draw(xoffset,yoffset,patch,flags)
	v.drawString(xoffset+10,yoffset,text,flags,align)
end