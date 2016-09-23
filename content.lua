function loadStructureInfo()
	structureInfo = {
		Shack = {
			r = 255, g = 127, b = 31, 
			size = 4, vision = minNeighborDistance * 2, 
			cost = {Wood = 5}, production = {Stone = 1, Wood = 1}, 
			costIncrease = 1.2
			},
		Temple = {
			r = 255, g = 255, b = 255, 
			size = 6, vision = minNeighborDistance * 3, 
			cost = {Stone = 50}, production = {Stone = 1, Wood = 1}, 
			costIncrease = 2, 
			tip = "Pairs produce Leylines."
			},
		Tower = {
			r = 191, g = 127, b = 255, 
			size = 5, vision = minNeighborDistance * 6, 
			cost = {Stone = 5}, production = {}, 
			costIncrease = 1.6},
		Quarry = {
			r = 63, g = 63, b = 127, 
			size = 5, vision = minNeighborDistance * 2, 
			cost = {Wood = 10, Stone = 10}, production = {Stone = 4}, 
			costIncrease = 1.6
			},
		Mill = {
			r = 127, g = 191, b = 63, 
			size = 5, vision = minNeighborDistance * 2, 
			cost = {Wood = 10, Stone = 10}, production = {Wood = 4}, 
			costIncrease = 1.6
			},
	}
end

function loadLandInfo()
	--TODO some data about land colors. probably just for stone and wood for now
end