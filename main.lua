function love.load()
	grid = {}
	grid.cellSize = 128
	grid.width = math.ceil(love.graphics.getWidth() / grid.cellSize)
	grid.height = math.ceil(love.graphics.getHeight() / grid.cellSize)

	exactGrid = {}
	exactGrid.cellSize, exactGrid.width, exactGrid.height = grid.cellSize, grid.width, grid.height

	for y = 1, grid.height do
		grid[y] = {}
		exactGrid[y] = {}
		for x = 1, grid.width do
			grid[y][x] = false
			exactGrid[y][x] = false
		end
	end

	ray = {startX = grid.cellSize/2, startY = grid.cellSize/2,
		   dirX = grid.cellSize, dirY = grid.cellSize}

	love.graphics.setBackgroundColor(255, 255, 255, 255)
end

function love.update()
	-- update ray
	local mouseX, mouseY = love.mouse.getPosition()
	ray.dirX, ray.dirY = mouseX - ray.startX, mouseY - ray.startY
	if love.mouse.isDown(1) then
		ray.startX, ray.startY = mouseX, mouseY
	end

	-- clear
	for y = 1, grid.height do
		for x = 1, grid.width do
			exactGrid[y][x] = false
			grid[y][x] = false
		end
	end

	-- cast rays
	markers = {}
	castRay_clearer_alldirs_improved_transformed(exactGrid, ray)

	markers = {}
	castRay_naive(grid, ray)
	--castRay_accurate(grid, ray)
	--castRay_clearer_positive(grid, ray)
	--castRay_clearer_alldirs(grid, ray)
	--castRay_clearer_alldirs_improved(grid, ray)
	--castRay_clearer_alldirs_improved_transformed(grid, ray)
	--castRay_DDA(grid, ray)
	--castRay_Bresenham(grid, ray)
end

function love.draw()
	local cSize = grid.cellSize
	for y = 1, grid.height do
		for x = 1, grid.width do
			love.graphics.setColor(220, 220, 220, 255)
			love.graphics.rectangle("line", (x-1)*cSize, (y-1)*cSize, cSize, cSize)
			love.graphics.print("(" .. tostring(x) .. ", " .. tostring(y) .. ")", (x-1)*cSize + 2, (y-1)*cSize + 2)

			if grid[y][x] then
				love.graphics.setColor(255, 0, 0, 50)
				love.graphics.rectangle("fill", (x-1)*cSize, (y-1)*cSize, cSize, cSize)
			end

			if exactGrid[y][x] ~= grid[y][x] then
				local padding = cSize*0.25
				love.graphics.rectangle("fill", (x-1)*cSize + padding, (y-1)*cSize + padding, cSize - padding*2, cSize - padding*2)
			end

			if love.keyboard.isDown("d") then -- diamonds
				love.graphics.line( (x-0.5    )*cSize, (y-0.5+0.5)*cSize,
									(x-0.5+0.5)*cSize, (y-0.5    )*cSize,
									(x-0.5    )*cSize, (y-0.5-0.5)*cSize,
									(x-0.5-0.5)*cSize, (y-0.5    )*cSize,
									(x-0.5    )*cSize, (y-0.5+0.5)*cSize)
			end
		end
	end

	love.graphics.setLineWidth(2)
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(ray.startX, ray.startY, ray.startX + ray.dirX, ray.startY + ray.dirY)
	love.graphics.setLineWidth(1)

	for i = 1, #markers do
		love.graphics.setColor(0, 0, 0, 200)
		love.graphics.circle("line", markers[i][1], markers[i][2], 5)
		--love.graphics.setColor(0, 0, 0, 200)
		love.graphics.print(tostring(i), markers[i][1] + 5, markers[i][2] + 5)
	end

	love.graphics.setColor(0, 0, 0, 255)
	love.graphics.print("ray start: " .. tostring(ray.startX) .. ", " .. tostring(ray.startY), 5, 5)
	love.graphics.print("ray dir: " .. tostring(ray.dirX) .. ", " .. tostring(ray.dirY), 5, 15)
