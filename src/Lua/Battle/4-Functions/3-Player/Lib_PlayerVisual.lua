local B = CBW_Battle

local fx = {}
fx[SH_PITY] = {
	blend = AST_TRANSLUCENT,
	render = RF_FULLDARK|RF_NOCOLORMAPS,
	color = SKINCOLOR_BLACK
}
fx[SH_WHIRLWIND] = {
	blend = AST_SUBTRACTIVE,
	render = RF_NOCOLORMAPS,
	color = SKINCOLOR_SILVER
}
fx[SH_ARMAGEDDON] = {
	blend = AST_TRANSLUCENT,
	render = RF_NOCOLORMAPS,
	color = SKINCOLOR_CRIMSON
}
fx[SH_PINK] = {
	blend = AST_TRANSLUCENT,
	render = RF_NOCOLORMAPS,
	color = SKINCOLOR_ROSY
}
fx[SH_ELEMENTAL] = {
	blend = AST_SUBTRACT,
	render = RF_FULLBRIGHT|RF_NOCOLORMAPS,
	color = SKINCOLOR_COBALT
}
fx[SH_ATTRACT] = {
	blend = AST_SUBTRACT,
	render = RF_FULLBRIGHT|RF_NOCOLORMAPS,
	color = SKINCOLOR_GOLD
}
fx[SH_FLAMEAURA] = {
	blend = AST_ADD,
	render = RF_FULLBRIGHT|RF_NOCOLORMAPS,
	color = SKINCOLOR_FLAME
}
fx[SH_BUBBLEWRAP] = {
	blend = AST_ADD,
	render = RF_FULLBRIGHT|RF_NOCOLORMAPS,
	color = SKINCOLOR_BLUE
}
fx[SH_THUNDERCOIN] = {
	blend = AST_ADD,
	render = RF_FULLBRIGHT|RF_NOCOLORMAPS,
	color = SKINCOLOR_YELLOW
}
fx[SH_FORCE|1] = {
	blend = AST_SUBTRACTIVE,
	render = RF_NOCOLORMAPS,
	color = SKINCOLOR_PURPLE
}
B.ShadowCharacterFX = fx

B.GetShadowCharacterFX = function(shield, alert)
	if alert
		return assert(shield and fx[shield], "Attempted to get undefined Shadow Character FX for shield argument "..tostring(shield)..".")
	end
	return fx[shield] or fx[SH_PITY]
end

B.DrawShadowCharacter = function(player)
	local shield = player.battlespshield
	local sh = fx[shield] or fx[SH_PITY]
	local blend, render, color =
		sh.blend or AST_TRANSLUCENT,
		sh.render or 0,
		sh.color or player.skincolor
-- 			blend = AST_SUBTRACT
-- 			render = RF_FULLBRIGHT
-- 			color = SKINCOLOR_BLUE
	if player.mo and not(player.mo.colorized)
		player.skincolor = color
		player.mo.color = color
		player.mo.colorized = true
		player.mo.blendmode = blend
		player.mo.renderflags = $|render
		if player.followmobj and player.followmobj.valid
			player.followmobj.color = color
			player.followmobj.colorized = true
			player.followmobj.blendmode = blend
			player.followmobj.renderflags = $|render
		end
	end
-- 			if not(leveltime % 8)
-- 				local ghost = P_SpawnGhostMobj(player.mo)
-- 				ghost.color = color
-- 				ghost.colorized = true
-- 				ghost.blendmode = blend2
-- 				ghost.renderflags = $|render
-- 			end
end