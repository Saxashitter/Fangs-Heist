local B = CBW_Battle

B.Choose = function(...)
	local args = {...}
	local choice = P_RandomRange(1,#args)
	return args[choice]
end

B.Shuffle = function(t)
	-- Shuffles instances of a table into a newly ordered table. Returns the new table.
	local copy = {}
	for n,i in pairs(t) do
		copy[n] = i
	end
	local sh = {}
	while #copy do
		local r = P_RandomRange(1, #copy)
		table.insert(sh, copy[r])
		table.remove(copy, r)
	end		
	return sh
end