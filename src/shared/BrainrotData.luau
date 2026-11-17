-- Brainrot Bay — the shared catalogue of every brainrot character, rarity,
-- mutation and shop item. Both the server (spawning, earnings, shop) and the
-- client (labels, shop UI) read this one table, so a character's numbers are
-- never written down twice.

local BrainrotData = {}

-- Rarities, weakest first. Weight is the spawn weight on the belt; RateMult
-- scales a brainrot's base $/s; Color is the rarity colour used on labels.
BrainrotData.RARITIES = {
	Common = { Weight = 40, RateMult = 1.0, Color = Color3.fromRGB(200, 200, 200) },
	Rare = { Weight = 26, RateMult = 2.0, Color = Color3.fromRGB(80, 180, 255) },
	Epic = { Weight = 16, RateMult = 4.0, Color = Color3.fromRGB(170, 90, 255) },
	Legendary = { Weight = 10, RateMult = 8.0, Color = Color3.fromRGB(255, 170, 0) },
	Mythic = { Weight = 6, RateMult = 16.0, Color = Color3.fromRGB(255, 70, 120) },
	Secret = { Weight = 2, RateMult = 32.0, Color = Color3.fromRGB(255, 220, 60) },
}

BrainrotData.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- Mutations roll rarely on a spawned brainrot and multiply its $/s again.
-- Tint is the colour the brainrot's body takes while mutated.
BrainrotData.MUTATIONS = {
	None = { Chance = 0, RateMult = 1.0, Tint = nil },
	Golden = { Chance = 0.06, RateMult = 2.0, Tint = Color3.fromRGB(255, 215, 0) },
	Diamond = { Chance = 0.04, RateMult = 3.0, Tint = Color3.fromRGB(180, 230, 255) },
	Lava = { Chance = 0.03, RateMult = 4.0, Tint = Color3.fromRGB(255, 90, 20) },
	Rainbow = { Chance = 0.02, RateMult = 5.0, Tint = Color3.fromRGB(255, 120, 220) },
	Ghost = { Chance = 0.05, RateMult = 2.5, Tint = Color3.fromRGB(200, 220, 255) },
}

BrainrotData.MUTATION_ORDER = { "Golden", "Diamond", "Lava", "Rainbow", "Ghost" }

-- The cast: 15 original brainrots. Rate is the base $/s before rarity and
-- mutation multipliers. Body is the colour of the character's body part, and
-- Accent the colour of its head crest. Size is the body scale in studs.
BrainrotData.CHARACTERS = {
	{ Name = "Noodle Cat", Rarity = "Common", Rate = 2, Body = Color3.fromRGB(255, 210, 130), Accent = Color3.fromRGB(255, 150, 60), Size = 2.2 },
	{ Name = "Banana Shark", Rarity = "Common", Rate = 3, Body = Color3.fromRGB(255, 235, 90), Accent = Color3.fromRGB(120, 200, 255), Size = 2.4 },
	{ Name = "Soggy Croissant", Rarity = "Common", Rate = 4, Body = Color3.fromRGB(220, 170, 90), Accent = Color3.fromRGB(160, 110, 50), Size = 2.0 },
	{ Name = "Turbo Toaster", Rarity = "Rare", Rate = 8, Body = Color3.fromRGB(200, 200, 210), Accent = Color3.fromRGB(255, 80, 80), Size = 2.4 },
	{ Name = "Disco Pickle", Rarity = "Rare", Rate = 10, Body = Color3.fromRGB(90, 200, 90), Accent = Color3.fromRGB(255, 80, 220), Size = 2.2 },
	{ Name = "Captain Crumb", Rarity = "Rare", Rate = 12, Body = Color3.fromRGB(180, 130, 70), Accent = Color3.fromRGB(255, 215, 0), Size = 2.6 },
	{ Name = "Sir Barksalot", Rarity = "Epic", Rate = 22, Body = Color3.fromRGB(150, 100, 60), Accent = Color3.fromRGB(255, 220, 150), Size = 2.8 },
	{ Name = "Madame Marshmallow", Rarity = "Epic", Rate = 26, Body = Color3.fromRGB(255, 240, 245), Accent = Color3.fromRGB(255, 150, 200), Size = 2.6 },
	{ Name = "The Grumpy Gnome", Rarity = "Epic", Rate = 30, Body = Color3.fromRGB(90, 130, 200), Accent = Color3.fromRGB(255, 60, 60), Size = 2.4 },
	{ Name = "Lord Lava Lamp", Rarity = "Legendary", Rate = 55, Body = Color3.fromRGB(255, 120, 40), Accent = Color3.fromRGB(255, 220, 80), Size = 3.0 },
	{ Name = "Queen Quokka", Rarity = "Legendary", Rate = 65, Body = Color3.fromRGB(190, 140, 90), Accent = Color3.fromRGB(255, 190, 220), Size = 2.8 },
	{ Name = "Doctor Donut", Rarity = "Legendary", Rate = 75, Body = Color3.fromRGB(255, 170, 200), Accent = Color3.fromRGB(255, 255, 255), Size = 3.0 },
	{ Name = "Emperor Eggplant", Rarity = "Mythic", Rate = 140, Body = Color3.fromRGB(120, 60, 180), Accent = Color3.fromRGB(255, 215, 0), Size = 3.4 },
	{ Name = "The Invisible Sandwich", Rarity = "Mythic", Rate = 170, Body = Color3.fromRGB(230, 210, 170), Accent = Color3.fromRGB(140, 220, 255), Size = 3.2 },
	{ Name = "Golden Goblin King", Rarity = "Secret", Rate = 350, Body = Color3.fromRGB(255, 200, 40), Accent = Color3.fromRGB(255, 240, 160), Size = 3.6 },
}

