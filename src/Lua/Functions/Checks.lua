local orig = FangsHeist.require "Modules/Variables/net"

function FangsHeist.isMode()
	if not multiplayer then
		return not titlemapinaction
	end

	return gametype == GT_FANGSHEIST
end

function FangsHeist.isServer()
	return isserver or isdedicatedserver
end