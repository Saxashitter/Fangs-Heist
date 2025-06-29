local function copy(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end

	local _tbl = {}

	for k,v in pairs(tbl) do
		_tbl[k] = copy(v)
	end

	return _tbl
end

return copy