--map.lua: most code to do with stencils, canvases, and drawing the map lives here
	
function generateIsland()
	print("generateIsland not implemented")
end	

function drawMap()
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
	--this is where a background canvas will be drawn! TODO
	love.graphics.setColor(63, 127, 63)
	love.graphics.rectangle("fill", 0, 0, canvasWidth, canvasHeight)
	
	--...and not this so much, i don't think. TODO
	-- for k, thing in pairs(landFeatures) do
	-- love.graphics.setColor(thing.type.r, thing.type.g, thing.type.b, 255)
	-- 	love.graphics.circle("fill", thing.x, thing.y, 4, 4)
	-- end
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