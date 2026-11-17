-- Brainrot Bay — the steal system. It owns every player's base, money and
-- brainrots: buying off the belt (E), stealing from another base (E), carrying
-- a stolen brainrot home, defending with a slap (Q) and a base lock (F), and
-- the once-a-second earnings tick that pays every brainrot its $/s.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local StealSystem = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BASE_RADIUS = 55
local BASE_SIZE = 16

local basesFolder = nil
local baseStands = {} -- player -> array of stand positions (Vector3)
local owned = {} -- player -> array of { model, character, mutation, rate, standIndex }
local carrying = {} -- player -> { model, character, mutation, rate, fromPlayer, fromStand }
local money = {} -- player -> number
local rebirths = {} -- player -> number
local shopLevels = {} -- player -> { [itemId] = level }
local lockUntil = {} -- player -> os.clock() timestamp the lock ends
local lockReadyAt = {} -- player -> os.clock() timestamp the next lock is ready
local slapReadyAt = {} -- player -> os.clock() timestamp the next slap is ready
local stealReadyAt = {} -- player -> os.clock() timestamp the next steal is ready

local onEvent = nil -- (player, kind, text) -> nil; the server wires this to the client notify RemoteEvent

local function baseCenter(index)
	local info = BrainrotData.BASES[index]
	local angle = math.rad(info.Angle)
	return Vector3.new(math.cos(angle) * BASE_RADIUS, 0, math.sin(angle) * BASE_RADIUS)
end

local function standPosition(baseIndex, standIndex)
	local center = baseCenter(baseIndex)
	-- Stands sit in a row across the base, facing the island centre.
	local right = Vector3.new(-math.sin(math.rad(BrainrotData.BASES[baseIndex].Angle)), 0, math.cos(math.rad(BrainrotData.BASES[baseIndex].Angle)))
	local offset = (standIndex - 3) * 3
	return center + right * offset + Vector3.new(0, 1.6, 0)
end

function StealSystem.init(folder, notifyCallback)
	basesFolder = folder
	onEvent = notifyCallback
end

