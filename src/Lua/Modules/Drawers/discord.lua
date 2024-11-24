local module = {}

function module.init() end
function module.draw(v)
	v.drawString(320, 0, "https://discord.gg/BqUHFYJSDv", V_SNAPTOTOP|V_SNAPTORIGHT|V_ALLOWLOWERCASE, "thin-right")
end

return module