--map.lua: most code to do with stencils, canvases, and drawing the map lives here

function initMap()
	mapCanvasWidth, mapCanvasHeight = 640, 640 --TODO these need to be not-global (i think)
	love.window.setMode(mapCanvasWidth, mapCanvasHeight) --TODO and this should not go in map.lua :[
	love.window.setTitle("Leylines v0.1")
		
	--worldCanvas = for drawing terrain and fog of war
	--yes, terrain is also on its own canvas, but it's drawn to the world canvas
	worldContainer = {}
	worldContainer.canvas = love.graphics.newCanvas(mapCanvasWidth, mapCanvasHeight)
	worldContainer.canvas:setFilter('linear', 'nearest', 0)
	
	mapScale = 16 --TODO maybe just change this back to worldScale or something
	
	--stuffCanvas = for drawing structures and leylines
	stuffContainer = {} --TODO this name... yeah. :/
	stuffContainer.canvas = love.graphics.newCanvas(mapCanvasWidth, mapCanvasHeight) --TODO probably not right? maybe have own versions?
	stuffContainer.canvas:setFilter('linear', 'nearest', 0)
	
	stuffContainer.scale = mapScale / 16 --the trick is actually to change the points' distributions, not to scale the draw TODO
	
	--should be called whenever canvas is zoomed or scrolled (i guess?)
	setWorldAndStuffCanvasLocation()
		
	--constants
	minNeighborDistance = 4
	lineTouchTolerance = 2
	
	--viewport stuff. 
	--viewX and viewY are the top left corner of the viewport
	-- viewX = mapCanvasWidth / 2 - mapCanvasWidth / (mapScale * 2)
	-- viewY = mapCanvasHeight / 2 - mapCanvasHeight / (mapScale * 2)
	--or... a table called visibleRange with top left x+y and ranges
end

function zoomOut()
	mapScale = 4
	setWorldAndStuffCanvasLocation()
end

function zoomIn()
	mapScale = 16
	setWorldAndStuffCanvasLocation()
end


------------move us
function setWorldAndStuffCanvasLocation()
	worldContainer.x = mapCanvasWidth / 2 - mapCanvasWidth * mapScale / 2
	worldContainer.y = mapCanvasHeight / 2 - mapCanvasHeight * mapScale / 2
	
	stuffContainer.x, stuffContainer.y = 0,0--worldContainer.x, worldContainer.y --TODO chanto shinasai!
end

function getWorldCanvasMouseCoordinates()--mx, my)
	local mx, my = love.mouse.getPosition()
	local worldX = math.floor(mx / mapScale - worldContainer.x / mapScale + 1)
	local worldY = math.floor(my / mapScale - worldContainer.y / mapScale + 1)
	
	return worldX, worldY
end
---------------

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
	--canvas setup: world (terrain + fog/vision) first
	love.graphics.setCanvas(worldContainer.canvas)
	love.graphics.clear()
	
	drawFogAndTerrain()
	
	--canvas setup: structures and lines next
	love.graphics.setCanvas(stuffContainer.canvas)
	love.graphics.clear()
	
	drawLeylines()

	drawStructures()
	
	--debug; just putting here until TODO it gets its own place
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("line", 
	math.floor(mouseX/mapScale)*mapScale, 
	math.floor(mouseY/mapScale)*mapScale, 
	mapScale * 2, mapScale * 2)
	
	--mouse-linked line
	-- love.graphics.line(points[#points].x, points[#points].y, mouseX, mouseY)
	-- love.graphics.line(newLine.x1, newLine.y1, newLine.x2, newLine.y2)
	
	--actually draw the terrain, then the stuff)
	love.graphics.setCanvas()
	
	love.graphics.draw(worldContainer.canvas, worldContainer.x, worldContainer.y, 0, mapScale)
	
	love.graphics.draw(stuffContainer.canvas, stuffContainer.x, stuffContainer.y, 0, stuffContainer.scale)
end

function drawFogAndTerrain()
	--grey fog of war
	love.graphics.setColor(63, 63, 63)	
	love.graphics.rectangle("fill", 0, 0, mapCanvasWidth, mapCanvasHeight)
	
	--draw visible areas as stencil
	love.graphics.stencil(drawTerrainVision, "increment")

	love.graphics.setStencilTest("greater", 0)

	--draw land & terrain features (-> stencil shape)
	drawTerrain()
	
	--revert to normal drawing
	love.graphics.setStencilTest()
end

--how far each structure can "see"; only called from love.graphics.stencil() in drawMap()!
--TODO obviously needs lots of changes if you're scaling up the whole game
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

--actual resolution is 1-to-1; the scale is used to change elements' draw positions
--TODO ultimately should probably separate into two functions
function drawLeylines()
	--lines
	love.graphics.setLineWidth(1)
	for i = 1, #lines do
		love.graphics.setColor(lines[i].color)
		love.graphics.line(lines[i].x1 * mapScale + worldContainer.x, lines[i].y1 * mapScale + worldContainer.y, lines[i].x2 * mapScale + worldContainer.x, lines[i].y2 * mapScale + worldContainer.y)
	end
end
	
function drawStructures()
	--structures
	for k, s in pairs(structures) do
		love.graphics.setColor(structureInfo[s.type].r, structureInfo[s.type].g + s.numLines * 32, structureInfo[s.type].b, 255)
		-- love.graphics.circle("fill", s.x, s.y, structureInfo[s.type].size)
		love.graphics.draw(s.img[mapScale], s.x * mapScale + worldContainer.x - mapScale, s.y * mapScale + worldContainer.y - mapScale)
	end
end