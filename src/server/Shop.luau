-- Brainrot Bay — the shop. Players spend the money their brainrots earn on
-- five upgrades. Each upgrade has levels, and each level costs more than the
-- last. Buying applies the effect at once where it has one (walk speed).

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local StealSystem = require(script.Parent:WaitForChild("StealSystem"))

local Shop = {}

local onEvent = nil -- (player, kind, text) -> nil; wired to the client notify RemoteEvent

function Shop.init(notifyCallback)
	onEvent = notifyCallback
end

local function findItem(itemId)
	for _, entry in ipairs(BrainrotData.SHOP) do
		if entry.Id == itemId then
			return entry
		end
	end
	return nil
end

-- Buy one level of a shop item. Returns a message for the client.
function Shop.buy(player, itemId)
	local item = findItem(itemId)
	if not item then
		return "Unknown item"
	end
	local level = StealSystem.getShopLevel(player, itemId)
	if level >= item.MaxLevel then
		return item.Name .. " is maxed out"
	end
	local cost = BrainrotData.shopCost(item, level)
	if StealSystem.getMoney(player) < cost then
		return "Not enough money: need $" .. tostring(cost)
	end
	StealSystem.addMoney(player, -cost)
	StealSystem.setShopLevel(player, itemId, level + 1)
	if itemId == "SpeedCoil" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and not StealSystem.isCarrying(player) then
				humanoid.WalkSpeed = 16 + 6 * StealSystem.getShopLevel(player, "SpeedCoil")
			end
		end
	end
	if onEvent then
		onEvent(player, "shop", "Bought " .. item.Name .. " level " .. tostring(level + 1))
	end
	return "Bought " .. item.Name .. "!"
end

-- The shop's full state for one player: each item, its level and next cost,
-- so the client can draw the shop window without doing the maths itself.
function Shop.stateFor(player)
	local state = {}
	for _, item in ipairs(BrainrotData.SHOP) do
		local level = StealSystem.getShopLevel(player, item.Id)
		table.insert(state, {
			Id = item.Id,
			Name = item.Name,
			Desc = item.Desc,
			Level = level,
			MaxLevel = item.MaxLevel,
			Cost = level < item.MaxLevel and BrainrotData.shopCost(item, level) or nil,
		})
	end
	return state
end

return Shop
