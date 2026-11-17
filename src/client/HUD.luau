-- Brainrot Bay — the HUD. It builds the whole ScreenGui: the money counter
-- up top, the tsunami timer, the action buttons along the bottom, the shop
-- window, and the notification line. It draws nothing in the top-left corner,
-- where Roblox puts its own menu buttons.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local HUD = {}

local player = game:GetService("Players").LocalPlayer

local gui = nil
local moneyLabel = nil
local rebirthLabel = nil
local timerLabel = nil
local warnBanner = nil
local noticeLabel = nil
local noticeClock = 0
local shopFrame = nil
local shopList = nil
local carryLabel = nil

local onShopBuy = nil -- (itemId) -> nil; the client wires this to the shop RemoteEvent
local onRebirth = nil -- () -> nil
local onLock = nil -- () -> nil
local onBuyOrSteal = nil -- () -> nil; fires the E action
local onSlap = nil -- () -> nil; fires the Q action

local function makeButton(name, text, position, size, parent)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
	button.BackgroundTransparency = 0.15
	button.BorderColor3 = Color3.fromRGB(255, 255, 255)
	button.BorderSizePixel = 1
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Font = Enum.Font.GothamBold
	button.Parent = parent
	return button
end

local function makeLabel(name, text, position, size, parent, colour, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.TextColor3 = colour or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.1
	label.TextScaled = textSize == nil
	if textSize then
		label.TextSize = textSize
	end
	label.Font = Enum.Font.GothamBold
	label.Parent = parent
	return label
end

function HUD.init(callbacks)
	onShopBuy = callbacks.shopBuy
	onRebirth = callbacks.rebirth
	onLock = callbacks.lock
	onBuyOrSteal = callbacks.buyOrSteal
	onSlap = callbacks.slap

	gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotBayGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true

	-- Money, top centre: the number the player watches most.
	moneyLabel = makeLabel("MoneyLabel", "$100", UDim2.new(0.5, -110, 0, 8), UDim2.fromOffset(220, 44), gui, Color3.fromRGB(255, 220, 80), 30)
	rebirthLabel = makeLabel("RebirthLabel", "Rebirth 0  |  x1.00", UDim2.new(0.5, -110, 0, 52), UDim2.fromOffset(220, 22), gui, Color3.fromRGB(255, 255, 255), 16)

	-- Tsunami timer, top right.
	timerLabel = makeLabel("TimerLabel", "Tsunami in 3:00", UDim2.new(1, -210, 0, 10), UDim2.fromOffset(200, 30), gui, Color3.fromRGB(120, 220, 255), 20)
	timerLabel.TextXAlignment = Enum.TextXAlignment.Right

	-- The tsunami warning banner, centre top, hidden until the wave comes.
	warnBanner = makeLabel("WarnBanner", "TSUNAMI INCOMING — GET TO YOUR BASE!", UDim2.new(0.5, -260, 0, 90), UDim2.fromOffset(520, 44), gui, Color3.fromRGB(255, 70, 70), 26)
	warnBanner.Visible = false

	-- The notification line, under the money counter.
	noticeLabel = makeLabel("NoticeLabel", "", UDim2.new(0.5, -300, 0, 82), UDim2.fromOffset(600, 26), gui, Color3.fromRGB(255, 255, 255), 18)
	noticeLabel.Visible = false

	-- Carrying indicator, above the bottom buttons.
	carryLabel = makeLabel("CarryLabel", "CARRYING A BRAINROT — RUN HOME!", UDim2.new(0.5, -220, 1, -150), UDim2.fromOffset(440, 30), gui, Color3.fromRGB(255, 180, 60), 20)
	carryLabel.Visible = false

	-- Bottom buttons: buy/steal, slap, lock, shop, rebirth.
	local bar = Instance.new("Frame")
	bar.Name = "ActionBar"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -12)
	bar.Size = UDim2.fromOffset(620, 56)
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local buyButton = makeButton("BuyButton", "BUY / STEAL  [E]", UDim2.fromOffset(0, 0), UDim2.fromOffset(140, 56), bar)
	buyButton.MouseButton1Click:Connect(function()
		if onBuyOrSteal then
			onBuyOrSteal()
		end
		HUD.flashButton(buyButton)
	end)

	local slapButton = makeButton("SlapButton", "SLAP  [Q]", UDim2.fromOffset(150, 0), UDim2.fromOffset(110, 56), bar)
	slapButton.MouseButton1Click:Connect(function()
		if onSlap then
			onSlap()
		end
		HUD.flashButton(slapButton)
	end)

	local lockButton = makeButton("LockButton", "LOCK BASE  [F]", UDim2.fromOffset(270, 0), UDim2.fromOffset(130, 56), bar)
	lockButton.MouseButton1Click:Connect(function()
		if onLock then
			onLock()
		end
		HUD.flashButton(lockButton)
	end)

	local shopButton = makeButton("ShopButton", "SHOP", UDim2.fromOffset(410, 0), UDim2.fromOffset(90, 56), bar)
	shopButton.MouseButton1Click:Connect(function()
		HUD.toggleShop()
		HUD.flashButton(shopButton)
	end)

	local rebirthButton = makeButton("RebirthButton", "REBIRTH", UDim2.fromOffset(510, 0), UDim2.fromOffset(110, 56), bar)
	rebirthButton.BackgroundColor3 = Color3.fromRGB(120, 40, 120)
	rebirthButton.MouseButton1Click:Connect(function()
		if onRebirth then
			onRebirth()
		end
		HUD.flashButton(rebirthButton)
	end)

	-- The shop window, centre screen, hidden until opened.
	shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.Position = UDim2.fromScale(0.5, 0.5)
	shopFrame.Size = UDim2.fromOffset(460, 360)
	shopFrame.BackgroundColor3 = Color3.fromRGB(25, 35, 55)
	shopFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
	shopFrame.BorderSizePixel = 2
	shopFrame.Visible = false
	shopFrame.Parent = gui

	local shopTitle = makeLabel("ShopTitle", "SHOP — spend what your brainrots earn", UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 30), shopFrame, Color3.fromRGB(255, 220, 80), 20)
	shopTitle.TextScaled = false

	shopList = Instance.new("Frame")
	shopList.Name = "ShopList"
	shopList.Position = UDim2.new(0, 10, 0, 44)
	shopList.Size = UDim2.new(1, -20, 1, -100)
	shopList.BackgroundTransparency = 1
	shopList.Parent = shopFrame

	local closeButton = makeButton("CloseButton", "CLOSE", UDim2.new(0.5, -60, 1, -52), UDim2.fromOffset(120, 40), shopFrame)
	closeButton.MouseButton1Click:Connect(function()
		shopFrame.Visible = false
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

function HUD.flashButton(button)
	button.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
	task.delay(0.15, function()
		if button.Name == "RebirthButton" then
			button.BackgroundColor3 = Color3.fromRGB(120, 40, 120)
		else
			button.BackgroundColor3 = Color3.fromRGB(40, 60, 90)
		end
	end)
end

function HUD.setMoney(amount, rebirthCount)
	if moneyLabel then
		moneyLabel.Text = "$" .. tostring(math.floor(amount + 0.5))
	end
	if rebirthLabel then
		local mult = BrainrotData.rebirthMult(rebirthCount)
		rebirthLabel.Text = "Rebirth " .. tostring(rebirthCount) .. "  |  x" .. string.format("%.2f", mult)
	end
end

function HUD.setTimer(seconds, warning)
	if timerLabel then
		if warning then
			timerLabel.Text = "TSUNAMI NOW!"
			timerLabel.TextColor3 = Color3.fromRGB(255, 70, 70)
		else
			local mins = math.floor(seconds / 60)
			local secs = math.floor(seconds % 60)
			timerLabel.Text = "Tsunami in " .. tostring(mins) .. ":" .. string.format("%02d", secs)
			timerLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
		end
	end
end

function HUD.showWarning(show)
	if warnBanner then
		warnBanner.Visible = show
	end
end

function HUD.showCarrying(show)
	if carryLabel then
		carryLabel.Visible = show
	end
end

function HUD.notify(text)
	if not noticeLabel then
		return
	end
	noticeLabel.Text = text
	noticeLabel.Visible = true
	noticeClock = 4
end

-- Called every frame by the client: fades the notification line away.
function HUD.step(dt)
	if noticeLabel and noticeLabel.Visible then
		noticeClock -= dt
		if noticeClock <= 0 then
			noticeLabel.Visible = false
		end
	end
end

function HUD.toggleShop()
	if shopFrame then
		shopFrame.Visible = not shopFrame.Visible
	end
end

function HUD.isShopOpen()
	return shopFrame and shopFrame.Visible
end

-- Draw the shop's rows from the server's state: name, level and next cost.
function HUD.drawShop(state)
	if not shopList then
		return
	end
	for _, child in ipairs(shopList:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	for _, item in ipairs(state) do
		local row = Instance.new("Frame")
		row.Name = "ShopRow_" .. item.Id
		row.Position = UDim2.fromOffset(0, y)
		row.Size = UDim2.new(1, 0, 0, 44)
		row.BackgroundColor3 = Color3.fromRGB(40, 55, 85)
		row.BorderSizePixel = 0
		row.Parent = shopList

		local nameLabel = makeLabel("ItemName", item.Name .. "  (" .. tostring(item.Level) .. "/" .. tostring(item.MaxLevel) .. ")", UDim2.fromOffset(8, 2), UDim2.new(0.6, -8, 0, 22), row, Color3.fromRGB(255, 255, 255), 16)
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.TextScaled = false

		local descLabel = makeLabel("ItemDesc", item.Desc, UDim2.fromOffset(8, 24), UDim2.new(0.6, -8, 0, 18), row, Color3.fromRGB(180, 200, 220), 13)
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextScaled = false

		if item.Cost then
			local buy = makeButton("Buy_" .. item.Id, "$" .. tostring(item.Cost), UDim2.new(1, -108, 0, 4), UDim2.fromOffset(100, 36), row)
			buy.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
			buy.MouseButton1Click:Connect(function()
				if onShopBuy then
					onShopBuy(item.Id)
				end
			end)
		else
			makeLabel("MaxedLabel", "MAXED", UDim2.new(1, -108, 0, 4), UDim2.fromOffset(100, 36), row, Color3.fromRGB(255, 220, 80), 16)
		end
		y += 50
	end
end

return HUD
