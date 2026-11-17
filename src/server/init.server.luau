-- Brainrot Bay — the server. It builds the island's live pieces (the belt's
-- brainrots, the players' bases), wires the E / Q / F keys and the shop and
-- rebirth buttons to the game systems through RemoteEvents, and runs the
-- island's clocks: the belt, the tsunami, and the once-a-second pay day.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Spawner = require(script:WaitForChild("Spawner"))
local StealSystem = require(script:WaitForChild("StealSystem"))
local Shop = require(script:WaitForChild("Shop"))
local Tsunami = require(script:WaitForChild("Tsunami"))

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Folders that hold the live brainrot models, so the world stays tidy.
local beltFolder = Instance.new("Folder")
beltFolder.Name = "BeltBrainrots"
beltFolder.Parent = Workspace

local basesFolder = Instance.new("Folder")
basesFolder.Name = "BaseBrainrots"
basesFolder.Parent = Workspace

-- One folder of RemoteEvents, named so the client can find them all.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local buyOrStealRemote = makeRemote("BuyOrSteal")
local slapRemote = makeRemote("Slap")
local lockRemote = makeRemote("Lock")
local shopBuyRemote = makeRemote("ShopBuy")
local shopStateRemote = makeRemote("ShopState")
local rebirthRemote = makeRemote("Rebirth")
local notifyRemote = makeRemote("Notify")
local tsunamiRemote = makeRemote("TsunamiAlert")

local function notify(player, kind, text)
	notifyRemote:FireClient(player, kind, text)
end

Spawner.init(beltFolder)
StealSystem.init(basesFolder, notify)
Shop.init(notify)

local wavePart = Workspace:FindFirstChild("TsunamiWave")
local towerLight = Workspace:FindFirstChild("TowerLight")

-- The tsunami's sweep set, and the players it has knocked in this wave.
local sweptThisWave = {}

Tsunami.init(wavePart, towerLight, function(phase)
	if phase == "wave" then
		-- A fresh wave can knock players again.
		sweptThisWave = {}
	end
	tsunamiRemote:FireAllClients(phase, Tsunami.secondsUntilNext())
end)

-- The tsunami's sweep: knock a player the wave reaches, unless they are
-- standing on their own base. A thief who is knocked drops the brainrot.
local function sweepWave(waveX)
	for _, player in ipairs(Players:GetPlayers()) do
		if not sweptThisWave[player] then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local home = nil
				local bases = BrainrotData.BASES
				local index = StealSystem.baseIndexOf(player)
				local angle = math.rad(bases[index].Angle)
				home = Vector3.new(math.cos(angle) * 55, 0, math.sin(angle) * 55)
				local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
				local onBase = (flat - Vector3.new(home.X, 0, home.Z)).Magnitude < 16
				if not onBase and math.abs(root.Position.X - waveX) < 10 then
					sweptThisWave[player] = true
					root.AssemblyLinearVelocity = Vector3.new(0, 55, 0)
					if StealSystem.isCarrying(player) then
						StealSystem.dropCarried(player)
					end
					notify(player, "wave", "The tsunami knocked you down! Stand on your base next time.")
				end
			end
		end
	end
end

-- E: buy the belt brainrot in reach, or steal the base brainrot in reach.
buyOrStealRemote.OnServerEvent:Connect(function(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local beltRecord = Spawner.nearestTo(root.Position, BrainrotData.TUNING.BuyRange)
	if beltRecord then
		local ok, message = StealSystem.tryBuy(player, beltRecord)
		if ok then
			Spawner.take(beltRecord.id)
		end
		notify(player, "action", message)
		return
	end
	local record, owner = StealSystem.nearestOwnedTo(root.Position, BrainrotData.TUNING.StealRange)
	if record then
		local message = StealSystem.trySteal(player, record, owner)
		notify(player, "action", message)
	else
		notify(player, "action", "Nothing in reach — stand by the belt to buy, or by a base to steal")
	end
end)

-- Q: slap.
slapRemote.OnServerEvent:Connect(function(player)
	local message = StealSystem.trySlap(player)
	if message ~= "" then
		notify(player, "action", message)
	end
end)

-- F: lock the player's own base.
lockRemote.OnServerEvent:Connect(function(player)
	local message = StealSystem.tryLock(player)
	notify(player, "action", message)
end)

-- Shop: buy an item, then send the fresh shop state to the client.
shopBuyRemote.OnServerEvent:Connect(function(player, itemId)
	local message = Shop.buy(player, itemId)
	notify(player, "action", message)
	shopStateRemote:FireClient(player, Shop.stateFor(player))
end)

-- Shop: the client asks for the shop state when it opens the window.
shopStateRemote.OnServerEvent:Connect(function(player)
	shopStateRemote:FireClient(player, Shop.stateFor(player))
end)

-- Rebirth.
rebirthRemote.OnServerEvent:Connect(function(player)
	local message = StealSystem.tryRebirth(player)
	notify(player, "action", message)
end)

-- Players join: give them money, a base and their leaderstats. Players who
-- come back after leaving start fresh — their brainrots are gone with them.
Players.PlayerAdded:Connect(function(player)
	StealSystem.playerJoined(player)
	-- Tell the newcomer where the tsunami clock stands right now.
	tsunamiRemote:FireClient(player, Tsunami.phase(), Tsunami.secondsUntilNext())
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 16 + 6 * StealSystem.getShopLevel(player, "SpeedCoil")
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	StealSystem.playerLeft(player)
	sweptThisWave[player] = nil
end)

-- The island's clocks.
local earnClock = 0
RunService.Heartbeat:Connect(function(dt)
	Spawner.step(dt)
	StealSystem.stepCarry(dt)
	Tsunami.step(dt, function(waveX)
		sweepWave(waveX)
	end)
	earnClock += dt
	if earnClock >= 1 then
		earnClock = 0
		StealSystem.tickEarnings()
	end
end)

print("Brainrot Bay server is running: the belt, the bases and the tsunami are live.")
