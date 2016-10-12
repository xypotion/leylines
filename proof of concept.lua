--temple: every pair makes a leyline. cost increases quickly. only gathers local resources when built? or when clicked?
--village: slowly gathers local resources. cost increases slowly. leyline effect = slightly faster gathering

--quarry: gathers stone from red areas. medium cost increase. leyline effect = faster gathering
--mill: gathers wood from green areas. medium cost increase. leyline effect = faster gathering, also produces food?
--farm: gathers food from blue areas. medium cost increase. leyline effect = faster gathering, also produces wood and stone?

--tower: reveals terrain, slowly gathers local resources. medium cost increase. leyline effect = sees much further

--monument: cost increases quickly. leyline effect = lengthens leyline!
--signpost: cost increases quickly. leyline effect = turns water under leyline into land (like a bridge)

--green -> wood, red -> stone, blue -> food (water and fish)?
--are people a resource, too? or just abstracted to food?

--other ideas:
--  different structure "blueprints" have to be discovered. just uncover the terrain & click to acquire or something
--  scrying for rare/unique items: send out 5 evently spaced lines; something good is on one of those lines; can use multiples to triangulate to distant points (but not perfectly)
--  large temples for uniting distant areas, i.e. regular temples' leylines have a length limit, but better ones can link farther

--TODO, generally
--back to proper terrain generation, not a bunch of random points of interest in an infinite green field. but later, because that shit is hard
--enlarged + griddy map, then map scrolling??
--[ability to] preview lines & structures before placing
--other on-hover effects, like for buttons, but also lines & structures
--(?) change the way resources are gathered. might not be as simple as precalculating rates, since the land features' multipliers can change (i guess??)
--make type-in-table implementation pattern more consistent. it's ok to reference one table from another! probably!
--similarly, make color implementation patterns more consistent. i forgot that setColor() can take a table {1,2,3,4}, which sure seems more efficient than {r=1, g=2, b=3, a=4}
--art.
--sound?
--actual good UI, not wonky, debuggy stuff. maybe a sidebar with buttons?

function love.load()
	--basics & graphics
	DEBUG = true
	TWO_THIRDS = 2 / 3
	
	love.math.noise()
	
	math.randomseed(os.time())
	
	canvasWidth, canvasHeight = 720, 720
	love.window.setMode(canvasWidth, canvasHeight)
		
	canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)
	canvas:setFilter('nearest', 'nearest', 0)
	
	-- painting = love.graphics.newImage("painting3.jpg")
	
	--constants
	minDistance = 20
	tolerance = 3
	
	structureInfo = {
		Camp = {r = 255, g = 127, b = 31, size = 4, vision = minDistance * 2, cost = {Wood = 5}, production = {Stone = 1, Wood = 1}, costIncrease = 1.2},
		Temple = {
			r = 255, g = 255, b = 255, size = 6, vision = minDistance * 3, cost = {Stone = 50}, production = {Stone = 1, Wood = 1}, costIncrease = 2, tip = "Pairs produce Leylines."
			},
		Tower = {r = 191, g = 127, b = 255, size = 5, vision = minDistance * 6, cost = {Stone = 5}, production = {}, costIncrease = 1.6},
		Quarry = {r = 63, g = 63, b = 127, size = 5, vision = minDistance * 2, cost = {Wood = 10, Stone = 10}, production = {Stone = 4}, costIncrease = 1.6},
		Mill = {r = 127, g = 191, b = 63, size = 5, vision = minDistance * 2, cost = {Wood = 10, Stone = 10}, production = {Wood = 4}, costIncrease = 1.6},
	}
	
	landInfo = {
		Forest = {r = 127, g = 223, b = 127, productionMultipliers = {Wood = 2}, distanceStep = minDistance},
		Mountain = {r = 255, g = 127, b = 63, productionMultipliers = {Stone = 2}, distanceStep = minDistance},
		Crystal = {r = 255, g = 255, b = 63, productionMultipliers = {Wood = 2, Stone = 2}, distanceStep = minDistance},
	}
	
	--UI
	--TODO generate dynamically...
	buttons = {
		Camp = {x = 10, y = 10, w = 200, h = 20, label = "Camp: 5 Wood"},
		Temple = {x = 10, y = 35, w = 200, h = 20, label = "Temple: 100 Stone"},
		Tower = {x = 10, y = 60, w = 200, h = 20, label = "Tower: 20 Stone"},
		Quarry = {x = 10, y = 85, w = 200, h = 20, label = "Quarry: 10 Stone, 10 Wood"},
		Mill = {x = 10, y = 110, w = 200, h = 20, label = "Mill: 10 Stone, 10 Wood"},
	}
	buildMode = "Temple"
	
	errorMsg = ""
	toolTip = ""
	
	-- newLine = {}
	
	--progress
	resources = {
		Wood = 0,
		Stone = 50,
	}
	
	resourceRates = {
		Wood = 0,
		Stone = 0
	}
	
	lines = {}
	
	counter = 0
	
	structures = {}
	buildA("Temple", canvasWidth / 2, canvasHeight / 2)
	
	--testing lines...
	-- for i = 1, 100 do
		-- buildA("Camp", (canvasWidth / 3) + (i / 10) * 20, (canvasHeight / 3) + (i % 10) * 20)
	-- end
	-- buildA("Temple", canvasWidth / 3, canvasHeight / 3)
	
	--generate a bunch of forests and lakes
	landFeatures = {}
	for i = 1, 50 do
		landFeatures[i] = {
			x = math.random(canvasWidth), 
			y = math.random(canvasWidth),
			numLines = 0
		}
		
		if i <= 20 then
			landFeatures[i].type = landInfo.Forest
		elseif i <= 40 then
			landFeatures[i].type = landInfo.Mountain
		elseif i <= 100 then
			landFeatures[i].type = landInfo.Crystal
		end
	end
