require "hud"
require "game"
require "content"
require "map"
require "images"

function love.load()
	--basics & graphics
	DEBUG = true
	TWO_THIRDS = 2 / 3

	seed = os.time() % 2 ^ 16
	math.randomseed(seed)
	print("seed: "..seed)
	
	initMap()
	
	loadImages()
	
	loadLandInfo()
	loadStructureInfo()
	
	initHUD()
	buildMode = "Tower" --debug
	drawCursorBox = true --debug
	hoveredStructure = nil

	love.window.setMode(mapCanvasWidth + hudWidth, mapCanvasHeight)
	love.window.setTitle("Leylines v0.1")
	
	startGame()

	--debug
	-- for k, v in pairs(love.graphics.getSystemLimits()) do
	-- 	print(k, v)
	-- end
	
	love.keyboard.setKeyRepeat(true)
	
	scrollSpeed = 2
	
	--debug
	fpsCounter = 0
	frameCounter = 0
	fpsWarning = 58
end

function love.update(dt)
	--TODO move to "updateHUD()" or something
	mouseX, mouseY = love.mouse.getPosition()
	hoveredButtonType = mouseOnButton(mouseX, mouseY)
	if hoveredButtonType then updateToolTip(hoveredButtonType) end
	
	--TODO move to another function?
	mapMouseX, mapMouseY = getWorldCanvasMouseCoordinates()
	drawCursorBox = true
	hoveredStructure = nil
	for i, s in pairs(structures) do
		if (mapMouseX == s.x or mapMouseX == s.x + 1) and (mapMouseY == s.y or mapMouseY == s.y + 1) then
			-- print(s.type)
			drawCursorBox = false
			hoveredStructure = s
		end
	end
	
	--ticks up by dt and produces resources when productionTimer hits 1s
	resourceTimer(dt)
	
	--changes lines' lengths and recalculates leyline powers
	updateLinesAndRecalculate(dt)
	
	--debug for FPS
	fpsCounter = fpsCounter + dt
	frameCounter = frameCounter + 1
	if fpsCounter > 1 then
		if frameCounter <= fpsWarning then
			print("FPS = "..frameCounter)
		end
		frameCounter = 0
	end
	fpsCounter = fpsCounter % 1
end

--either you're clicking a HUD button or building a structure.
function love.mousepressed(x, y)
	if hoveredButtonType then
		--set build mode
		buildMode = hoveredButtonType
	else
		if structureInfo[buildMode] then
			tryToBuildA(buildMode, mapMouseX, mapMouseY)
		end
	end	
end

--just debug for now, but TODO should be used for switching build modes, i guess?
function love.keypressed(key)
	if DEBUG then
		if key == "escape" then
			love.event.quit()
		elseif key == "w" then
			resources.Wood = resources.Wood + 10 ^ 6
		elseif key == "s" then
			resources.Stone = resources.Stone + 10 ^ 6
		elseif key == "x" then
			-- print("\nSTART")
			calculateLeylinePower()
		end
	end
	
	if key == "left" then
		--this works, but move to a different function, probably in map.lua TODO
		worldContainer.x = worldContainer.x + mapScale * scrollSpeed
	elseif key == "right" then
		worldContainer.x = worldContainer.x - mapScale * scrollSpeed
	elseif key == "up" then
		worldContainer.y = worldContainer.y + mapScale * scrollSpeed
	elseif key == "down" then
		worldContainer.y = worldContainer.y - mapScale * scrollSpeed
	end
	
	if key == "-" then
		zoomOut()
	elseif key == "=" then
		zoomIn()
	end
end

function love.draw()
	--draw map where structures, leylines, background, and fog appear
	drawMap()
	
	--draw buttons, resource tickers, and other game info
	drawHUD()
end