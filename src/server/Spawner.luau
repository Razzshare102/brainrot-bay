-- Brainrot Bay — the belt spawner. On a timer it rolls a character and a
-- mutation, builds the brainrot as a small Model of parts, and rides it along
-- the conveyor belt from the spawn arch to the despawn gate. A brainrot the
-- belt carries to the end is gone for good.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local Spawner = {}

local Workspace = game:GetService("Workspace")

local BELT_START_X = -BrainrotData.TUNING.BeltLength / 2
local BELT_END_X = BrainrotData.TUNING.BeltLength / 2

local beltFolder = nil
local beltBrainrots = {} -- array of { model, rate, price, character, mutation, id }
local nextId = 1
local spawnClock = 0

-- Build one brainrot as a Model: a body, a head crest, two eyes, and a
-- BillboardGui label that reads its name, rarity and $/s at a glance.
function Spawner.buildModel(character, mutationName, position)
	local mutation = BrainrotData.MUTATIONS[mutationName]
	local bodyColour = character.Body
	if mutation.Tint then
		bodyColour = mutation.Tint
	end

	local model = Instance.new("Model")
	model.Name = character.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(character.Size, character.Size, character.Size)
	body.Color = bodyColour
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Position = position
	body.Parent = model

	local crest = Instance.new("Part")
	crest.Name = "Crest"
	crest.Shape = Enum.PartType.Ball
	crest.Size = Vector3.new(character.Size * 0.55, character.Size * 0.55, character.Size * 0.55)
	crest.Color = character.Accent
	crest.Material = Enum.Material.Neon
	crest.Anchored = true
	crest.CanCollide = false
	crest.Position = position + Vector3.new(0, character.Size * 0.65, 0)
	crest.Parent = model

	local eyeLeft = Instance.new("Part")
	eyeLeft.Name = "EyeLeft"
	eyeLeft.Shape = Enum.PartType.Ball
	eyeLeft.Size = Vector3.new(character.Size * 0.22, character.Size * 0.22, character.Size * 0.22)
	eyeLeft.Color = Color3.fromRGB(20, 20, 20)
	eyeLeft.Material = Enum.Material.SmoothPlastic
	eyeLeft.Anchored = true
	eyeLeft.CanCollide = false
	eyeLeft.Position = position + Vector3.new(-character.Size * 0.22, character.Size * 0.12, character.Size * 0.48)
	eyeLeft.Parent = model

	local eyeRight = eyeLeft:Clone()
	eyeRight.Name = "EyeRight"
	eyeRight.Position = position + Vector3.new(character.Size * 0.22, character.Size * 0.12, character.Size * 0.48)
	eyeRight.Parent = model

	if mutationName == "Ghost" then
		for _, part in ipairs(model:GetChildren()) do
			if part:IsA("BasePart") then
				part.Transparency = 0.35
			end
		end
	end

	-- The label: name on top, rarity and $/s below, rarity coloured.
	local label = Instance.new("BillboardGui")
	label.Name = "BrainrotLabel"
	label.Size = UDim2.fromOffset(150, 64)
	label.StudsOffset = Vector3.new(0, character.Size * 0.9 + 1.2, 0)
	label.AlwaysOnTop = true
	label.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = label

	local _, rate = BrainrotData.priceOf(character, mutationName)
	local rateText = character.Rarity
	if mutationName ~= "None" and string.sub(character.Name, 1, #mutationName) ~= mutationName then
		rateText = mutationName .. " " .. rateText
	end
	rateText = rateText .. "  |  $" .. tostring(math.floor(rate + 0.5)) .. "/s"

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.fromScale(0, 0.5)
	rateLabel.Size = UDim2.fromScale(1, 0.5)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = rateText
	rateLabel.TextColor3 = BrainrotData.RARITIES[character.Rarity].Color
	rateLabel.TextStrokeTransparency = 0.2
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = label

	model.PrimaryPart = body
	return model
end

function Spawner.init(folder)
	beltFolder = folder
end

-- Spawn one brainrot at the start of the belt, if the belt has room.
function Spawner.spawnOne()
	if #beltBrainrots >= BrainrotData.TUNING.MaxBelt then
		return nil
	end
	local character = BrainrotData.rollCharacter()
	local mutation = BrainrotData.rollMutation()
	local price, _ = BrainrotData.priceOf(character, mutation)
	local position = Vector3.new(BELT_START_X, BrainrotData.TUNING.BeltY + character.Size / 2, 0)
	local model = Spawner.buildModel(character, mutation, position)
	model.Parent = beltFolder
	local record = {
		id = nextId,
		model = model,
		character = character,
		mutation = mutation,
		price = price,
	}
	nextId += 1
	table.insert(beltBrainrots, record)
	return record
end

-- The belt brainrot nearest to a point, within range, or nil.
function Spawner.nearestTo(position, range)
	local best = nil
	local bestDist = range
	for _, record in ipairs(beltBrainrots) do
		local dist = (record.model.PrimaryPart.Position - position).Magnitude
		if dist < bestDist then
			bestDist = dist
			best = record
		end
	end
	return best
end

-- Take a brainrot off the belt (bought). Returns the record, or nil.
function Spawner.take(id)
	for i, record in ipairs(beltBrainrots) do
		if record.id == id then
			table.remove(beltBrainrots, i)
			return record
		end
	end
	return nil
end

-- Wash every belt brainrot away (the tsunami does this).
function Spawner.clearAll()
	for _, record in ipairs(beltBrainrots) do
		record.model:Destroy()
	end
	beltBrainrots = {}
end

-- Step the belt: move every brainrot forward, despawn any that reaches the
-- gate, and spawn a fresh one on the timer.
function Spawner.step(dt)
	spawnClock += dt
	if spawnClock >= BrainrotData.TUNING.SpawnEvery then
		spawnClock = 0
		Spawner.spawnOne()
	end
	local step = BrainrotData.TUNING.BeltSpeed * dt
	for i = #beltBrainrots, 1, -1 do
		local record = beltBrainrots[i]
		local model = record.model
		if not model.Parent then
			table.remove(beltBrainrots, i)
		else
			local body = model.PrimaryPart
			body.CFrame = body.CFrame + Vector3.new(step, 0, 0)
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") and part ~= body then
					part.CFrame = part.CFrame + Vector3.new(step, 0, 0)
				end
			end
			if body.Position.X >= BELT_END_X then
				model:Destroy()
				table.remove(beltBrainrots, i)
			end
		end
	end
end

return Spawner
