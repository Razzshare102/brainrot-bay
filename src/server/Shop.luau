-- Brainrot Bay: the shop. Five one-time upgrades (the extra slot can be
-- bought twice). The server checks the price and whether the player already
-- owns it, so the client can never buy the same upgrade twice for free.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Bases = require(script.Parent.Bases)

local Shop = {}

function Shop.tryBuy(player, itemId)
	local item = GameConfig.findShopItem(itemId)
	if not item then
		return false, "No such shop item."
	end
	local owned = Bases.itemCount(player, itemId)
	if itemId == "slot" then
		if owned >= 2 then
			return false, "You already own two Extra Slots."
		end
	elseif owned >= 1 then
		return false, "You already own " .. item.name .. "."
	end
	if not Bases.charge(player, item.price) then
		return false, "Not enough cash for " .. item.name .. " ($" .. tostring(item.price) .. ")."
	end
	Bases.grantItem(player, itemId)
	return true, "Bought " .. item.name .. "!"
end

return Shop
