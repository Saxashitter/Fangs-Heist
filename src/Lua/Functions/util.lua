function FH:CopyTable(tbl)
	if type(tbl) ~= "table" then
		return tbl
	end

	local new = {}

	for k,v in pairs(tbl) do
		new[k] = self:CopyTable(v)
	end

	return new
end