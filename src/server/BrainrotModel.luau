-- Brainrot Bay: turns a catalogue entry into a visible character. One
-- function builds the whole model — body, belly, eyes and the floating name
-- tag — so the belt and the bases always draw the same character.

local BrainrotModel = {}

local SHAPES = {
	blob = Vector3.new(3, 3, 3),
	tall = Vector3.new(2.4, 4, 2.4),
	wide = Vector3.new(4, 2.6, 2.6),
}

local function makePart(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- Half the body height, so a base can stand the model on a pad without
-- it sinking into the floor or floating above it.
function BrainrotModel.standHeight(character)
	local size = SHAPES[character.shape] or SHAPES.blob
	return size.Y / 2
end

-- Build a character model. uid is the model's name, so the client can find
-- it again; rate is shown on the tag so a buyer always sees what it earns.
function BrainrotModel.build(character, mutation, rate, uid)
	local model = Instance.new("Model")
	model.Name = uid

	local bodyColor = character.bodyColor
	if mutation.name ~= "Normal" then
		bodyColor = bodyColor:Lerp(mutation.color, 0.45)
	end
	local size = SHAPES[character.shape] or SHAPES.blob
	local body = makePart("Body", size, bodyColor, model)
	body.CanCollide = true

	local belly = makePart("Belly", Vector3.new(size.X * 0.55, size.Y * 0.55, 0.4), character.bellyColor, model)
	belly.CFrame = CFrame.new(0, -size.Y * 0.1, size.Z * 0.5 + 0.1)

	local eyeY = size.Y * 0.18
	local eyeX = size.X * 0.22
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(0.5, 0.7, 0.2), Color3.fromRGB(255, 255, 255), model)
		eye.CFrame = CFrame.new(eyeX * side, eyeY, size.Z * 0.5 + 0.05)
		local pupil = makePart("Pupil", Vector3.new(0.22, 0.35, 0.1), Color3.fromRGB(20, 20, 20), model)
		pupil.CFrame = CFrame.new(eyeX * side, eyeY - 0.05, size.Z * 0.5 + 0.16)
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(140, 64)
	tag.StudsOffset = Vector3.new(0, size.Y * 0.5 + 1.6, 0)
	tag.AlwaysOnTop = true
	tag.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = tag

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.fromScale(0, 0.4)
	rarityLabel.Size = UDim2.fromScale(1, 0.3)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = character.rarity .. "  •  " .. mutation.name
	rarityLabel.TextColor3 = mutation.color
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextStrokeTransparency = 0.4
	rarityLabel.Parent = tag

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.fromScale(0, 0.7)
	rateLabel.Size = UDim2.fromScale(1, 0.3)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. tostring(rate) .. " /s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.Parent = tag

	model.PrimaryPart = body
	return model
end

return BrainrotModel
