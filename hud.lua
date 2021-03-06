--this should ONLY be for the sidebar. code for hover/click effects on the map CAN go here, but delineate clearly

function initHUD()
	--make buttons TODO generate dynamically from structure info
	buttons = {
		Camp = {x = 10, y = 210, w = 200, h = 20, label = "Camp: 5 Wood"},
		Temple = {x = 10, y = 235, w = 200, h = 20, label = "Temple: 100 Stone"},
		Tower = {x = 10, y = 260, w = 200, h = 20, label = "Tower: 20 Stone"}, --this is wrong!
		Quarry = {x = 10, y = 285, w = 200, h = 20, label = "Quarry: 10 Stone, 10 Wood"},
		Mill = {x = 10, y = 310, w = 200, h = 20, label = "Mill: 10 Stone, 10 Wood"},
	}
	
	--initialize these things
	errorMsg = ""
	toolTip = ""
	clickedStructure = nil
	
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
	
	--header info first; TODO refine
	love.graphics.setColor(255, 255, 255)
	love.graphics.print("LEYLINES! TIME: "..math.floor(gameTimer),5, 5, 0, 2)
	
	
	
	--then everything else. if a structure has been clicked...
	if clickedStructure then
		--...show upgrade buttons
	
		--buttons
		--TODO change into upgrade buttons
		-- for k, b in pairs(buttons) do
		-- 	love.graphics.setColor(255, 255, 255)
		-- 	if k == buildMode then
		-- 		love.graphics.rectangle("fill", b.x, b.y, b.w, b.h)
		-- 		love.graphics.setColor(0, 0, 0)
		-- 	else
		-- 		love.graphics.rectangle("line", b.x, b.y, b.w, b.h)
		-- 	end
		-- 	love.graphics.print(b.label, b.x + 5, b.y + 5)
		-- end
		
		--abandon/reinhabit/demolish
		love.graphics.rectangle("line", 10, 40, 145, 30)
		love.graphics.rectangle("line", 165, 40, 145, 30)
		love.graphics.print("abandon", 20, 50)
		love.graphics.print("demolish", 175, 50)
		
		--TODO loop through structure's upgrade options and maka da buddins
		-- love.graphics.rectangle("line", 10, 80, hudWidth - 20, 100)
		-- love.graphics.rectangle("line", 10, 190, hudWidth - 20, 100)
		-- love.graphics.rectangle("line", 10, 300, hudWidth - 20, 100)
		-- love.graphics.print("upgrade", 100, 130)
		-- love.graphics.print("buttons", 100, 240)
		-- love.graphics.print("here", 100, 350)
		
		if clickedStructure.upgrades then
			drawUpgradeButtons()
		else
			--
		end
	
		--button tooltip
		--TODO remove?
		-- if hoveredButtonType then
		-- 	love.graphics.print(toolTip, buttons[hoveredButtonType].x + buttons[hoveredButtonType].w + 10, buttons[hoveredButtonType].y)
		-- end
	else
		--resources & rates
		local text = ""
		for resource, amount in pairs(resources) do
			text = text..resource..": "..amount.."\n"
			text = text..resourceRates[resource].."/s"
			text = text.."\n\n"
		end
		love.graphics.printf(text, 10, 40, hudWidth - 10, "left")
		
		--is the player hovering on a structure?
		if hoveredStructure then
			--show its info
			-- print (hoveredStructure.type)
			--show structure info (type, production, other effects)
			--show "upgrades available" or "no upgrades available"
			love.graphics.print(hoveredStructure.type, 20, 190)
			love.graphics.rectangle("line", 10, 180, 300, 300)
			love.graphics.print("structure info", 20, 230)
		else
			--show terrain info?
			love.graphics.rectangle("line", 10, 180, 300, 300)
			love.graphics.print("terrain \nor \nleyline \ninfo", 20, 230)
			
			--show default HUD info
			love.graphics.setColor(255, 255, 255)
		end
		
		--zoom buttons
		love.graphics.rectangle("line", 10, 500, 90, 90)
		love.graphics.rectangle("line", 110, 500, 90, 90)
		love.graphics.rectangle("line", 210, 500, 90, 90)
		love.graphics.print("zoom", 30, 540)
		love.graphics.print("buttons", 130, 540)
		love.graphics.print("here", 230, 540)
	
		--other buttons
		love.graphics.rectangle("line", 10, 600, 90, 30)
		love.graphics.rectangle("line", 110, 600, 90, 30)
		love.graphics.rectangle("line", 210, 600, 90, 30)
		love.graphics.print("time", 30, 610)
		love.graphics.print("info", 130, 610)
		love.graphics.print("settings", 230, 610)
	end
	
	--error message
	love.graphics.setColor(255, 191, 191)
	love.graphics.printf(errorMsg, 0, 450, hudWidth, "center")
	
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

function drawUpgradeButtons()
	for i, u in ipairs(clickedStructure.upgrades) do
		local h = i * 110

		--border
		love.graphics.rectangle("line", 10, h - 30, hudWidth - 20, 100)
		
		--pic and name
		love.graphics.draw(structureInfo[u.type].img[16], 20, h - 20)
		love.graphics.print(u.type, 60, h - 20)	
		
		--costs
		if u.cost.Wood then 
			love.graphics.print("Wood: "..u.cost.Wood, 20, h + 20)
		end
		if u.cost.Stone then 
			love.graphics.print("Stone: "..u.cost.Stone, 20, h + 35)
		end
	end
end