end

function tileCoords(cellSize, x, y)
	return math.floor(x / cellSize) + 1, math.floor(y / cellSize) + 1
end

function mark(x, y)
	table.insert(markers, {x, y})
end

function castRay_naive(grid, ray)
	local curX, curY = ray.startX, ray.startY
	local stepSize = grid.cellSize * 0.9
	local dirLen = math.sqrt(ray.dirX*ray.dirX + ray.dirY*ray.dirY)
	local deltaX, deltaY = ray.dirX / dirLen * stepSize, ray.dirY / dirLen * stepSize
	if dirLen > 0 then
		while curX > 0 and curX < grid.width*grid.cellSize and curY > 0 and curY < grid.height*grid.cellSize do
			local tileX, tileY = tileCoords(grid.cellSize, curX, curY)
			grid[tileY][tileX] = true
			mark(curX, curY)
			curX, curY = curX + deltaX, curY + deltaY
		end
	end
end

function getHelpers(cellSize, pos, dir)
	local tile = math.floor(pos / cellSize) + 1

	local dTile, dt
	if dir > 0 then
		dTile = 1
		dt = ((tile+0)*cellSize - pos) / dir
	elseif dir == 0 then
        	dTile = 0
		dt = ((tile+0)*cellSize - pos) / dir
	else
		dTile = -1
		dt = ((tile-1)*cellSize - pos) / dir
	end

	return tile, dTile, dt, dTile * cellSize / dir
end

function castRay_clearer_alldirs_improved_transformed(grid, ray)
	local tileX, dtileX, dtX, ddtX = getHelpers(grid.cellSize, ray.startX, ray.dirX)
	local tileY, dtileY, dtY, ddtY = getHelpers(grid.cellSize, ray.startY, ray.dirY)
	local t = 0

	if ray.dirX*ray.dirX + ray.dirY*ray.dirY > 0 then -- start and end should not be at the same point
		while tileX > 0 and tileX <= grid.width and tileY > 0 and tileY <= grid.height do
			grid[tileY][tileX] = true
			mark(ray.startX + ray.dirX * t, ray.startY + ray.dirY * t)

			if dtX < dtY then
				tileX = tileX + dtileX
				local dt = dtX
				t = t + dt
				dtX = dtX + ddtX - dt
				dtY = dtY - dt
			else
				tileY = tileY + dtileY
				local dt = dtY
				t = t + dt
				dtX = dtX - dt
				dtY = dtY + ddtY - dt
			end
		end
	else
		grid[tileY][tileX] = true
	end
end

function castRay_clearer_alldirs_improved(grid, ray)
	local dirSignX = ray.dirX > 0 and 1 or -1
	local dirSignY = ray.dirY > 0 and 1 or -1
	-- -1 to compensate for 1-indexed tile coordinates
	local tileOffsetX = (ray.dirX > 0 and 1 or 0) - 1
	local tileOffsetY = (ray.dirY > 0 and 1 or 0) - 1

	local curX, curY = ray.startX, ray.startY
	local tileX, tileY = tileCoords(grid.cellSize, curX, curY)
	local t = 0

	if ray.dirX*ray.dirX + ray.dirY*ray.dirY > 0 then -- start and end should not be at the same point
		while tileX > 0 and tileX <= grid.width and tileY > 0 and tileY <= grid.height do
			grid[tileY][tileX] = true
			mark(curX, curY)

			local dtX = ((tileX + tileOffsetX)*grid.cellSize - curX) / ray.dirX -- distances to next borders
			local dtY = ((tileY + tileOffsetY)*grid.cellSize - curY) / ray.dirY

			if dtX < dtY then
				t = t + dtX
				tileX = tileX + dirSignX
			else
				t = t + dtY
				tileY = tileY + dirSignY
			end

			curX = ray.startX + ray.dirX * t
			curY = ray.startY + ray.dirY * t
		end
	else
		grid[tileY][tileX] = true
	end
end

