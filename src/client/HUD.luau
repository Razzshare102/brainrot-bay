-- Brainrot Bay: the whole interface, built in code. Money top-right, the
-- wave clock top-centre, your base on the left, the shop on the right, and
-- the three actions along the bottom. Nothing sits in the top-left corner,
-- where Roblox puts its own menu buttons.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local HUD = {}

local DARK = Color3.fromRGB(20, 24, 40)
local PANEL = Color3.fromRGB(28, 32, 54)
local GREEN = Color3.fromRGB(70, 220, 110)
local GOLD = Color3.fromRGB(255, 205, 60)
local RED = Color3.fromRGB(235, 70, 70)
local WHITE = Color3.fromRGB(245, 245, 245)

local function commas(n)
	local text = tostring(math.floor(n))
	local out = ""
	while #text > 3 do
		out = "," .. string.sub(text, -3) .. out
		text = string.sub(text, 1, -4)
	end
	return text .. out
end

local function makeLabel(parent, name, text, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or WHITE
	label.TextSize = textSize
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makeButton(parent, name, text, position, size, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = color or PANEL
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = WHITE
	button.TextSize = 20
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	return button
end

local function makePanel(parent, name, position, size)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = DARK
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame
	return frame
end

-- Build the interface. callbacks: buy, slap, lock, shop(itemId), rebirth.
function HUD.build(callbacks)
	local player = game:GetService("Players").LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBayGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")

	local api = { rows = {}, shopRows = {} }

	local money = makePanel(gui, "MoneyPanel", UDim2.new(1, -276, 0, 16), UDim2.fromOffset(260, 100))
	api.cashLabel = makeLabel(money, "Cash", "$100", UDim2.fromOffset(14, 8), UDim2.fromOffset(232, 36), 30, GOLD)
	api.incomeLabel = makeLabel(money, "Income", "+$0 /s", UDim2.fromOffset(14, 46), UDim2.fromOffset(232, 24), 18, GREEN)
	api.rebirthLabel = makeLabel(money, "Rebirths", "Rebirths: 0", UDim2.fromOffset(14, 70), UDim2.fromOffset(232, 22), 16, WHITE)

	api.waveLabel = makeLabel(gui, "WaveClock", "Next tsunami: 3:00", UDim2.new(0.5, -150, 0, 16), UDim2.fromOffset(300, 34), 22, Color3.fromRGB(140, 210, 255))
	api.waveLabel.TextXAlignment = Enum.TextXAlignment.Center

	api.alertLabel = makeLabel(gui, "Alert", "TSUNAMI WARNING - GET TO HIGH GROUND!", UDim2.new(0.5, -240, 0, 56), UDim2.fromOffset(480, 40), 24, RED)
	api.alertLabel.TextXAlignment = Enum.TextXAlignment.Center
	api.alertLabel.Visible = false

	api.carryLabel = makeLabel(gui, "Carrying", "", UDim2.new(0.5, -210, 0.32, 0), UDim2.fromOffset(420, 40), 22, GOLD)
	api.carryLabel.TextXAlignment = Enum.TextXAlignment.Center
	api.carryLabel.Visible = false

	api.toastLabel = makeLabel(gui, "Toast", "", UDim2.new(0.5, -240, 0.42, 0), UDim2.fromOffset(480, 36), 20, WHITE)
	api.toastLabel.TextXAlignment = Enum.TextXAlignment.Center

	local base = makePanel(gui, "BasePanel", UDim2.new(0, 16, 0.5, -130), UDim2.fromOffset(250, 260))
	api.baseTitle = makeLabel(base, "Title", "MY BASE - 0/6", UDim2.fromOffset(12, 8), UDim2.fromOffset(226, 26), 18, GOLD)
	for i = 1, 8 do
		local row = makeLabel(base, "Row" .. tostring(i), "", UDim2.fromOffset(12, 38 + (i - 1) * 26), UDim2.fromOffset(226, 24), 15, WHITE)
		api.rows[i] = row
	end

	api.shopToggle = makeButton(gui, "ShopToggle", "SHOP", UDim2.new(1, -176, 0, 124), UDim2.fromOffset(160, 44), PANEL)
	local shop = makePanel(gui, "ShopPanel", UDim2.new(1, -296, 0.5, -160), UDim2.fromOffset(280, 320))
	shop.Visible = false
	api.shopPanel = shop
	makeLabel(shop, "Title", "SHOP", UDim2.fromOffset(12, 8), UDim2.fromOffset(256, 26), 18, GOLD)
	for i, item in ipairs(GameConfig.SHOP) do
		local y = 40 + (i - 1) * 54
		makeLabel(shop, "Name" .. tostring(i), item.name, UDim2.fromOffset(12, y), UDim2.fromOffset(170, 24), 16, WHITE)
		makeLabel(shop, "Desc" .. tostring(i), item.desc, UDim2.fromOffset(12, y + 24), UDim2.fromOffset(170, 22), 14, Color3.fromRGB(180, 180, 180))
		local buyButton = makeButton(shop, "Buy" .. tostring(i), "$" .. commas(item.price), UDim2.fromOffset(190, y + 6), UDim2.fromOffset(78, 38), GREEN)
		buyButton.TextColor3 = Color3.fromRGB(15, 30, 15)
		buyButton.MouseButton1Click:Connect(function()
			callbacks.shop(item.id)
		end)
		api.shopRows[item.id] = buyButton
	end
	api.shopToggle.MouseButton1Click:Connect(function()
		shop.Visible = not shop.Visible
	end)

	api.contextLabel = makeLabel(gui, "Context", "Waiting for the belt...", UDim2.new(0.5, -230, 1, -118), UDim2.fromOffset(460, 28), 18, WHITE)
	api.contextLabel.TextXAlignment = Enum.TextXAlignment.Center

	local actions = makePanel(gui, "Actions", UDim2.new(0.5, -230, 1, -86), UDim2.fromOffset(460, 70))
	api.buyButton = makeButton(actions, "Buy", "BUY  [E]", UDim2.fromOffset(10, 10), UDim2.fromOffset(140, 50), GREEN)
	api.buyButton.TextColor3 = Color3.fromRGB(15, 30, 15)
	api.slapButton = makeButton(actions, "Slap", "SLAP  [Q]", UDim2.fromOffset(160, 10), UDim2.fromOffset(140, 50), Color3.fromRGB(230, 120, 40))
	api.lockButton = makeButton(actions, "Lock", "LOCK  [F]", UDim2.fromOffset(310, 10), UDim2.fromOffset(140, 50), Color3.fromRGB(90, 140, 255))
	api.buyButton.MouseButton1Click:Connect(callbacks.buy)
	api.slapButton.MouseButton1Click:Connect(callbacks.slap)
	api.lockButton.MouseButton1Click:Connect(callbacks.lock)

	api.rebirthButton = makeButton(gui, "Rebirth", "REBIRTH - $25,000 (+25%)", UDim2.new(1, -236, 1, -66), UDim2.fromOffset(220, 50), Color3.fromRGB(150, 70, 220))
	api.rebirthButton.MouseButton1Click:Connect(callbacks.rebirth)

	return api
end

function HUD.update(api, state)
	api.cashLabel.Text = "$" .. commas(state.cash)
	api.incomeLabel.Text = "+$" .. commas(state.income) .. " /s"
	api.rebirthLabel.Text = "Rebirths: " .. tostring(state.rebirths) .. "  (+" .. tostring(math.floor(state.rebirths * 25 + 0.5)) .. "%)"
	local minutes = math.floor(state.tsunamiIn / 60)
	local seconds = state.tsunamiIn % 60
	if state.tsunamiWarning then
		api.waveLabel.Text = "TSUNAMI INCOMING!"
	else
		api.waveLabel.Text = "Next tsunami: " .. tostring(minutes) .. ":" .. string.format("%02d", seconds)
	end
	api.alertLabel.Visible = state.tsunamiWarning
	if state.carrying then
		api.carryLabel.Visible = true
		api.carryLabel.Text = "CARRYING: " .. state.carrying.name .. " - get home! " .. tostring(state.carrying.secondsLeft) .. "s"
	else
		api.carryLabel.Visible = false
	end
	api.baseTitle.Text = "MY BASE - " .. tostring(state.slotsUsed) .. "/" .. tostring(state.slotsTotal)
	for i = 1, 8 do
		local entry = state.owned[i]
		if entry then
			api.rows[i].Text = entry.name .. " (" .. entry.rarity .. " " .. entry.mutation .. ") - $" .. commas(entry.rate) .. "/s"
		else
			api.rows[i].Text = ""
		end
	end
	for id, button in pairs(api.shopRows) do
		local count = (state.shopOwned and state.shopOwned[id]) or 0
		if id == "slot" then
			button.Text = count >= 2 and "OWNED x2" or "$2,000"
		else
			button.Text = count >= 1 and "OWNED" or button.Text
		end
	end
	if state.lockLeft > 0 then
		api.lockButton.Text = "LOCKED " .. tostring(math.ceil(state.lockLeft)) .. "s"
	else
		api.lockButton.Text = "LOCK  [F]"
	end
end

function HUD.toast(api, text)
	api.toastLabel.Text = text
	task.delay(3, function()
		if api.toastLabel.Text == text then
			api.toastLabel.Text = ""
		end
	end)
end

return HUD
