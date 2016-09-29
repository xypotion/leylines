function startGame()
	resources = {
		Wood = 0,
		Stone = 50, --debug
	}
	
	resourceRates = {
		Wood = 0,
		Stone = 0
	}
	
	lines = {}
	
	productionTimer = 0
	
	generateIsland()
	
	structures = {}
	buildA("Temple", mapCanvasWidth / 2, mapCanvasHeight / 2) --debug
end

function resourceTimer(dt)
	productionTimer = productionTimer + dt --TODO rename this. it's only used for resource production
	
	--for each structure...
	for k, s in pairs(structures) do
		--enhance vision ring if applicable
		if s.vision < s.targetVision then
			s.vision = s.vision + dt * structureInfo[s.type].vision * 2
		end
		
		--produce resources if it's time to
		if productionTimer >= 1 then
			produceAllResources(s)
		end
	end
	
	productionTimer = productionTimer % 1
end

function produceAllResources(structure)
	for r, amount in pairs(structureInfo[structure.type].production) do
		resources[r] = resources[r] + amount * (1 + structure.numLines)
	end
end

--build a structure, but make sure it's allowed first (visible area, not crowding, have materials)
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

--actually add that structure
function buildA(type, x, y)
	print("building at", x, y)
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
			numLines = 0,
			img = structureInfo[type].img
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

--TODO all of this will have to go! use cell attributes, not clicked pixel color
function clickingGreen(x, y)
	local c = {r=0, g=0, b=0, a=0}
	local iData = worldContainer.canvas:newImageData() 
	
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
		if distanceBetween(s, {x = x, y = y}) < minNeighborDistance then
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
	
	buttons[type].label = label --TODO no no no, not here
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
	
	if distance < structureInfo[p.type].size + lineTouchTolerance
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
			structures[i].targetVision = minNeighborDistance * (6 + 3 * s.numLines)
		-- elseif s.type == "Shack" then
		-- 	structures[i].targetVision = minNeighborDistance * (4 + 2 * s.numLines)
		end
	end
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