function castRay_clearer_alldirs(grid, ray)
	local t = 0
	local curX, curY = ray.startX, ray.startY

    local dirSignX = ray.dirX > 0 and 0 or -1
    local dirSignY = ray.dirY > 0 and 0 or -1

	if ray.dirX*ray.dirX + ray.dirY*ray.dirY > 0 then
		while curX > 0 and curX < grid.width*grid.cellSize and curY > 0 and curY < grid.height*grid.cellSize do
			local tileX, tileY = tileCoords(grid.cellSize, curX, curY)
			grid[tileY][tileX] = true
			mark(curX, curY)

			local dtX = ((tileX + dirSignX)*grid.cellSize - curX) / ray.dirX -- distances to next borders
			local dtY = ((tileY + dirSignY)*grid.cellSize - curY) / ray.dirY

			if dtX < dtY then
				t = t + dtX + 0.001
			else
				t = t + dtY + 0.001
			end

			curX = ray.startX + ray.dirX * t
			curY = ray.startY + ray.dirY * t
		end
	end
end

function castRay_clearer_positive(grid, ray) -- only works for positive x and y direction, just for clarification
	local t = 0
	local curX, curY = ray.startX, ray.startY

	if ray.dirX*ray.dirX + ray.dirY*ray.dirY > 0 then
		while curX > 0 and curX < grid.width*grid.cellSize and curY > 0 and curY < grid.height*grid.cellSize do
			local tileX, tileY = tileCoords(grid.cellSize, curX, curY)
			grid[tileY][tileX] = true
			mark(curX, curY)

			local dtX = ((tileX)*grid.cellSize - curX) / ray.dirX -- distances to next borders
			local dtY = ((tileY)*grid.cellSize - curY) / ray.dirY

			if dtX < dtY then
				t = t + dtX
			else
				t = t + dtY
			end

			curX = ray.startX + ray.dirX * t
			curY = ray.startY + ray.dirY * t
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

function castRay_accurate(grid, ray)
	local x, xStep, tMaxX, tDeltaX = getRayCastHelperValues(grid.cellSize, ray.startX, ray.dirX)
	local y, yStep, tMaxY, tDeltaY = getRayCastHelperValues(grid.cellSize, ray.startY, ray.dirY)

	while x > 0 and x <= grid.width and y > 0 and y <= grid.height do
		grid[y][x] = true
		local t = math.min(tMaxX, tMaxY) -- ?? lucky guess? this should not work
		mark(ray.startX + ray.dirX * t, ray.startY + ray.dirY * t)

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
	local startX, startY = tileCoords(grid.cellSize, ray.startX, ray.startY)
	local endX, endY = tileCoords(grid.cellSize, ray.startX + ray.dirX, ray.startY + ray.dirY)
	local relX, relY = endX - startX, endY - startY

	local steps = math.max(math.abs(relX), math.abs(relY))

	local dx, dy = relX / steps, relY / steps

	if dx ~= 0 or dy ~= 0 then
		local curX, curY = startX, startY
		while curX > 0 and curX <= grid.width and curY > 0 and curY <= grid.height do
			-- I don't know why I need this, and I feel ashamed of myself because of it
			grid[math.floor(curY+0.5)][math.floor(curX+0.5)] = true
			curX, curY = curX + dx, curY + dy
		end
	end
end

-- https://de.wikipedia.org/wiki/Bresenham-Algorithmus#Kompakte_Variante
function castRay_Bresenham(grid, ray)
	local startX, startY = tileCoords(grid.cellSize, ray.startX, ray.startY)
	local endX, endY = tileCoords(grid.cellSize, ray.startX + ray.dirX, ray.startY + ray.dirY)

	local dx = math.abs(endX - startX)
	local dy = math.abs(endY - startY)
	local incX = endX > startX and 1 or -1
	local incY = endY > startY and 1 or -1

	local err, e2 = dx-dy, nil

	if dx == 0 and dy == 0 then
		grid[startY][startX] = true
		return
	end

	while startX > 0 and startX <= grid.width and startY > 0 and startY <= grid.height do
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
