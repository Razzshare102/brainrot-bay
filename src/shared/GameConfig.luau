-- Brainrot Bay: the numbers every service agrees on. One table, so a
-- balance tweak is a one-line change and the client and server can never
-- disagree about what something costs or how long it lasts.

local GameConfig = {}

GameConfig.START_CASH = 100
GameConfig.BASE_SLOTS = 6
GameConfig.MAX_BASES = 8

-- The belt: a new character rolls in this often, and walks this fast.
GameConfig.BELT_SPAWN_SECONDS = 4
GameConfig.BELT_SPEED = 6
GameConfig.BELT_START_Z = -44
GameConfig.BELT_END_Z = 4
GameConfig.BELT_MAX_ON_BELT = 8

-- Money: how often the server pays out, and the rebirth deal.
GameConfig.EARN_TICK_SECONDS = 1
GameConfig.REBIRTH_COST = 25000
GameConfig.REBIRTH_BONUS = 0.25

-- Stealing and defence.
GameConfig.SLAP_COOLDOWN_SECONDS = 3
GameConfig.SLAP_RANGE = 12
GameConfig.SLAP_FLING = 55
GameConfig.CARRY_SECONDS = 25
GameConfig.LOCK_SECONDS = 30
GameConfig.LOCK_COOLDOWN_SECONDS = 60
GameConfig.STEAL_RANGE = 14

-- The tsunami: a wave every three minutes, ten seconds of warning first.
GameConfig.TSUNAMI_PERIOD_SECONDS = 180
GameConfig.TSUNAMI_WARNING_SECONDS = 10
GameConfig.TSUNAMI_FLING = 70

-- The shop. Each item can be bought once unless it says it stacks.
GameConfig.SHOP = {
	{ id = "sneakers", name = "Turbo Sneakers", desc = "+6 walk speed", price = 500 },
	{ id = "glove", name = "Slap Glove", desc = "Slaps fling twice as far", price = 750 },
	{ id = "slot", name = "Extra Base Slot", desc = "+2 brainrot slots", price = 2000 },
	{ id = "magnet", name = "Coin Magnet", desc = "+10% income", price = 1500 },
	{ id = "vault", name = "Money Vault", desc = "+25% income", price = 5000 },
}

function GameConfig.findShopItem(id)
	for _, item in ipairs(GameConfig.SHOP) do
		if item.id == id then
			return item
		end
	end
	return nil
end

-- The eight base colours, in ring order, matching the floors in the place.
GameConfig.BASE_COLORS = {
	Color3.fromRGB(255, 40, 40),
	Color3.fromRGB(40, 100, 255),
	Color3.fromRGB(40, 215, 65),
	Color3.fromRGB(255, 215, 25),
	Color3.fromRGB(155, 65, 230),
	Color3.fromRGB(255, 140, 25),
	Color3.fromRGB(255, 90, 180),
	Color3.fromRGB(25, 215, 230),
}

return GameConfig
