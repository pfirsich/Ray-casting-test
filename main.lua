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
	castRay_clearer_alldirs(exactGrid, cellSize, ray)

	markers = {}
	--castRay_naive(grid, cellSize, ray)
	--castRay_accurate(grid, cellSize, ray)
	--castRay_clearer_positive(grid, cellSize, ray)
	--castRay_clearer_alldirs(grid, cellSize, ray)
	castRay_clearer_alldirs_improved(grid, cellSize, ray)
	--castRay_DDA(grid, cellSize, ray)
	--castRay_Bresenham(grid, cellSize, ray)
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

			if love.keyboard.isDown("d") then -- diamonds
				love.graphics.line( (x-0.5    )*cellSize, (y-0.5+0.5)*cellSize,
									(x-0.5+0.5)*cellSize, (y-0.5    )*cellSize,
									(x-0.5    )*cellSize, (y-0.5-0.5)*cellSize,
									(x-0.5-0.5)*cellSize, (y-0.5    )*cellSize,
									(x-0.5    )*cellSize, (y-0.5+0.5)*cellSize)
			end
		end
	end

	love.graphics.setLineWidth(2)
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(ray.start[1], ray.start[2], ray.start[1] + ray.dir[1], ray.start[2] + ray.dir[2])
	love.graphics.setLineWidth(1)

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

function tileCoords(cellSize, x, y)
	if y == nil then x, y = x[1], x[2] end
	return math.floor(x / cellSize) + 1, math.floor(y / cellSize) + 1
end

function mark(x, y)
	if y == nil then x, y = unpack(x) end
	table.insert(markers, {x, y})
end

function castRay_naive(grid, cellSize, ray)
	local cur = vret(ray.start)
	local stepSize = cellSize * 0.9
	local dir = vmul(vnormed(ray.dir), stepSize)
	if vdot(dir, dir) > 1 then
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local tileX, tileY = tileCoords(cellSize, cur)
			grid[tileY][tileX] = true
			mark(cur)
			cur = vadd(cur, dir)
		end
	end
end

function castRay_clearer_alldirs_improved(grid, cellSize, ray)
    local dirSignX = ray.dir[1] > 0 and 1 or -1
    local dirSignY = ray.dir[2] > 0 and 1 or -1
    -- -1 to compensate for 1-indexed tile coordinates
    local tileOffsetX = (ray.dir[1] > 0 and 1 or 0) - 1
    local tileOffsetY = (ray.dir[2] > 0 and 1 or 0) - 1

	local curX, curY = ray.start[1], ray.start[2]
    local tileX, tileY = tileCoords(cellSize, curX, curY)
	local t = 0

	if vdot(ray.dir, ray.dir) > 0 then -- start and end should not be at the same point
		while tileX > 0 and tileX <= width and tileY > 0 and tileY <= height do
			grid[tileY][tileX] = true
			mark(curX, curY)

			local dtX = ((tileX + tileOffsetX)*cellSize - curX) / ray.dir[1] -- distances to next borders
			local dtY = ((tileY + tileOffsetY)*cellSize - curY) / ray.dir[2]

			if dtX < dtY then
				t = t + dtX
				tileX = tileX + dirSignX
			else
				t = t + dtY
				tileY = tileY + dirSignY
			end

			curX = ray.start[1] + ray.dir[1] * t
			curY = ray.start[2] + ray.dir[2] * t
		end
	else
		grid[tileY][tileX] = true
	end
end

function castRay_clearer_alldirs(grid, cellSize, ray)
	local t = 0
	local cur = vret(ray.start)
	local dir = vret(ray.dir)

    local dirSignX = dir[1] > 0 and 0 or -1
    local dirSignY = dir[2] > 0 and 0 or -1

	if vdot(dir, dir) > 1 then
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local tileX, tileY = tileCoords(cellSize, cur)
			grid[tileY][tileX] = true
			mark(cur)

			local dtX = ((tileX + dirSignX)*cellSize - cur[1]) / dir[1] -- distances to next borders
			local dtY = ((tileY + dirSignY)*cellSize - cur[2]) / dir[2]

			if dtX < dtY then
				t = t + dtX + 0.001
			else
				t = t + dtY + 0.001
			end
			cur = vadd(ray.start, vmul(dir, t))
		end
	end
end

function castRay_clearer_positive(grid, cellSize, ray) -- only works for positive x and y direction, just for clarification
	local t = 0
	local cur = vret(ray.start)
	local dir = vret(ray.dir)

	if vdot(dir, dir) > 1 then
		while cur[1] > 0 and cur[1] < width*cellSize and cur[2] > 0 and cur[2] < height*cellSize do
			local tileX, tileY = tileCoords(cellSize, cur)
			grid[tileY][tileX] = true
			mark(cur)

			local dtX = ((tileX)*cellSize - cur[1]) / dir[1] -- distances to next borders
			local dtY = ((tileY)*cellSize - cur[2]) / dir[2]

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
		grid[y][x] = true
		mark(vadd(ray.start, vmul(ray.dir, math.min(tMaxX, tMaxY))))

		if(tMaxX < tMaxY) then
			tMaxX = tMaxX + tDeltaX
			x = x + xStep
		else
			tMaxY = tMaxY + tDeltaY
			y = y + yStep
		end
	end
end

function castRay_DDA(grid, cellSize, ray)
	local startX, startY = tileCoords(cellSize, ray.start)
	local endX, endY = tileCoords(cellSize, vadd(ray.start, ray.dir))
	local relX, relY = endX - startX, endY - startY

	local steps = math.max(math.abs(relX), math.abs(relY))

	local dx, dy = relX / steps, relY / steps

	if dx ~= 0 or dy ~= 0 then
		local curX, curY = startX, startY
		while curX > 0 and curX <= width and curY > 0 and curY <= height do
			-- I don't know why I need this, and I feel ashamed of myself because of it
			grid[math.floor(curY+0.5)][math.floor(curX+0.5)] = true
			curX, curY = curX + dx, curY + dy
		end
	end
end

-- https://de.wikipedia.org/wiki/Bresenham-Algorithmus#Kompakte_Variante
function castRay_Bresenham(grid, cellSize, ray)
	local startX, startY = tileCoords(cellSize, ray.start)
	local endX, endY = tileCoords(cellSize, vadd(ray.start, ray.dir))

	local dx = math.abs(endX - startX)
	local dy = math.abs(endY - startY)
	local incX = endX > startX and 1 or -1
	local incY = endY > startY and 1 or -1

	local err, e2 = dx-dy, nil

	if dx == 0 and dy == 0 then
		grid[startY][startX] = true
		return
	end

	while startX > 0 and startX <= width and startY > 0 and startY <= height do
		grid[startY][startX] = true

		e2 = 2*err
		if e2 > -dy then
		  err = err - dy
		  startX  = startX + incX
		end
		if e2 < dx then
		  err = err + dx
		  startY  = startY + incY
		end
	end
end
