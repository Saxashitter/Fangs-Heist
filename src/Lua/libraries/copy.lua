function FH:DeepCopy(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end

	local _tbl = {}

	for k,v in pairs(tbl) do
		_tbl[k] = self:DeepCopy(v)
	end

	return _tbl
end