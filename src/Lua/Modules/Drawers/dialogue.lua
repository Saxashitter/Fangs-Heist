local dialogue = FangsHeist.require "Modules/Handlers/dialogue"

local module = {}

function module.init() end
function module.draw(hook, v)
	dialogue.drawhud(v)
end

return module,"gameandscores"