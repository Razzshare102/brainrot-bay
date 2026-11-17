-- Brainrot Bay: bases, money and ownership. Every player's cash, brainrots,
-- shop items, rebirths and base lock live in one table here, so no other
-- service ever has to guess what a player owns.

local BrainrotCatalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local BrainrotModel = require(script.Parent.BrainrotModel)

local Bases = {}

local states = {}
local usedBases = {}
local folder = nil

-- Base centres and pad spots, matching the floors in default.project.json.
local BASE_CENTERS = {
	Vector3.new(0, 3, -48),
	Vector3.new(33.94, 3, -33.94),
	Vector3.new(48, 3, 0),
	Vector3.new(33.94, 3, 33.94),
	Vector3.new(0, 3, 48),
	Vector3.new(-33.94, 3, 33.94),
	Vector3.new(-48, 3, 0),
	Vector3.new(-33.94, 3, -33.94),
}

local PAD_SPOTS = {
	{ Vector3.new(-4, 3.4, -45), Vector3.new(0, 3.4, -45), Vector3.new(4, 3.4, -45), Vector3.new(-4, 3.4, -51), Vector3.new(0, 3.4, -51), Vector3.new(4, 3.4, -51) },
	{ Vector3.new(28.99, 3.4, -34.65), Vector3.new(31.82, 3.4, -31.82), Vector3.new(34.65, 3.4, -28.99), Vector3.new(33.23, 3.4, -38.89), Vector3.new(36.06, 3.4, -36.06), Vector3.new(38.89, 3.4, -33.23) },
	{ Vector3.new(45, 3.4, -4), Vector3.new(45, 3.4, 0), Vector3.new(45, 3.4, 4), Vector3.new(51, 3.4, -4), Vector3.new(51, 3.4, 0), Vector3.new(51, 3.4, 4) },
	{ Vector3.new(34.65, 3.4, 28.99), Vector3.new(31.82, 3.4, 31.82), Vector3.new(28.99, 3.4, 34.65), Vector3.new(38.89, 3.4, 33.23), Vector3.new(36.06, 3.4, 36.06), Vector3.new(33.23, 3.4, 38.89) },
	{ Vector3.new(4, 3.4, 45), Vector3.new(0, 3.4, 45), Vector3.new(-4, 3.4, 45), Vector3.new(4, 3.4, 51), Vector3.new(0, 3.4, 51), Vector3.new(-4, 3.4, 51) },
	{ Vector3.new(-28.99, 3.4, 34.65), Vector3.new(-31.82, 3.4, 31.82), Vector3.new(-34.65, 3.4, 28.99), Vector3.new(-33.23, 3.4, 38.89), Vector3.new(-36.06, 3.4, 36.06), Vector3.new(-38.89, 3.4, 33.23) },
	{ Vector3.new(-45, 3.4, 4), Vector3.new(-45, 3.4, 0), Vector3.new(-45, 3.4, -4), Vector3.new(-51, 3.4, 4), Vector3.new(-51, 3.4, 0), Vector3.new(-51, 3.4, -4) },
	{ Vector3.new(-34.65, 3.4, -28.99), Vector3.new(-31.82, 3.4, -31.82), Vector3.new(-28.99, 3.4, -34.65), Vector3.new(-38.89, 3.4, -33.23), Vector3.new(-36.06, 3.4, -36.06), Vector3.new(-33.23, 3.4, -38.89) },
}

function Bases.getState(player)
	return states[player]
end

function Bases.getCash(player)
	local state = states[player]
	return state and state.cash or 0
end

function Bases.addCash(player, amount)
	local state = states[player]
	if state then
		state.cash += amount
	end
end

function Bases.charge(player, amount)
	local state = states[player]
	if not state or state.cash < amount then
		return false
	end
	state.cash -= amount
	return true
end

function Bases.baseCenter(index)
	return BASE_CENTERS[index]
end

function Bases.slotsOf(state)
	return GameConfig.BASE_SLOTS + 2 * (state.shopOwned.slot or 0)
end

function Bases.hasFreeSlot(player)
	local state = states[player]
	if not state then
		return false
	end
	return #state.owned < Bases.slotsOf(state)
end

function Bases.incomeOf(state)
	local base = 0
	for _, entry in ipairs(state.owned) do
		base += entry.rate
	end
	local shopBonus = 0.10 * (state.shopOwned.magnet or 0) + 0.25 * (state.shopOwned.vault or 0)
	return math.floor(base * (1 + state.rebirths * GameConfig.REBIRTH_BONUS) * (1 + shopBonus) + 0.5)
end

function Bases.itemCount(player, id)
	local state = states[player]
	return state and (state.shopOwned[id] or 0) or 0
end

function Bases.grantItem(player, id)
	local state = states[player]
	if not state then
		return
	end
	state.shopOwned[id] = (state.shopOwned[id] or 0) + 1
	if id == "sneakers" then
		local humanoid = Bases.findHumanoid(player)
		if humanoid then
			humanoid.WalkSpeed = 22
		end
	end
end

function Bases.findHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid") or nil
end

function Bases.isLocked(player)
	local state = states[player]
	return state and os.clock() < state.lockUntil or false
end

function Bases.lockSecondsLeft(player)
	local state = states[player]
	if not state then
		return 0
	end
	return math.max(0, state.lockUntil - os.clock())
end