end

function love.update(dt)
	mouseX, mouseY = love.mouse.getPosition()
	
	-- newLine = extendedLine(points[#points], mousePos)
	
	counter = counter + dt --TODO rename this. it's only used for resource production
	
	--for each structure...
	for k, s in pairs(structures) do
		--enhance vision ring if applicable
		if s.vision < s.targetVision then
			s.vision = s.vision + dt * structureInfo[s.type].vision * 2
		end
		
		--produce resources if it's time to
		if counter >= 1 then
			for r, amount in pairs(structureInfo[s.type].production) do
				resources[r] = resources[r] + amount * (1 + s.numLines)
			end
		end
	end
	
	counter = counter % 1
	
	--stretch lines, recalculate line-related stuff if it's time to do so
	updateLinesAndRecalculate(dt)
	
	--update tooltip
	hoveredButtonType = mouseOnButton(mouseX, mouseY)
	if hoveredButtonType then updateToolTip(hoveredButtonType) end
end

function love.mousepressed(x, y)
	if hoveredButtonType then
		--set build mode
		buildMode = hoveredButtonType
	else
		if structureInfo[buildMode] then
			tryToBuildA(buildMode, x, y)
		end
	end
	-- print("distance from temple = "..distanceBetween(structures[1], {x = x, y = y}))
	
end

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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--separating because of stencil complications

function love.draw()
	--canvas setup
	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	
	--grey fog of war
	love.graphics.setColor(63, 63, 63)	
	love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
	
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
	
	drawUI()
	
	--canvas drawing
	love.graphics.setColor(255, 255, 255)
	love.graphics.setCanvas()
	love.graphics.draw(canvas)
	
	love.graphics.setStencilTest()
end

function drawTerrainVision()
	love.graphics.setColor(255, 255, 255, 255)
	
	--structures' visions
	for k, s in pairs(structures) do
		-- love.graphics.setColor(127, 191, 127, 255)
		love.graphics.ellipse("fill", s.x, s.y, s.vision, s.vision * TWO_THIRDS)
	end
	
	--lines' visions
	love.graphics.setLineWidth(minDistance)
	love.graphics.setLineStyle("smooth")
	for i = 1, #lines do
		love.graphics.line(lines[i].x1, lines[i].y1, lines[i].x2, lines[i].y2)
	end
end

function drawTerrain()
	--this is where a background canvas will be drawn! TODO
	love.graphics.setColor(63, 127, 63)
	love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
	
	--...and not this so much, i don't think. TODO
	for k, thing in pairs(landFeatures) do
	love.graphics.setColor(thing.type.r, thing.type.g, thing.type.b, 255)
		love.graphics.circle("fill", thing.x, thing.y, 4, 4)
	end
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

function drawUI()
	--buttons
	for k, b in pairs(buttons) do
		love.graphics.setColor(255, 255, 255)
		if k == buildMode then
			love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
			love.graphics.setColor(0, 0, 0)
		else
			love.graphics.rectangle("line", b.x, b.y, b.w, b.h)
		end
		love.graphics.print(b.label, b.x + 5, b.y + 5)
	end
	
	love.graphics.setColor(255, 255, 255)
	
	--tooltip
	if hoveredButtonType then
		love.graphics.print(toolTip, buttons[hoveredButtonType].x + buttons[hoveredButtonType].w + 10, buttons[hoveredButtonType].y)
	end
	
	--resources & rates
	local text = ""
	for resource, amount in pairs(resources) do
		text = text..resource..": "..amount.."\n"
		text = text..resourceRates[resource].."/s"
		text = text.."\n\n"
	end
	love.graphics.printf(text, 0, 10, canvasWidth - 10, "right")
	
	--error message
	love.graphics.setColor(255, 191, 191)
	love.graphics.printf(errorMsg, 0, 10, canvasWidth, "center")
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--build a thing, but make sure it's allowed first (visible area, not crowding, have materials)
function tryToBuildA(type, x, y)
	local allowed = true
	errorMsg = ""

	allowed = clickingGreen(x, y) and allowed
	allowed = overMinDistanceFromNeighbors(x, y) and allowed
	allowed = costMet(type) and allowed
	
	if allowed then
		buildA(type, x, y)
		
		increaseStructureCost(type)
	end
end

function buildA(type, x, y)
	if structureInfo[type] then
		--deduct cost
		for resource, amount in pairs(structureInfo[type].cost) do
			resources[resource] = resources[resource] - amount
		end
		
		--build it already
		table.insert(structures, {
			type = type, 
			x = x, 
			y = y, 
			vision = 0, 
			targetVision = structureInfo[type].vision,
			numLines = 0
			-- production = structureInfo[type].production --maybe not that simple... gotta clone, not just ref. good TODO for performance, anyway
		})
		
		if type == "Temple" then
			addNewLeylines()
			-- calculateLeylinePower()
			structureCalculationsNeeded = true
		end
	end
	
	structureCalculationsNeeded = true
end

function costMet(type)
	local costMet = true
	for resource, amount in pairs(structureInfo[type].cost) do
		if resources[resource] < amount then
			errorMsg = errorMsg.."not enough "..resource..".\n"
			costMet = false
		end
	end
	
	return costMet
end

function clickingGreen(x, y)
	local c = {r=0, g=0, b=0, a=0}
	local iData = canvas:newImageData()
	
	c.r, c.g, c.b = iData:getPixel(x, y)
	
	if c.r == 63 and c.g == 63 and c.b == 63 then
		errorMsg = errorMsg.."cannot build in non-visible areas.\n"
		return false
	else
		return true
	end
end

function overMinDistanceFromNeighbors(x, y)
	local overMin = true
	for k, s in pairs(structures) do
		if distanceBetween(s, {x = x, y = y}) < 20 then
			overMin = false
			-- print ("too close!")
			errorMsg = errorMsg.."too close to other structures.\n"
			break
		end
	end
	
	return overMin
end

function increaseStructureCost(type, setTo)
	local label = type..": "
	
	for r, a in pairs(structureInfo[type].cost) do
		if setTo and setTo[r] then
			structureInfo[type].cost[r] = setTo[r]
		else
			structureInfo[type].cost[r] = math.ceil(a * structureInfo[type].costIncrease)
		end

		label = label..structureInfo[type].cost[r].." "..r.." "
	end
	
	buttons[type].label = label
end

function mouseOnButton(x, y)
	for k, b in pairs(buttons) do
		if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
			return k
		end
	end
	
	return nil
end 

function updateToolTip(type)
	if structureInfo[type].tip then
		toolTip = type.."\n"..structureInfo[type].tip.."\n"
	else
		toolTip = type.."\n"
	end
	
	for r, amt in pairs(structureInfo[type].production) do
		toolTip = toolTip.."Produces "..amt.." "..r.." per second.\n"
	end
end

function addNewLeylines()
	local noob = structures[#structures]
	for i = 1, #structures - 1 do
		if structures[i].type == "Temple" then
			table.insert(lines, extendedLine(noob, structures[i], {255, 255, 255, 255}))
		end
	end
end

function extendedLine(p1, p2, color, r)
	local ratio = r or 0.5
	
	local xDiff = p1.x - p2.x
	local yDiff = p1.y - p2.y
	
	return {
		x1 = p1.x - xDiff * ratio, 
		y1 = p1.y - yDiff * ratio, 
		x2 = p2.x + xDiff * ratio,
		y2 = p2.y + yDiff * ratio,
		ratio = ratio,
		targetRatio = 1,
		p1 = p1,
		p2 = p2,
		lineLevel = 0,
		-- slope = yDiff / xDiff,
		-- perpendicular = -xDiff / yDiff,
		color = color or {math.random(255), math.random(255), math.random(255), 127},
	}
end

function calculateLeylinePower()
	for i, structure in ipairs(structures) do
		-- print(structure.type)
		if structure.type ~= "Temple" then
			structures[i].numLines = 0
			-- print("")
			for j, line in pairs(lines) do
				if(distanceToLine(structure, line)) then
				-- if(isPointNearLine(structure, line)) then
					-- print("point "..i.." is on line "..j)
					structures[i].numLines = structures[i].numLines + 1
				else
					-- print("point "..i.." is NOT on line "..j)
				end
			end
		end
	end
end

--thanks, https://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line. would not have figured this out on my own.
function distanceToLine(p, l)
	local xDiff = l.x2 - l.x1
	local yDiff = l.y2 - l.y1
	local numerator = math.abs(yDiff * p.x - xDiff * p.y + l.x2 * l.y1 - l.y2 * l.x1)
	local denominator = (yDiff ^ 2 + xDiff ^ 2) ^ 0.5
	local distance = numerator / denominator
	
	if distance < structureInfo[p.type].size + tolerance
	and (
		(l.x1 <= p.x and p.x <= l.x2) or --TODO bad bad bad, use x1x2y1y2
		(l.x2 <= p.x and p.x <= l.x1)
	) and (
		(l.y1 <= p.y and p.y <= l.y2) or
		(l.y2 <= p.y and p.y <= l.y1)
	)
	then
		-- print(distance) -- debug
		return true
	else
		-- print(distance) -- debug
		return false
	end
end

--now that they're all calculated, use numLines to augments structures' effects
function applyLeylinePower()
	--
	for i, s in pairs(structures) do
		if s.type == "Tower" then
			structures[i].targetVision = minDistance * (6 + 3 * s.numLines)
		-- elseif s.type == "Camp" then
		-- 	structures[i].targetVision = minDistance * (4 + 2 * s.numLines)
		end
	end
end

function calculateResourceRates()
	for r, amt in pairs(resourceRates) do
		resourceRates[r] = 0
	end
	
	for i, s in pairs(structures) do
		for r, amt in pairs(structureInfo[s.type].production) do
			resourceRates[r] = resourceRates[r] + amt * (1 + s.numLines)
		end
	end
	
	--test
	-- for r, amt in pairs(resourceRates) do
	-- 	print(r, amt)
	-- end
end

function changeLineLength(line, ratio)
	return extendedLine(line.p1, line.p2, line.color, line.ratio)
end

function distanceBetween(p1, p2)
	local xDiff = p1.x - p2.x
	local yDiff = p1.y - p2.y
	
	return (xDiff ^ 2 + yDiff ^ 2) ^ 0.5
end

function updateLinesAndRecalculate(dt)
	--lengthen lines & apply their power
	local linesChanging = false

	for k, l in pairs(lines) do
		if l.ratio < l.targetRatio then
			l.ratio = l.ratio + dt
			lines[k] = changeLineLength(lines[k], l.ratio)
			linesChanging = true
		end
	end

	--update some stuff if leylines were added
	if structureCalculationsNeeded and not linesChanging then 
		calculateLeylinePower()
		applyLeylinePower()
		calculateResourceRates()
	
		structureCalculationsNeeded = false
	end
end