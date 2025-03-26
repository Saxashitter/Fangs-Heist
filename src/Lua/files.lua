local function makeFile(name, content)
	local f = io.openlocal("client/FangsHeist/"..name..".txt", "r")
	local bool = false

	if not f then
		f = io.openlocal("client/FangsHeist/"..name..".txt", "w+")
		if content then
			f:write(content)
			f:flush()
		end
		bool = true
	end

	f:close()
	return bool
end

// SCORE FORMAT FOR SERVER SCORES:
// {skin, color_name, player_name, score}

FangsHeist.Save.ServerScores = {}

function FangsHeist.ServerScoresToString()
	print("FH - Turning scores to string...")
	local str = ""

	for map,data in pairs(FangsHeist.Save.ServerScores) do
		str = $.."#MAP "..map.."\n"
		for _,data in pairs(data) do
			str = $..string.format("%s::%s::%s::%s", data[1], data[2], data[3], data[4]).."\n"
		end
	end

	print("FH - Success!")
	return str
end

local function mysplit(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end

	local t = {}

	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end

	return t
end

function FangsHeist.FileToServerScores()
	// SHOULD ONLY BE CALLED ONCE.
	FangsHeist.Save.ServerScores = {}

	print("FH - Getting scores from file...")

	local scores = FangsHeist.Save.ServerScores
	local f = io.openlocal("client/FangsHeist/serverScores.txt", "r")
	local curMap = 0

	for line in f:lines() do
		if #line == 0 then continue end

		if line:sub(1, 4) == "#MAP" then
			curMap = tonumber(line:sub(6, #line))

			scores[curMap] = {}

			continue
		end

		local data = mysplit(line, "::")

		table.insert(scores[curMap], {
			data[1], data[2], data[3], tonumber(data[4])
		})
	end

	f:close()
	print("FH - Success!")
end

if not makeFile("serverScores", FangsHeist.ServerScoresToString()) then
	FangsHeist.FileToServerScores()
end

addHook("GameQuit", function()
	FangsHeist.FileToServerScores()
end)