local HT_INDEX = 0

FangsHeist.GameTypes = {}

local function GT_DEF(t)
	local gt = {}

	gt.name = t.name or "Unknown"
	gt.escape = t.escape or false
	gt.combat = t.combat or false
	gt.friendly_fire = t.friendly_fire or false
	gt.bullet_mode = t.bullet_mode or false
	gt.enemy_bullets = t.enemy_bullets or false
	gt.start_timer = t.start_timer or false

	rawset(_G, "HT_"..(t.const or "UNKNOWN"), HT_INDEX)
	FangsHeist.GameTypes[HT_INDEX] = gt
	HT_INDEX = $+1

	print("Defined Mode: "..gt.name)
end

GT_DEF{name = "Escape",
	const = "ESCAPE",
	escape = true,
	combat = true,
	friendly_fire = true,
}

GT_DEF{name = "Bullet Hell",
	const = "BULLET",
	bullet_mode = true,
	combat = true,
	start_timer = true
}