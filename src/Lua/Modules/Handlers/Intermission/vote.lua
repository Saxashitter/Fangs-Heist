local module = {}

function module.think(p) // runs when selected
end

function module.draw(v,p)
	v.drawString(160, 100-4, "WORK IN PROGRESS!", V_YELLOWMAP, "center")
	v.drawString(160, 4, "VOTE", 0, "center")
end

return module