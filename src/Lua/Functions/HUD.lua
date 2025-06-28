function FH:DrawParallax(v, x, y, width, height, scale, patch, flags, ox, oy)
	local width = fixdiv(width, scale)
	local height = fixdiv(height, scale)

	local offsetX = fixdiv(ox or 0, scale)
	local offsetY = fixdiv(oy or 0, scale)

	local currentX = -offsetX
	local currentY = -offsetY

	while currentY < height do
		local sh = patch.height*FU

		if currentY+sh > height then
			sh = height - currentY
		end

		while currentX < width do
			local sw = patch.width*FU

			if currentX+sw > width then
				sw = width - currentX
			end

			v.drawCropped(
				x+FixedMul(max(0, currentX), scale),
				y+FixedMul(max(0, currentY), scale),
				scale,
				scale,
				patch,
				flags,
				nil,
				-min(currentX, 0),
				-min(currentY, 0),
				sw + min(currentX, 0),
				sh + min(currentY, 0)
			)

			currentX = $+sw
		end

		currentY = $+sh
		currentX = -offsetX
	end
end