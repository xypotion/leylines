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
	
	initMap()
	
	--constants
	minNeighborDistance = 20
	lineTouchTolerance = 3
	
	loadLandInfo()
	loadStructureInfo()
	
	initHUD()
	buildMode = "Tower" --debug
	
	startGame()
	
	for k, v in pairs(love.graphics.getSystemLimits()) do
		print(k, v)
	end
end

function love.update(dt)
	--TODO move to "updateHUD()" or something
	mouseX, mouseY = love.mouse.getPosition()
	-- mouseX, mouseY = getWorldCanvasMouseCoordinates()--mouseX, mouseY)
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
			local mx, my = getWorldCanvasMouseCoordinates() --TODO probably unnecessary; just use mouseX and mouseY
			tryToBuildA(buildMode, mx, my)
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
end