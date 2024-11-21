local escape = {}

local ANIM_END_TICS = 2*TICRATE
local KILL_TICS = 3*TICRATE
local SPAWN_TICS = TICRATE/3

local SPAWN_X = 160*FU
local OFFSET_X = 45*FU

local GRAVITY = FU/3

local ticker = 0
local objects = {}

local text = "GO!  "

local function make_escape_object(v)
	return {
		text = text,
		x = 0,
		y = v.height()*FU/v.dupy(),
		vx = 0,
		vy = 0
	}
end

local function animate_object(v, object)
	if ticker < KILL_TICS then
		local sw = v.height()*FU/v.dupy()

		object.y = ease.linear(FU/6, $, (sw/2)-(4*FU))
		return
	end

	if ticker == KILL_TICS then
		object.vx = v.RandomRange(-4*FU, 4*FU)
		object.vy = v.RandomRange(-GRAVITY*6, -GRAVITY*12)
	end

	if object.y > v.height()*FU/v.dupy() then
		return true
	end

	object.vy = $+GRAVITY

	object.x = $+object.vx
	object.y = $+object.vy
end

local function draw_object(v, object)
	v.drawString(object.x, object.y, object.text, V_SNAPTOTOP|V_YELLOWMAP, "fixed")
	if object.vx or object.vy then
		for i = 1,3 do
			local ox = (object.vx*3/2)*i
			local oy = (object.vy*3/2)*i
			local trans = V_20TRANS*i
			v.drawString(object.x-ox, object.y-oy, object.text, V_SNAPTOTOP|V_YELLOWMAP|trans, "fixed")
		end
	end
end

function escape.init()
	ticker = 0
	objects = {}
end

function escape.draw(v)
	if not FangsHeist.Net.escape then return end

	if ticker % SPAWN_TICS == 0
	and #objects < 3 then
		objects[#objects+1] = make_escape_object(v)

		local text_width = v.stringWidth(text)*FU*3

		objects[#objects].x = SPAWN_X-(text_width/2)+((text_width/3)*(#objects-1))
	end

	local remove = {}
	for k,i in pairs(objects) do
		if not animate_object(v,i) then
			draw_object(v,i)
			continue
		end

		table.insert(remove, i)
	end

	for _,i in pairs(remove) do
		for k,v in pairs(objects) do
			if i == v then
				table.remove(objects, k)
				break
			end
		end
	end

	ticker = $+1
end

return escape