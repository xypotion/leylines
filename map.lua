--map.lua: most code to do with stencils, canvases, and drawing the map lives here

function initMap()
	mapCanvasWidth, mapCanvasHeight = 720, 720
	love.window.setMode(mapCanvasWidth, mapCanvasHeight)
		
	--worldCanvas = for drawing terrain and fog of war
	worldCanvas = love.graphics.newCanvas(mapCanvasWidth, mapCanvasHeight)
	worldCanvas:setFilter('linear', 'nearest', 0)
	
	worldScale = 16
	setWorldCanvasLocation()
	
	--stuffCanvas = for drawing structures and leylines
	stuffCanvas = love.graphics.newCanvas(mapCanvasWidth, mapCanvasHeight) --TODO probably not right? maybe have own versions?
	stuffCanvas:setFilter('linear', 'nearest', 0)
	stuffScale = worldScale / 16
	
	--constants
	minNeighborDistance = 4
	lineTouchTolerance = 2
end

function setWorldCanvasLocation()
	worldCanvasX = mapCanvasWidth / 2 - mapCanvasWidth * worldScale / 2
	worldCanvasY = mapCanvasHeight / 2 - mapCanvasHeight * worldScale / 2
end

function getWorldCanvasMouseCoordinates()--mx, my)
	local mx, my = love.mouse.getPosition()
	local worldX = math.floor(mx / worldScale - worldCanvasX / worldScale)
	local worldY = math.floor(my / worldScale - worldCanvasY / worldScale)
	
	return worldX, worldY
end

function generateIsland()
	--make sum noize
	terrain = generateMultiOctavePerlinNoise()
	
	--plain elevations become land types
	stratifyTerrain()
	
	--draw terrain once to a special canvas
	drawTerrainToTerrainCanvas()
end

--makes some pretty terrain with perlin noise. thanks to https://love2d.org/forums/viewtopic.php?f=4&t=82737&p=202175 for inspiration
--TODO will need a slightly different approach once map is expandable
function generateMultiOctavePerlinNoise()
	local grid = {}
	foo = {}
	for i = 1, mapCanvasWidth do
		grid[i] = {}
		for j = 1, mapCanvasWidth do
			grid[i][j] = 0
			+ love.math.noise(i / 128 + seed, j / 128 + seed) * 128
			+ love.math.noise(i / 64 + seed, j / 64 + seed) * 64
			+ love.math.noise(i / 32 + seed, j / 32 + seed) * 32
			+ love.math.noise(i / 16 + seed, j / 16 + seed) * 16
			+ love.math.noise(i / 8 + seed, j / 8 + seed) * 8
			+ love.math.noise(i / 4 + seed, j / 4 + seed) * 4
			+ love.math.noise(i / 2 + seed, j / 2 + seed) * 2
			
			grid[i][j] = math.floor(grid[i][j] / 32) * 32
			
			--debug
			if not foo[grid[i][j]] then
				foo[grid[i][j]] = {i = i, j = j, count = 1}
			else
				foo[grid[i][j]].count = foo[grid[i][j]].count + 1
			end
		end
	end
	
	--debug
	-- for f, oo in pairs(foo) do
	-- 	print(f, oo.count)
	-- end
	
	return grid
end

--should be called once at start of game, and (TODO) only again if terrain is changed/expanded
function drawTerrainToTerrainCanvas()
	terrainCanvas = love.graphics.newCanvas(mapCanvasWidth, mapCanvasHeight)
	terrainCanvas:setFilter('nearest', 'nearest', 0)
	
	love.graphics.setCanvas(terrainCanvas)
	love.graphics.clear()
	
	--draw terrain cells
	for i, row in ipairs(terrain) do
		for j, cell in ipairs(row) do
			-- print (cell)
			love.graphics.setColor(cell.color)
			love.graphics.rectangle("fill", i, j, 1, 1)
		end
	end
	
	love.graphics.setCanvas()
end

function drawMap()
	--canvas setup
	love.graphics.setCanvas(worldCanvas)
	love.graphics.clear()
	
	--grey fog of war
	love.graphics.setColor(63, 63, 63)	
	love.graphics.rectangle("fill", 0, 0, mapCanvasWidth, mapCanvasHeight)
	
	--draw visible areas as stencil
	love.graphics.stencil(drawTerrainVision, "increment")

	love.graphics.setStencilTest("greater", 0)

	--draw land & terrain features (-> stencil shape)
	drawTerrain()
	
	--mouse-linked line
	-- love.graphics.line(points[#points].x, points[#points].y, mouseX, mouseY)
	-- love.graphics.line(newLine.x1, newLine.y1, newLine.x2, newLine.y2)
	
	--revert to normal drawing
	love.graphics.setStencilTest()
	
	drawStructuresAndLeylines()

	--draw the map (terrain + stuff)
	love.graphics.setColor(255, 255, 255)
	love.graphics.setCanvas()
	love.graphics.draw(worldCanvas, worldCanvasX, worldCanvasY, 0, worldScale)
	
	--another layer for graphics and lines?
	love.graphics.setCanvas()
	love.graphics.draw(templeImg,  mapCanvasWidth / 2 - worldScale / 2, mapCanvasHeight / 2 - worldScale / 2, 0, 1)
	
	--necessary for ???
	love.graphics.setStencilTest()
end

--how far each structure can "see" TODO obviously needs lots of changes if you're scaling up the whole game
function drawTerrainVision()
	love.graphics.setColor(255, 255, 255, 255)
	
	--structures' visions
	for k, s in pairs(structures) do
		-- love.graphics.setColor(127, 191, 127, 255)
		love.graphics.ellipse("fill", s.x, s.y, s.vision, s.vision * TWO_THIRDS)
	end
	
	--lines' visions
	love.graphics.setLineWidth(minNeighborDistance) --TODO not appropriate
	love.graphics.setLineStyle("smooth")
	for i = 1, #lines do
		love.graphics.line(lines[i].x1, lines[i].y1, lines[i].x2, lines[i].y2)
	end
end

function drawTerrain()
	love.graphics.setColor(255, 255, 255)
	
	love.graphics.draw(terrainCanvas)
end

function drawStructuresAndLeylines()
	--structures
	for k, s in pairs(structures) do
		love.graphics.setColor(structureInfo[s.type].r, structureInfo[s.type].g + s.numLines * 32, structureInfo[s.type].b, 255)
		love.graphics.circle("fill", s.x, s.y, structureInfo[s.type].size)
	end
	
	--lines
	love.graphics.setLineWidth(1)
	for i = 1, #lines do
		love.graphics.setColor(lines[i].color)
		love.graphics.line(lines[i].x1, lines[i].y1, lines[i].x2, lines[i].y2)
	end
end