function Bases.tryLock(player)
	local state = states[player]
	if not state then
		return false, "No base yet."
	end
	local now = os.clock()
	if now < state.lockReadyAt then
		return false, "Lock recharging: " .. tostring(math.ceil(state.lockReadyAt - now)) .. "s left."
	end
	state.lockUntil = now + GameConfig.LOCK_SECONDS
	state.lockReadyAt = now + GameConfig.LOCK_SECONDS + GameConfig.LOCK_COOLDOWN_SECONDS
	return true, "Base locked for " .. tostring(GameConfig.LOCK_SECONDS) .. " seconds!"
end

function Bases.tryRebirth(player)
	local state = states[player]
	if not state then
		return false, "No base yet."
	end
	if state.cash < GameConfig.REBIRTH_COST then
		return false, "Rebirth costs $" .. tostring(GameConfig.REBIRTH_COST) .. "."
	end
	state.cash = GameConfig.START_CASH
	state.rebirths += 1
	return true, "Rebirth " .. tostring(state.rebirths) .. "! All income +" .. tostring(math.floor(state.rebirths * GameConfig.REBIRTH_BONUS * 100 + 0.5)) .. "%."
end

-- Put a brainrot model on the player's first free pad and record it.
function Bases.placeOwned(player, entry, model)
	local state = states[player]
	if not state then
		return false, "No base yet."
	end
	local taken = {}
	for _, owned in ipairs(state.owned) do
		taken[owned.padIndex] = true
	end
	local padIndex = nil
	for i = 1, GameConfig.BASE_SLOTS do
		if not taken[i] then
			padIndex = i
			break
		end
	end
	if not padIndex then
		return false, "Your base is full."
	end
	local spot = PAD_SPOTS[state.baseIndex][padIndex]
	local character = entry.character or BrainrotCatalog.findCharacter(entry.characterId)
	local mutationName = entry.mutationName or (type(entry.mutation) == "table" and entry.mutation.name or entry.mutation)
	local height = BrainrotModel.standHeight(character)
	model:PivotTo(CFrame.new(spot + Vector3.new(0, height, 0)))
	model.Parent = folder
	table.insert(state.owned, {
		uid = entry.uid,
		characterId = character.id,
		name = entry.name or character.name,
		rarity = entry.rarity or character.rarity,
		mutation = mutationName,
		rate = entry.rate,
		padIndex = padIndex,
		model = model,
	})
	return true, "Placed on your base."
end

-- Take one owned brainrot off a base (for stealing). Returns entry + model.
function Bases.takeOwned(player, uid)
	local state = states[player]
	if not state then
		return nil, nil
	end
	for i, owned in ipairs(state.owned) do
		if owned.uid == uid then
			table.remove(state.owned, i)
			return owned, owned.model
		end
	end
	return nil, nil
end

function Bases.findOwned(uid)
	for player, state in pairs(states) do
		for _, owned in ipairs(state.owned) do
			if owned.uid == uid then
				return player, owned
			end
		end
	end
	return nil, nil
end

function Bases.snapshot(player, extra)
	local state = states[player]
	if not state then
		return nil
	end
	local owned = {}
	for _, entry in ipairs(state.owned) do
		table.insert(owned, {
			uid = entry.uid,
			name = entry.name,
			rarity = entry.rarity,
			mutation = entry.mutation,
			rate = entry.rate,
		})
	end
	local shopOwned = {}
	for id, count in pairs(state.shopOwned) do
		shopOwned[id] = count
	end
	local snap = {
		cash = state.cash,
		income = Bases.incomeOf(state),
		owned = owned,
		rebirths = state.rebirths,
		baseIndex = state.baseIndex,
		slotsUsed = #state.owned,
		slotsTotal = Bases.slotsOf(state),
		lockLeft = Bases.lockSecondsLeft(player),
		shopOwned = shopOwned,
	}
	if extra then
		for key, value in pairs(extra) do
			snap[key] = value
		end
	end
	return snap
end

local function setupPlayer(player)
	local baseIndex = nil
	for i = 1, GameConfig.MAX_BASES do
		if not usedBases[i] then
			baseIndex = i
			break
		end
	end
	if not baseIndex then
		return
	end
	usedBases[baseIndex] = player
	states[player] = {
		baseIndex = baseIndex,
		cash = GameConfig.START_CASH,
		owned = {},
		rebirths = 0,
		shopOwned = {},
		lockUntil = 0,
		lockReadyAt = 0,
	}
end

local function removePlayer(player)
	local state = states[player]
	if state then
		usedBases[state.baseIndex] = nil
		for _, owned in ipairs(state.owned) do
			if owned.model then
				owned.model:Destroy()
			end
		end
		states[player] = nil
	end
end

function Bases.init()
	folder = Instance.new("Folder")
	folder.Name = "PlacedBrainrots"
	folder.Parent = workspace
	local players = game:GetService("Players")
	players.PlayerAdded:Connect(setupPlayer)
	players.PlayerRemoving:Connect(removePlayer)
	for _, player in ipairs(players:GetPlayers()) do
		setupPlayer(player)
	end
	task.spawn(function()
		while true do
			task.wait(GameConfig.EARN_TICK_SECONDS)
			for player, state in pairs(states) do
				local income = Bases.incomeOf(state)
				if income > 0 then
					state.cash += income
				end
			end
		end
	end)
end

return Bases
