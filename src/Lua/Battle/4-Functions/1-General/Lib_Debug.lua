local B = CBW_Battle
local CV = B.Console
local CP = B.ControlPoint
local I = B.Item
local A = B.Arena
local D = B.Diamond

local PR = CBW_PowerCards

B.DebugPrint = function(string,flags)
	local debug = CV.Debug.value
	//Gates
	if not(debug) then return end
	if flags and not(debug&flags) then return end
	//Colors
	local c = "\x8C"
	if flags then
		c = "\x8A"
		if flags == 1 c = "\x8E" end
		if flags == 2 c = "\x8B" end
		if flags == 4 c = "\x8D" end
		if flags == 8 c = "\x87" end
		if flags == 16 c = "\x81" end
	end
	//Print
	print(c..tostring(string))
end

B.DebugGhost = function(mo, condition)
	local ghost = P_SpawnGhostMobj(mo)
	ghost.colorized = true
	ghost.scale = $<<1
	ghost.color = condition and SKINCOLOR_GREEN or SKINCOLOR_RED
	return ghost
end

B.Warning = function(string)
	print("\x82".."WARNING:"..tostring(string))
end

//Print function
PR.DPrint = function(string,type)
	if PR.CV_Debug.value == 1
		if type == 'warning'
			string = '\x82'..'WARNING:\x81 '..$
		elseif type == 'error'
			string = '\x85'..'ERROR:\x81 '..$
		else
			string = '\x81'..$
		end
		print(string)
	end
end