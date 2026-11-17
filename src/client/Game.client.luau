-- Brainrot Bay: the client. It builds the HUD, turns keys and taps into
-- the same three actions, and keeps one job of its own: watching the world
-- around the player so the E key always knows whether it should buy the
-- front brainrot off the belt or steal the one standing next to you.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local HUD = require(script.Parent.HUD)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local state = nil
local hud = nil

local STEAL_SCAN_RANGE = 14

local function myRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") or nil
end

local function ownUids()
	local set = {}
	if state then
		for _, entry in ipairs(state.owned) do
			set[entry.uid] = true
		end
	end
	return set
end

-- The closest brainrot on somebody else's base, if one is in reach.
local function nearestStealable()
	local root = myRoot()
	if not root then
		return nil
	end
	local folder = workspace:FindFirstChild("PlacedBrainrots")
	if not folder then
		return nil
	end
	local mine = ownUids()
	local best = nil
	local bestDistance = STEAL_SCAN_RANGE
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and not mine[model.Name] then
			local primary = model.PrimaryPart
			if primary then
				local distance = (primary.Position - root.Position).Magnitude
				if distance < bestDistance then
					local tag = primary:FindFirstChild("Tag")
					local nameLabel = tag and tag:FindFirstChild("NameLabel")
					local rateLabel = tag and tag:FindFirstChild("RateLabel")
					best = {
						uid = model.Name,
						name = nameLabel and nameLabel.Text or model.Name,
						rate = rateLabel and rateLabel.Text or "",
					}
					bestDistance = distance
				end
			end
		end
	end
	return best
end

local function doBuyOrSteal()
	local target = nearestStealable()
	if target then
		remotes.StealRequest:FireServer(target.uid)
		return
	end
	remotes.BuyRequest:FireServer()
end

local function doSlap()
	remotes.SlapRequest:FireServer()
end

local function doLock()
	remotes.LockRequest:FireServer()
end

hud = HUD.build({
	buy = doBuyOrSteal,
	slap = doSlap,
	lock = doLock,
	shop = function(itemId)
		remotes.ShopRequest:FireServer(itemId)
	end,
	rebirth = function()
		remotes.RebirthRequest:FireServer()
	end,
})

remotes.StatePush.OnClientEvent:Connect(function(snap)
	state = snap
	HUD.update(hud, snap)
end)

remotes.Toast.OnClientEvent:Connect(function(text)
	HUD.toast(hud, text)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		doBuyOrSteal()
	elseif input.KeyCode == Enum.KeyCode.Q then
		doSlap()
	elseif input.KeyCode == Enum.KeyCode.F then
		doLock()
	end
end)

-- Keep the context line honest: it always says what E will do right now.
task.spawn(function()
	while true do
		task.wait(0.3)
		if state then
			if state.carrying then
				hud.contextLabel.Text = "E: carrying " .. state.carrying.name .. " - run home!"
			else
				local target = nearestStealable()
				if target then
					hud.contextLabel.Text = "E: STEAL " .. target.name .. " (" .. target.rate .. ")"
				elseif state.beltNext then
					local next = state.beltNext
					hud.contextLabel.Text = "E: BUY " .. next.name .. " - $" .. tostring(next.price) .. " (" .. next.rarity .. " " .. next.mutation .. ", $" .. tostring(next.rate) .. "/s)"
				else
					hud.contextLabel.Text = "E: waiting for the belt..."
				end
			end
		end
	end
end)
