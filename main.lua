require "math_vec"

function love.load()
	cellSize = 128
	width = math.ceil(love.graphics.getWidth() / cellSize)
	height = math.ceil(love.graphics.getHeight() / cellSize)

	grid = {}
	exactGrid = {}
	for y = 1, height do
		grid[y] = {}
		exactGrid[y] = {}
		for x = 1, width do
			grid[y][x] = false
			exactGrid[y][x] = false
		end
	end

	ray = {start = {cellSize/2, cellSize/2}, dir = {cellSize, cellSize}}

	love.graphics.setBackgroundColor(255, 255, 255, 255)
end

function love.update()
	-- update ray
	local mpos = {love.mouse.getPosition()}
	ray.dir = vsub(mpos, ray.start)
	if love.mouse.isDown(1) then
		ray.start = mpos
	end

	-- clear
	for y = 1, height do
		for x = 1, width do
			exactGrid[y][x] = false
			grid[y][x] = false
		end
	end

	-- cast rays
	markers = {}
	castRay_clearer_temp_alldirs(exactGrid, cellSize, ray)

	markers = {}
	castRay_naive(grid, cellSize, ray)
	--castRay_accurate(grid, cellSize, ray)
	--castRay_clearer_temp(grid, cellSize, ray)
	--castRay_clearer_temp_alldirs(grid, cellSize, ray)
	--castRay_clearer_temp_alldirs_improved(grid, cellSize, ray)
	--castRay_DDA(grid, cellSize, ray)
end

function love.draw()
	for y = 1, height do
		for x = 1, width do
			love.graphics.setColor(220, 220, 220, 255)
			love.graphics.rectangle("line", (x-1)*cellSize, (y-1)*cellSize, cellSize, cellSize)
			love.graphics.print("(" .. tostring(x) .. ", " .. tostring(y) .. ")", (x-1)*cellSize + 2, (y-1)*cellSize + 2)

			if grid[y][x] then
				love.graphics.setColor(255, 0, 0, 50)
				love.graphics.rectangle("fill", (x-1)*cellSize, (y-1)*cellSize, cellSize, cellSize)
			end

			if exactGrid[y][x] ~= grid[y][x] then
				local padding = cellSize*0.25
				love.graphics.rectangle("fill", (x-1)*cellSize + padding, (y-1)*cellSize + padding, cellSize - padding*2, cellSize - padding*2)
			end
		end
	end

	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(ray.start[1], ray.start[2], ray.start[1] + ray.dir[1], ray.start[2] + ray.dir[2])

	for i = 1, #markers do
		love.graphics.setColor(0, 0, 0, 200)
		love.graphics.circle("line", markers[i][1], markers[i][2], 5)
		--love.graphics.setColor(0, 0, 0, 200)
		love.graphics.print(tostring(i), markers[i][1] + 5, markers[i][2] + 5)
	end

	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.print("ray start: " .. vstr(ray.start), 5, 5)
	love.graphics.print("ray end: " .. vstr(ray.dir), 5, 15)
end

function tileCoords(cellSize, p)
	return math.floor(p[1] / cellSize) + 1, math.floor(p[2] / cellSize) + 1
end

function visitGrid(grid, cellSize, point)
	local tileX, tileY = tileCoords(cellSize, point)
	table.insert(markers, point)
	-- love.graphics.clear(love.graphics.getBackgroundColor())
	-- love.draw()
	-- love.graphics.present()
	-- love.timer.sleep(1)
	grid[tileY][tileX] = true
	return tileX, tileY
end

function castRay_naive(grid, cellSize, ray)
	local cur = vret(ray.start)
	local dir = vmul(vnormed(ray.dir), cellSize * 0.9)
	if vdot(dir, dir) > 1 then
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local x, y = visitGrid(grid, cellSize, cur)
			cur = vadd(cur, dir)
		end
	end
end

function castRay_clearer_temp_alldirs(grid, cellSize, ray)
	local t = 0
	local cur = vret(ray.start)
	local dir = vret(ray.dir)

    local dirSignX = dir[1] > 0 and 0 or -1
    local dirSignY = dir[2] > 0 and 0 or -1

	if vdot(dir, dir) > 1 then
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local x, y = visitGrid(grid, cellSize, cur) -- returns tile coordinates

			local dtX = ((x + dirSignX)*cellSize - cur[1]) / dir[1] -- distances to next borders
			local dtY = ((y + dirSignY)*cellSize - cur[2]) / dir[2]

			if dtX < dtY then
				t = t + dtX + 0.001
			else
				t = t + dtY + 0.001
			end
			cur = vadd(ray.start, vmul(dir, t))
		end
	end
end

function castRay_clearer_temp(grid, cellSize, ray) -- only works for positive x and y direction, just for clarification
	local t = 0
	local cur = vret(ray.start)
	local dir = vret(ray.dir)

	if vdot(dir, dir) > 1 then
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local x, y = tileCoords(grid, cellSize, cur)
			grid[y][x] = true

			local dtX = ((x)*cellSize - cur[1]) / dir[1] -- distances to next borders
			local dtY = ((y)*cellSize - cur[2]) / dir[2]

			if dtX < dtY then
				t = t + dtX
			else
				t = t + dtY
			end
			cur = vadd(ray.start, vmul(dir, t))
		end
	end
end

function getRayCastHelperValues(cellSize, origin, dir)
	local tile = math.floor(origin / cellSize) + 1

	local step, tMax
	if dir > 0.0 then
		step = 1.0
		tMax = (cellSize*tile - origin) / dir -- maximal t (r = o + t*d) to hit next cell border
	else
		step = -1.0
		tMax = (origin - cellSize*(tile-1)) / -dir
	end
	if dir == 0 then tMax = math.huge end

	local tDelta = cellSize / dir * step -- cell width in units of t, * step to make it positive

	return tile, step, tMax, tDelta
end

function castRay_accurate(grid, cellSize, ray)
	local x, xStep, tMaxX, tDeltaX = getRayCastHelperValues(cellSize, ray.start[1], ray.dir[1])
	local y, yStep, tMaxY, tDeltaY = getRayCastHelperValues(cellSize, ray.start[2], ray.dir[2])

	while x > 0 and x <= width and y > 0 and y <= height do
		visitGrid(grid, cellSize, vadd(ray.start, vmul(ray.dir, math.min(tMaxX, tMaxY))))
		if(tMaxX < tMaxY) then
			tMaxX = tMaxX + tDeltaX
			x = x + xStep
		else
			tMaxY = tMaxY + tDeltaY
			y = y + yStep
		end
	end
end

function castRay_DDA(grid, ray)
	local origin = ray[1]
	local dir = vsub(ray[2], ray[1])

	local slope = math.abs(dir[2]/dir[1])
	local dx, dy

	if slope > 1.0 then
		dx, dy = 1/slope, 1
	else
		dx, dy = 1, slope
	end
	if dir[1] < 0 then dx = -dx end
	if dir[2] < 0 then dy = -dy end

	if dir[1] == 0 then dx = 0 end
	if dir[2] == 0 then dy = 0 end

	if dx ~= 0 or dy ~= 0 then
		local cur = vret(origin)
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local x, y = tileCoords(cur)
			grid[y][x] = true

			cur[1] = cur[1] + dx
			cur[2] = cur[2] + dy
		end
	end
end