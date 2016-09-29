--this should ONLY be for the sidebar. code for hover/click effects on the map CAN go here, but delineate clearly

function initHUD()
	--make buttons TODO generate dynamically from structure info
	buttons = {
		Shack = {x = 10, y = 10, w = 200, h = 20, label = "Shack: 5 Wood"},
		Temple = {x = 10, y = 35, w = 200, h = 20, label = "Temple: 100 Stone"},
		Tower = {x = 10, y = 60, w = 200, h = 20, label = "Tower: 20 Stone"},
		Quarry = {x = 10, y = 85, w = 200, h = 20, label = "Quarry: 10 Stone, 10 Wood"},
		Mill = {x = 10, y = 110, w = 200, h = 20, label = "Mill: 10 Stone, 10 Wood"},
	}
	
	--initialize these things
	errorMsg = ""
	toolTip = ""
	
	--canvas stuff
	hudWidth = 320
	hudHeight = mapCanvasHeight
	hudCanvas = love.graphics.newCanvas(hudWidth, hudHeight)
	
	
	--make other HUD elements... TODO
end

function updateHUD()
	
end

function drawHUD()
	--canvas setup
	love.graphics.setCanvas(hudCanvas)
	love.graphics.clear()
	
	--background
	love.graphics.setColor(0,0,0)
	love.graphics.rectangle("fill", 0, 0, hudWidth, hudHeight)
	
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
	love.graphics.printf(text, 10, 300, hudWidth - 10, "left")
	
	--error message
	love.graphics.setColor(255, 191, 191)
	love.graphics.printf(errorMsg, 0, 200, hudWidth, "center")
	
	--draw HUD canvas
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setCanvas()
	love.graphics.draw(hudCanvas)
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