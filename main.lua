require "hud"
require "game"
require "content"
require "map"

function love.load()
	--basics & graphics
	DEBUG = true
	TWO_THIRDS = 2 / 3

	seed = os.time() % 2 ^ 16
	math.randomseed(seed)
	
	mapCanvasWidth, mapCanvasHeight = 512, 512
	love.window.setMode(mapCanvasWidth, mapCanvasHeight)
		
	--TODO rename to mapCanvas, since that's what you mean
	canvas = love.graphics.newCanvas(mapCanvasWidth, mapCanvasHeight)
	canvas:setFilter('nearest', 'nearest', 0)
	
	-- painting = love.graphics.newImage("painting3.jpg")
	
	--constants
	minNeighborDistance = 20
	lineTouchTolerance = 3
	
	loadLandInfo()
	loadStructureInfo()
	
	initHUD()
	buildMode = "Temple" --debug
	
	startGame()
end

function love.update(dt)
	--TODO move to "updateHUD()" or something
	mouseX, mouseY = love.mouse.getPosition()
	hoveredButtonType = mouseOnButton(mouseX, mouseY)
	if hoveredButtonType then updateToolTip(hoveredButtonType) end
	
	--ticks up by dt and produces resources when productionTimer hits 1s
	resourceTimer(dt)
	
	--changes lines' lengths and recalculates leyline powers
	updateLinesAndRecalculate(dt)
end

--either you're clicking a HUD button or building a structure.
function love.mousepressed(x, y)
	if hoveredButtonType then
		--set build mode
		buildMode = hoveredButtonType
	else
		if structureInfo[buildMode] then
			tryToBuildA(buildMode, x, y)
		end
	end	
end

--just debug for now, but TODO should be used for switching build modes, i guess?
function love.keypressed(key)
	if DEBUG then
		if key == "escape" then
			love.event.quit()
		elseif key == "w" then
			resources.Wood = resources.Wood * 2
		elseif key == "s" then
			resources.Stone = resources.Stone * 2
		elseif key == "x" then
			-- print("\nSTART")
			calculateLeylinePower()
		end
	end
end



function love.draw()
	--draw map where structures, leylines, background, and fog appear
	drawMap()
	
	--draw buttons, resource tickers, and other game info
	drawHUD()
	
	--canvas drawing 
	--TODO move to drawMap, i guess?
	love.graphics.setColor(255, 255, 255)
	love.graphics.setCanvas()
	love.graphics.draw(canvas)
	
	love.graphics.setStencilTest()
end