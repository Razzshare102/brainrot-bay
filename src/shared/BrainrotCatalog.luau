-- Brainrot Bay: the cast. Fifteen original characters on six rarity rungs,
-- each with a price and a money-per-second rate. Mutations roll on spawn and
-- multiply the rate. Nothing here knows about the belt or the bases; it is
-- just the catalogue both the server and the client read from.

local BrainrotCatalog = {}

-- Rarity rungs, cheapest first. Weight is the belt spawn weight, multiplier
-- scales the base rate of every character on that rung.
BrainrotCatalog.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(180, 180, 180), weight = 40, multiplier = 1 },
	{ name = "Rare", color = Color3.fromRGB(80, 160, 255), weight = 26, multiplier = 2 },
	{ name = "Epic", color = Color3.fromRGB(170, 90, 255), weight = 16, multiplier = 3.5 },
	{ name = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 10, multiplier = 6 },
	{ name = "Mythic", color = Color3.fromRGB(255, 70, 200), weight = 6, multiplier = 10 },
	{ name = "Secret", color = Color3.fromRGB(255, 40, 40), weight = 2, multiplier = 18 },
}

-- Mutations: a small chance on spawn. The multiplier applies to the rate.
BrainrotCatalog.MUTATIONS = {
	{ name = "Normal", color = Color3.fromRGB(255, 255, 255), chance = 70, multiplier = 1 },
	{ name = "Golden", color = Color3.fromRGB(255, 215, 0), chance = 14, multiplier = 2 },
	{ name = "Rainbow", color = Color3.fromRGB(120, 220, 255), chance = 8, multiplier = 3 },
	{ name = "Diamond", color = Color3.fromRGB(180, 240, 255), chance = 5, multiplier = 5 },
	{ name = "Void", color = Color3.fromRGB(90, 40, 160), chance = 2, multiplier = 8 },
	{ name = "Cosmic", color = Color3.fromRGB(255, 120, 255), chance = 1, multiplier = 12 },
}

-- The cast. bodyColor is the character's main colour, bellyColor the second
-- one; shape picks the silhouette the belt builder draws (blob, tall, wide).
BrainrotCatalog.CHARACTERS = {
	{ id = "noodle", name = "Noodle Noodle", rarity = "Common", rate = 2, price = 50, bodyColor = Color3.fromRGB(255, 220, 90), bellyColor = Color3.fromRGB(255, 250, 200), shape = "blob" },
	{ id = "croc", name = "Soggy Croc", rarity = "Common", rate = 3, price = 90, bodyColor = Color3.fromRGB(90, 200, 90), bellyColor = Color3.fromRGB(200, 240, 180), shape = "wide" },
	{ id = "cone", name = "Traffic Cone Tim", rarity = "Common", rate = 4, price = 140, bodyColor = Color3.fromRGB(255, 120, 40), bellyColor = Color3.fromRGB(255, 255, 255), shape = "tall" },
	{ id = "pigeon", name = "Disco Pigeon", rarity = "Rare", rate = 7, price = 300, bodyColor = Color3.fromRGB(255, 120, 200), bellyColor = Color3.fromRGB(200, 220, 255), shape = "blob" },
	{ id = "barks", name = "Sir Barksalot", rarity = "Rare", rate = 9, price = 450, bodyColor = Color3.fromRGB(160, 110, 60), bellyColor = Color3.fromRGB(230, 200, 150), shape = "wide" },
	{ id = "pickle", name = "Pickle Rickshaw", rarity = "Rare", rate = 12, price = 650, bodyColor = Color3.fromRGB(110, 220, 90), bellyColor = Color3.fromRGB(220, 255, 190), shape = "tall" },
	{ id = "banana", name = "Banana Pharaoh", rarity = "Epic", rate = 18, price = 1200, bodyColor = Color3.fromRGB(255, 215, 60), bellyColor = Color3.fromRGB(120, 180, 255), shape = "tall" },
	{ id = "wasabi", name = "DJ Wasabi", rarity = "Epic", rate = 24, price = 1800, bodyColor = Color3.fromRGB(230, 60, 60), bellyColor = Color3.fromRGB(60, 230, 120), shape = "blob" },
	{ id = "crumb", name = "Captain Crumb", rarity = "Epic", rate = 30, price = 2500, bodyColor = Color3.fromRGB(70, 130, 255), bellyColor = Color3.fromRGB(255, 230, 150), shape = "wide" },
	{ id = "lasagna", name = "Lord Lasagna", rarity = "Legendary", rate = 45, price = 4500, bodyColor = Color3.fromRGB(170, 90, 220), bellyColor = Color3.fromRGB(255, 210, 90), shape = "wide" },
	{ id = "toilet", name = "Turbo Toilet", rarity = "Legendary", rate = 60, price = 6500, bodyColor = Color3.fromRGB(240, 240, 240), bellyColor = Color3.fromRGB(120, 200, 255), shape = "tall" },
	{ id = "quokka", name = "Queen Quokka", rarity = "Legendary", rate = 80, price = 9000, bodyColor = Color3.fromRGB(60, 200, 190), bellyColor = Color3.fromRGB(255, 240, 200), shape = "blob" },
	{ id = "gummy", name = "Galactic Gummy Bear", rarity = "Mythic", rate = 120, price = 15000, bodyColor = Color3.fromRGB(255, 80, 200), bellyColor = Color3.fromRGB(180, 255, 220), shape = "blob" },
	{ id = "reginald", name = "Sir Reginald III", rarity = "Mythic", rate = 160, price = 22000, bodyColor = Color3.fromRGB(200, 200, 210), bellyColor = Color3.fromRGB(255, 215, 90), shape = "tall" },
	{ id = "spaghetti", name = "The One True Spaghetti", rarity = "Secret", rate = 300, price = 50000, bodyColor = Color3.fromRGB(255, 210, 80), bellyColor = Color3.fromRGB(255, 120, 120), shape = "wide" },
}

function BrainrotCatalog.findCharacter(id)
	for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
		if character.id == id then
			return character
		end
	end
	return nil
end

function BrainrotCatalog.findRarity(name)
	for _, rarity in ipairs(BrainrotCatalog.RARITIES) do
		if rarity.name == name then
			return rarity
		end
	end
	return BrainrotCatalog.RARITIES[1]
end

-- Full earning rate of a character on its rung with a mutation applied.
function BrainrotCatalog.rateOf(character, mutation)
	local rarity = BrainrotCatalog.findRarity(character.rarity)
	return math.floor(character.rate * rarity.multiplier * mutation.multiplier + 0.5)
end

-- Roll a rarity by weight, then a character on that rung, then a mutation.
function BrainrotCatalog.rollSpawn()
	local totalWeight = 0
	for _, rarity in ipairs(BrainrotCatalog.RARITIES) do
		totalWeight += rarity.weight
	end
	local pick = math.random(1, totalWeight)
	local rung = BrainrotCatalog.RARITIES[1]
	for _, rarity in ipairs(BrainrotCatalog.RARITIES) do
		pick -= rarity.weight
		if pick <= 0 then
			rung = rarity
			break
		end
	end
	local pool = {}
	for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
		if character.rarity == rung.name then
			table.insert(pool, character)
		end
	end
	local character = pool[math.random(1, #pool)]
	local roll = math.random(1, 100)
	local mutation = BrainrotCatalog.MUTATIONS[1]
	for _, candidate in ipairs(BrainrotCatalog.MUTATIONS) do
		roll -= candidate.chance
		if roll <= 0 then
			mutation = candidate
			break
		end
	end
	return character, mutation
end

return BrainrotCatalog
