-- Brainrot Bay: the conveyor belt. Characters roll in at the north gate,
-- ride south past the buyers, and fall off the end if nobody wants them.
-- The belt owns every brainrot on it until one is bought or despawns.

local BrainrotCatalog = require(game:GetService("ReplicatedStorage").Shared.BrainrotCatalog)
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local BrainrotModel = require(script.Parent.BrainrotModel)
local Bases = require(script.Parent.Bases)

local Belt = {}

local folder = nil
local active = {}
local nextUid = 1

local function beltPosition(z)
	return Vector3.new(0, 4.6, z)
end

local function spawnOne()
	if #active >= GameConfig.BELT_MAX_ON_BELT then
		return
	end
	local character, mutation = BrainrotCatalog.rollSpawn()
	local rate = BrainrotCatalog.rateOf(character, mutation)
	local uid = "belt_" .. tostring(nextUid)
	nextUid += 1
	local model = BrainrotModel.build(character, mutation, rate, uid)
	model:PivotTo(CFrame.new(beltPosition(GameConfig.BELT_START_Z)))
	model.Parent = folder
	table.insert(active, {
		uid = uid,
		character = character,
		mutation = mutation,
		rate = rate,
		price = character.price,
		model = model,
		z = GameConfig.BELT_START_Z,
	})
end

-- The brainrot nearest the end of the belt: the one the BUY button sells.
function Belt.front()
	local best = nil
	for _, entry in ipairs(active) do
		if not best or entry.z > best.z then
			best = entry
		end
	end
	return best
end

function Belt.list()
	local out = {}
	for _, entry in ipairs(active) do
		table.insert(out, {
			uid = entry.uid,
			name = entry.character.name,
			rarity = entry.character.rarity,
			mutation = entry.mutation.name,
			rate = entry.rate,
			price = entry.price,
		})
	end
	return out
end

-- A player buys the front brainrot. The server checks the buyer is standing
-- by the belt, can afford it and has a free slot; then the model rides to
-- the buyer's base instead of off the end of the belt.
function Belt.tryBuy(player)
	local root = Belt.characterRoot(player)
	if not root then
		return false, "No character yet."
	end
	local pos = root.Position
	if math.abs(pos.X) > 16 or pos.Z < -48 or pos.Z > 10 then
		return false, "Stand next to the belt to buy."
	end
	local entry = Belt.front()
	if not entry then
		return false, "The belt is empty right now."
	end
	if Bases.getCash(player) < entry.price then
		return false, "Not enough cash for " .. entry.character.name .. "."
	end
	if not Bases.hasFreeSlot(player) then
		return false, "Your base is full. Buy an Extra Slot in the shop."
	end
	for i, item in ipairs(active) do
		if item.uid == entry.uid then
			table.remove(active, i)
			break
		end
	end
	Bases.charge(player, entry.price)
	local ok, message = Bases.placeOwned(player, entry, entry.model)
	if not ok then
		Bases.addCash(player, entry.price)
		entry.model:Destroy()
		return false, message
	end
	return true, "Bought " .. entry.character.name .. " for $" .. tostring(entry.price) .. "!"
end

function Belt.characterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

function Belt.init()
	folder = Instance.new("Folder")
	folder.Name = "BeltBrainrots"
	folder.Parent = workspace
	task.spawn(function()
		while true do
			task.wait(GameConfig.BELT_SPAWN_SECONDS)
			spawnOne()
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			local step = GameConfig.BELT_SPEED * 0.1
			for i = #active, 1, -1 do
				local entry = active[i]
				entry.z += step
				if entry.z > GameConfig.BELT_END_Z then
					entry.model:Destroy()
					table.remove(active, i)
				else
					entry.model:PivotTo(CFrame.new(beltPosition(entry.z)))
				end
			end
		end
	end)
end

return Belt