-- A brainrot's buy price: its $/s times 25, so a better earner always costs
-- more, and a Secret costs a fortune.
function BrainrotData.priceOf(character, mutationName)
	local rarity = BrainrotData.RARITIES[character.Rarity]
	local mutation = BrainrotData.MUTATIONS[mutationName or "None"] or BrainrotData.MUTATIONS.None
	local rate = character.Rate * rarity.RateMult * mutation.RateMult
	return math.floor(rate * 25 + 0.5), rate
end

-- Roll a rarity by weight, then pick a character of that rarity at random.
function BrainrotData.rollCharacter()
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
		total += BrainrotData.RARITIES[rarity].Weight
	end
	local roll = math.random() * total
	local picked = "Common"
	for _, rarity in ipairs(BrainrotData.RARITY_ORDER) do
		roll -= BrainrotData.RARITIES[rarity].Weight
		if roll <= 0 then
			picked = rarity
			break
		end
	end
	local pool = {}
	for _, character in ipairs(BrainrotData.CHARACTERS) do
		if character.Rarity == picked then
			table.insert(pool, character)
		end
	end
	return pool[math.random(1, #pool)]
end

-- Roll a mutation. Most spawns are plain; a lucky few come mutated.
function BrainrotData.rollMutation()
	local roll = math.random()
	local running = 0
	for _, name in ipairs(BrainrotData.MUTATION_ORDER) do
		running += BrainrotData.MUTATIONS[name].Chance
		if roll <= running then
			return name
		end
	end
	return "None"
end

-- The shop: five upgrades, each bought with money, each with a level cap.
-- Cost grows with the level already owned.
BrainrotData.SHOP = {
	{ Id = "SpeedCoil", Name = "Speed Coil", Desc = "+6 walk speed per level", BaseCost = 150, CostMult = 1.8, MaxLevel = 3 },
	{ Id = "SlapPower", Name = "Slap Power", Desc = "Slap knocks players further", BaseCost = 200, CostMult = 1.8, MaxLevel = 3 },
	{ Id = "MoneyMagnet", Name = "Money Magnet", Desc = "+10% earnings per level", BaseCost = 500, CostMult = 2.2, MaxLevel = 5 },
	{ Id = "BaseShield", Name = "Base Shield", Desc = "+15s lock time per level", BaseCost = 300, CostMult = 2.0, MaxLevel = 3 },
	{ Id = "QuickHands", Name = "Quick Hands", Desc = "Steal and lock 20% faster", BaseCost = 400, CostMult = 2.0, MaxLevel = 2 },
}

function BrainrotData.shopCost(item, levelOwned)
	return math.floor(item.BaseCost * (item.CostMult ^ levelOwned) + 0.5)
end

-- Rebirth: costs 10,000 times the square of the next rebirth number, and
-- every rebirth adds +25% to all earnings, forever.
function BrainrotData.rebirthCost(rebirths)
	return 10000 * (rebirths + 1) * (rebirths + 1)
end

function BrainrotData.rebirthMult(rebirths)
	return 1 + 0.25 * rebirths
end

-- The island's tuning, in one place so the server and client agree on it.
BrainrotData.TUNING = {
	BeltLength = 140, -- studs, from the spawn arch to the despawn gate
	BeltSpeed = 6, -- studs per second along the belt
	BeltY = 3, -- the belt bed's top surface
	SpawnEvery = 4, -- seconds between brainrot spawns
	MaxBelt = 8, -- brainrots riding the belt at once
	BaseStands = 5, -- brainrot stands on each base
	BuyRange = 10, -- studs: how close to a belt brainrot to buy it (E)
	StealRange = 10, -- studs: how close to a base brainrot to steal it (E)
	SlapRange = 9, -- studs: how close to slap someone (Q)
	SlapCooldown = 3, -- seconds between slaps
	LockSeconds = 30, -- base lock length
	LockCooldown = 60, -- seconds between locks
	TsunamiEvery = 180, -- seconds between tsunamis
	TsunamiWarn = 10, -- seconds of warning before the wave
	CarrySpeed = 14, -- walk speed while carrying a stolen brainrot
}

-- The eight bases, in a ring around the island. Angle is in degrees around
-- the centre; Colour is the base's colour; Name is shown on its flag.
BrainrotData.BASES = {
	{ Name = "Coral", Colour = Color3.fromRGB(255, 110, 110), Angle = 0 },
	{ Name = "Sunny", Colour = Color3.fromRGB(255, 210, 70), Angle = 45 },
	{ Name = "Lime", Colour = Color3.fromRGB(140, 220, 90), Angle = 90 },
	{ Name = "Aqua", Colour = Color3.fromRGB(70, 200, 220), Angle = 135 },
	{ Name = "Berry", Colour = Color3.fromRGB(190, 100, 255), Angle = 180 },
	{ Name = "Bubblegum", Colour = Color3.fromRGB(255, 130, 200), Angle = 225 },
	{ Name = "Tangerine", Colour = Color3.fromRGB(255, 150, 50), Angle = 270 },
	{ Name = "Mint", Colour = Color3.fromRGB(90, 230, 180), Angle = 315 },
}

return BrainrotData
