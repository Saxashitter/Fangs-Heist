local orig = FangsHeist.require "Modules/Variables/net"

function FangsHeist.isMode()
	return FangsHeist.GametypeIDs[gametype] ~= nil
end

function FangsHeist.isServer()
	return isserver or isdedicatedserver
end