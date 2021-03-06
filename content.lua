function loadStructureInfo()
	structureInfo = {
		Camp = {
			r = 255, g = 127, b = 31, 
			size = 1, vision = 6, 
			cost = {Wood = 5}, production = {Stone = 1, Wood = 1}, 
			costIncrease = 1.2,
			upgrades = {
				{type = "Tower", cost = {Stone = 10}},
				{type = "Temple", cost = {Stone = 10, Wood = 10}}
			},
		},
		Temple = {
			r = 255, g = 255, b = 255, 
			size = 1, vision = 9, 
			cost = {Stone = 50}, production = {Stone = 1, Wood = 1}, 
			costIncrease = 2, 
			tip = "Pairs produce Leylines."
		},
		Tower = {
			r = 191, g = 127, b = 255, 
			size = 1, vision = 12, 
			cost = {Stone = 5}, production = {}, 
			costIncrease = 1.6,
			upgrades = {
				{type = "Quarry", cost = {Stone = 20}}
			}
		},
		Quarry = {
			r = 63, g = 63, b = 127, 
			size = 1, vision = 8, 
			cost = {Wood = 10, Stone = 10}, production = {Stone = 4}, 
			costIncrease = 1.6
		},
		Mill = {
			r = 127, g = 191, b = 63, 
			size = 1, vision = 8, 
			cost = {Wood = 10, Stone = 10}, production = {Wood = 4}, 
			costIncrease = 1.6
		},
	}
	
	--kinda debug
	for i, s in pairs(structureInfo) do
		structureInfo[i].img = {}
		structureInfo[i].img[4] = temple8
		structureInfo[i].img[16] = temple32
		--TODO using [4] and [16] is asinine. just call them bigImg and smallImg or something
	end
end

function loadLandInfo()
	--TODO some data about land colors. probably just for stone and wood for now
	landTypes = {
		Ocean = {color = {31, 31, 191}},
		Shoal = {color = {63, 63, 191}},
		Beach = {color = {223, 223, 127}},
		Forest = {color = {63, 191, 63}},
		Mountain = {color = {127, 127, 0}},
		Snow = {color = {223, 223, 223}},
	}
end

function stratifyTerrain()
	for i = 1, #terrain do
		for j = 1, #terrain[i] do
			local t = terrain[i][j]
			if t <= 64 then
				terrain[i][j] = landTypes.Ocean
			elseif t <= 96 then
				terrain[i][j] = landTypes.Shoal
			elseif t <= 128 then
				terrain[i][j] = landTypes.Beach
			elseif t <= 160 then
				terrain[i][j] = landTypes.Forest
			elseif t <= 192 then
				terrain[i][j] = landTypes.Mountain
			elseif t <= 224 then
				terrain[i][j] = landTypes.Snow
			end
		end
	end
end

--TODO ? just to enforce some rules on the content above, like a schema for each content type
function validateContent()
	--e.g. structures must have all the same fields
end
--no idea if this is a good approach