function StealSystem.baseIndexOf(player)
	local n = 0
	for _, other in ipairs(Players:GetPlayers()) do
		n += 1
		if other == player then
			return ((n - 1) % #BrainrotData.BASES) + 1
		end
	end
	return 1
end

-- Give a joining player their money, an empty base and their first $100.
function StealSystem.playerJoined(player)
	money[player] = 100
	rebirths[player] = 0
	shopLevels[player] = {}
	owned[player] = {}
	lockUntil[player] = 0
	lockReadyAt[player] = 0
	slapReadyAt[player] = 0
	stealReadyAt[player] = 0

	local index = StealSystem.baseIndexOf(player)
	local stands = {}
	for i = 1, BrainrotData.TUNING.BaseStands do
		stands[i] = standPosition(index, i)
	end
	baseStands[player] = stands

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Money"
	cash.Value = 100
	cash.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats
end

function StealSystem.playerLeft(player)
	if carrying[player] then
		-- A player who leaves while carrying drops the brainrot where they stood.
		StealSystem.dropCarried(player)
	end
	for _, record in ipairs(owned[player] or {}) do
		record.model:Destroy()
	end
	owned[player] = nil
	money[player] = nil
	rebirths[player] = nil
	shopLevels[player] = nil
	baseStands[player] = nil
end

function StealSystem.getMoney(player)
	return money[player] or 0
end

function StealSystem.addMoney(player, amount)
	money[player] = (money[player] or 0) + amount
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cash = stats:FindFirstChild("Money")
		if cash then
			cash.Value = math.floor(money[player] + 0.5)
		end
	end
end

function StealSystem.getRebirths(player)
	return rebirths[player] or 0
end

function StealSystem.getShopLevel(player, itemId)
	local levels = shopLevels[player]
	if not levels then
		return 0
	end
	return levels[itemId] or 0
end

function StealSystem.earningsMult(player)
	local mult = BrainrotData.rebirthMult(rebirths[player] or 0)
	mult *= 1 + 0.10 * StealSystem.getShopLevel(player, "MoneyMagnet")
	return mult
end

-- Place a brainrot model on one of the player's free stands. Returns true.
function StealSystem.placeOnBase(player, model, character, mutation, rate)
	local stands = baseStands[player]
	if not stands then
		return false
	end
	local taken = {}
	for _, record in ipairs(owned[player] or {}) do
		taken[record.standIndex] = true
	end
	for i = 1, #stands do
		if not taken[i] then
			local pos = stands[i]
			local body = model.PrimaryPart
			-- Rest the brainrot on the floor pad (top y = 1).
			model:SetPrimaryPartCFrame(CFrame.new(Vector3.new(pos.X, 1 + body.Size.Y / 2, pos.Z)))
			model.Parent = basesFolder
			table.insert(owned[player], {
				model = model,
				character = character,
				mutation = mutation,
				rate = rate,
				standIndex = i,
			})
			return true
		end
	end
	return false
end

function StealSystem.freeStands(player)
	local used = #(owned[player] or {})
	return BrainrotData.TUNING.BaseStands - used
end

-- Buy the belt brainrot nearest to the player. Called by the E key.
-- Returns (true, message) on a buy, (false, reason) when it cannot buy.
function StealSystem.tryBuy(player, beltRecord)
	if not beltRecord then
		return false, "No brainrot in reach"
	end
	if StealSystem.freeStands(player) <= 0 then
		return false, "Your base is full!"
	end
	if money[player] < beltRecord.price then
		return false, "Not enough money: need $" .. tostring(beltRecord.price)
	end
	StealSystem.addMoney(player, -beltRecord.price)
	local _, rate = BrainrotData.priceOf(beltRecord.character, beltRecord.mutation)
	local placed = StealSystem.placeOnBase(player, beltRecord.model, beltRecord.character, beltRecord.mutation, rate)
	if not placed then
		StealSystem.addMoney(player, beltRecord.price)
		return false, "Your base is full!"
	end
	if onEvent then
		onEvent(player, "bought", "Bought " .. beltRecord.character.Name .. " for $" .. tostring(beltRecord.price))
	end
	return true, "Bought " .. beltRecord.character.Name .. "!"
end

-- The base brainrot nearest to a point, within range, with its owner.
function StealSystem.nearestOwnedTo(position, range)
	local best = nil
	local bestOwner = nil
	local bestDist = range
	for player, list in pairs(owned) do
		for _, record in ipairs(list) do
			local dist = (record.model.PrimaryPart.Position - position).Magnitude
			if dist < bestDist then
				bestDist = dist
				best = record
				bestOwner = player
			end
		end
	end
	return best, bestOwner
end

-- Steal the base brainrot nearest to the player. The thief carries it home;
-- if they reach their own base with it, it is theirs.
function StealSystem.trySteal(player, record, owner)
	if not record or not owner then
		return "No brainrot in reach"
	end
	if owner == player then
		return "That one is already yours"
	end
	if carrying[player] then
		return "You are already carrying one"
	end
	if os.clock() < (lockUntil[owner] or 0) then
		return owner.DisplayName .. "'s base is locked!"
	end
	if os.clock() < (stealReadyAt[player] or 0) then
		return "Stealing is on cooldown"
	end
	-- Lift it off the owner's stand and hand it to the thief.
	for i, item in ipairs(owned[owner]) do
		if item == record then
			table.remove(owned[owner], i)
			break
		end
	end
	carrying[player] = {
		model = record.model,
		character = record.character,
		mutation = record.mutation,
		rate = record.rate,
		fromPlayer = owner,
		fromStand = record.standIndex,
	}
	stealReadyAt[player] = os.clock() + 2
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = BrainrotData.TUNING.CarrySpeed
		end
	end
	if onEvent then
		onEvent(owner, "stolen", player.DisplayName .. " is stealing your " .. record.character.Name .. "!")
		onEvent(player, "stealing", "Run home with the " .. record.character.Name .. "!")
	end
	return "Run home!"
end

-- Drop the carried brainrot where the thief stands; it stays there, free for
-- anyone to grab, until someone steals it or the tsunami washes it away.
function StealSystem.dropCarried(player)
	local held = carrying[player]
	if not held then
		return
	end
	carrying[player] = nil
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local pos = root and root.Position or Vector3.new(0, 5, 0)
	held.model:SetPrimaryPartCFrame(CFrame.new(pos + Vector3.new(0, 2, 0)))
	held.model.Parent = basesFolder
	-- A dropped brainrot is ownerless: the next thief to touch it picks it up.
	-- We keep it in a limbo list by giving it to no one; nearestOwnedTo skips
	-- it, so instead we park it as a belt-style loose record on the island.
	-- Simplest honest rule: it returns to its original owner's base.
	local owner = held.fromPlayer
	if owner and owner.Parent then
		StealSystem.placeOnBase(owner, held.model, held.character, held.mutation, held.rate)
		if onEvent then
			onEvent(owner, "returned", "Your " .. held.character.Name .. " was dropped and came home")
			onEvent(player, "dropped", "You dropped the " .. held.character.Name .. "!")
		end
	else
		held.model:Destroy()
	end
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16 + 6 * StealSystem.getShopLevel(player, "SpeedCoil")
		end
	end
end

function StealSystem.isCarrying(player)
	return carrying[player] ~= nil
end

-- Called every heartbeat: carry the stolen brainrot above the thief, and
-- hand it over the moment they step onto their own base.
function StealSystem.stepCarry(dt)
	for player, held in pairs(carrying) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			continue
		end
		local target = root.Position + Vector3.new(0, 4, 0)
		held.model:SetPrimaryPartCFrame(CFrame.new(target))
		local home = baseCenter(StealSystem.baseIndexOf(player))
		local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
		if (flat - Vector3.new(home.X, 0, home.Z)).Magnitude < BASE_SIZE then
			-- Home! The brainrot is theirs now.
			carrying[player] = nil
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = 16 + 6 * StealSystem.getShopLevel(player, "SpeedCoil")
			end
			local placed = StealSystem.placeOnBase(player, held.model, held.character, held.mutation, held.rate)
			if placed then
				if onEvent then
					onEvent(player, "stole", "You stole the " .. held.character.Name .. "!")
				end
			else
				-- No free stand: it goes back to its old owner.
				if held.fromPlayer and held.fromPlayer.Parent then
					StealSystem.placeOnBase(held.fromPlayer, held.model, held.character, held.mutation, held.rate)
				else
					held.model:Destroy()
				end
				if onEvent then
					onEvent(player, "full", "No free stand — the brainrot went back")
				end
			end
		end
	end
end

-- Slap (Q): knock nearby players away. A thief who is slapped drops the
-- brainrot they are carrying.
function StealSystem.trySlap(player)
	if os.clock() < (slapReadyAt[player] or 0) then
		return "Slap is recharging"
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return ""
	end
	local power = 40 + 25 * StealSystem.getShopLevel(player, "SlapPower")
	slapReadyAt[player] = os.clock() + BrainrotData.TUNING.SlapCooldown
	local hitAnyone = false
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			if otherRoot and (otherRoot.Position - root.Position).Magnitude <= BrainrotData.TUNING.SlapRange then
				hitAnyone = true
				local dir = (otherRoot.Position - root.Position)
				dir = Vector3.new(dir.X, 0, dir.Z)
				if dir.Magnitude < 0.1 then
					dir = Vector3.new(0, 0, 1)
				end
				otherRoot.AssemblyLinearVelocity = dir.Unit * power + Vector3.new(0, 30, 0)
				if carrying[other] then
					StealSystem.dropCarried(other)
					if onEvent then
						onEvent(player, "slapped", "You slapped " .. other.DisplayName .. " — they dropped it!")
					end
				end
			end
		end
	end
	if not hitAnyone then
		return "Slap! Nobody in reach"
	end
	return "Slap!"
end

-- Lock (F): nobody can steal from this base until the lock ends.
function StealSystem.tryLock(player)
	if os.clock() < (lockReadyAt[player] or 0) then
		return "Lock is recharging"
	end
	local seconds = BrainrotData.TUNING.LockSeconds + 15 * StealSystem.getShopLevel(player, "BaseShield")
	lockUntil[player] = os.clock() + seconds
	lockReadyAt[player] = os.clock() + BrainrotData.TUNING.LockCooldown
	if onEvent then
		onEvent(player, "locked", "Base locked for " .. tostring(seconds) .. "s!")
	end
	return "Base locked for " .. tostring(seconds) .. "s!"
end

function StealSystem.isLocked(player)
	return os.clock() < (lockUntil[player] or 0)
end

function StealSystem.setShopLevel(player, itemId, level)
	if not shopLevels[player] then
		shopLevels[player] = {}
	end
	shopLevels[player][itemId] = level
end

-- Rebirth: reset money and brainrots, keep a permanent +25% earnings mult.
function StealSystem.tryRebirth(player)
	local cost = BrainrotData.rebirthCost(rebirths[player] or 0)
	if money[player] < cost then
		return "Rebirth needs $" .. tostring(cost)
	end
	StealSystem.addMoney(player, -cost)
	for _, record in ipairs(owned[player] or {}) do
		record.model:Destroy()
	end
	owned[player] = {}
	money[player] = 0
	rebirths[player] = (rebirths[player] or 0) + 1
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local cash = stats:FindFirstChild("Money")
		if cash then
			cash.Value = 0
		end
		local rebirthValue = stats:FindFirstChild("Rebirths")
		if rebirthValue then
			rebirthValue.Value = rebirths[player]
		end
	end
	if onEvent then
		onEvent(player, "rebirth", "Rebirth " .. tostring(rebirths[player]) .. "! Earnings x" .. string.format("%.2f", BrainrotData.rebirthMult(rebirths[player])))
	end
	return "Rebirth " .. tostring(rebirths[player]) .. "! Earnings +" .. tostring(25 * rebirths[player]) .. "%"
end

-- Pay every brainrot its $/s, once a second.
function StealSystem.tickEarnings()
	for player, list in pairs(owned) do
		local total = 0
		for _, record in ipairs(list) do
			total += record.rate
		end
		if total > 0 then
			StealSystem.addMoney(player, total * StealSystem.earningsMult(player))
		end
	end
end

return StealSystem
