-- Brainrot Bay — the client. It builds the HUD, binds the E / Q / F keys,
-- and listens to the server: notifications, the tsunami's phases, and the
-- shop's state. Money comes from the player's leaderstats, so the number on
-- screen is always the number the server holds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local HUD = require(script.Parent:WaitForChild("HUD"))
local Controls = require(script.Parent:WaitForChild("Controls"))
local Effects = require(script.Parent:WaitForChild("Effects"))

local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local buyOrStealRemote = remotes:WaitForChild("BuyOrSteal")
local slapRemote = remotes:WaitForChild("Slap")
local lockRemote = remotes:WaitForChild("Lock")
local shopBuyRemote = remotes:WaitForChild("ShopBuy")
local shopStateRemote = remotes:WaitForChild("ShopState")
local rebirthRemote = remotes:WaitForChild("Rebirth")
local notifyRemote = remotes:WaitForChild("Notify")
local tsunamiRemote = remotes:WaitForChild("TsunamiAlert")

-- The tsunami countdown, ticked down locally between the server's alerts.
local tsunamiSeconds = 180
local tsunamiActive = false

local function fireBuyOrSteal()
	buyOrStealRemote:FireServer()
end

local function fireSlap()
	slapRemote:FireServer()
end

local function fireLock()
	lockRemote:FireServer()
end

HUD.init({
	shopBuy = function(itemId)
		shopBuyRemote:FireServer(itemId)
	end,
	rebirth = function()
		rebirthRemote:FireServer()
	end,
	lock = fireLock,
	buyOrSteal = fireBuyOrSteal,
	slap = fireSlap,
})

Controls.init({
	buyOrSteal = fireBuyOrSteal,
	slap = fireSlap,
	lock = fireLock,
})

Effects.init()

-- Money and rebirths, straight from leaderstats.
local function refreshMoney()
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local cash = stats:FindFirstChild("Money")
	local rebirthValue = stats:FindFirstChild("Rebirths")
	if cash and rebirthValue then
		HUD.setMoney(cash.Value, rebirthValue.Value)
	end
end

local function watchStats()
	local stats = player:WaitForChild("leaderstats")
	local cash = stats:WaitForChild("Money")
	local rebirthValue = stats:WaitForChild("Rebirths")
	cash.Changed:Connect(refreshMoney)
	rebirthValue.Changed:Connect(refreshMoney)
	refreshMoney()
end
task.spawn(watchStats)

-- Server notifications: show the line, flash gold on good news, and track
-- whether the player is carrying a stolen brainrot.
notifyRemote.OnClientEvent:Connect(function(kind, text)
	HUD.notify(text)
	if kind == "bought" or kind == "stole" or kind == "rebirth" or kind == "shop" then
		Effects.goldFlash()
	end
	if kind == "stealing" then
		HUD.showCarrying(true)
	elseif kind == "stole" or kind == "returned" or kind == "full" or kind == "dropped" or kind == "wave" then
		HUD.showCarrying(false)
	end
end)

-- The tsunami's phases, with the seconds the server counts down from.
tsunamiRemote.OnClientEvent:Connect(function(phase, seconds)
	if phase == "warning" then
		tsunamiActive = true
		tsunamiSeconds = 0
		HUD.showWarning(true)
		Effects.setWarningFlash(true)
		HUD.setTimer(0, true)
	elseif phase == "wave" then
		tsunamiActive = true
		tsunamiSeconds = 0
		HUD.showWarning(true)
		HUD.setTimer(0, true)
	elseif phase == "calm" then
		tsunamiActive = false
		tsunamiSeconds = seconds or 180
		HUD.showWarning(false)
		Effects.setWarningFlash(false)
		HUD.setTimer(tsunamiSeconds, false)
	end
end)

-- The shop's state, drawn whenever the server sends it.
shopStateRemote.OnClientEvent:Connect(function(state)
	HUD.drawShop(state)
end)

-- Ask for the shop state the first time the shop is opened.
local shopRequested = false
RunService.RenderStepped:Connect(function(dt)
	HUD.step(dt)
	Effects.step(dt)
	if not tsunamiActive and tsunamiSeconds > 0 then
		tsunamiSeconds -= dt
		HUD.setTimer(math.max(tsunamiSeconds, 0), false)
	end
	if HUD.isShopOpen() and not shopRequested then
		shopRequested = true
		shopStateRemote:FireServer()
	elseif not HUD.isShopOpen() then
		shopRequested = false
	end
end)

print("Brainrot Bay client is running: E buys and steals, Q slaps, F locks the base.")
