-- Brainrot Bay: the server bootstrap. It builds the remotes, starts every
-- service, and wires each client request to the service that owns it. The
-- state loop below is the only thing that talks to the client unasked: a
-- fresh snapshot for every player twice a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bases = require(script.Parent.Bases)
local Belt = require(script.Parent.Belt)
local Shop = require(script.Parent.Shop)
local Steal = require(script.Parent.Steal)
local Tsunami = require(script.Parent.Tsunami)

local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local buyRemote = makeRemote("BuyRequest")
local stealRemote = makeRemote("StealRequest")
local slapRemote = makeRemote("SlapRequest")
local lockRemote = makeRemote("LockRequest")
local shopRemote = makeRemote("ShopRequest")
local rebirthRemote = makeRemote("RebirthRequest")
local stateRemote = makeRemote("StatePush")
local toastRemote = makeRemote("Toast")

Bases.init()
Belt.init()
Steal.init()
Tsunami.init()

local function toast(player, text)
	toastRemote:FireClient(player, text)
end

buyRemote.OnServerEvent:Connect(function(player)
	local ok, message = Belt.tryBuy(player)
	toast(player, message)
end)

stealRemote.OnServerEvent:Connect(function(player, uid)
	local ok, message = Steal.trySteal(player, uid)
	toast(player, message)
end)

slapRemote.OnServerEvent:Connect(function(player)
	local ok, message = Steal.slap(player)
	toast(player, message)
end)

lockRemote.OnServerEvent:Connect(function(player)
	local ok, message = Bases.tryLock(player)
	toast(player, message)
end)

shopRemote.OnServerEvent:Connect(function(player, itemId)
	local ok, message = Shop.tryBuy(player, itemId)
	toast(player, message)
end)

rebirthRemote.OnServerEvent:Connect(function(player)
	local ok, message = Bases.tryRebirth(player)
	toast(player, message)
end)

-- Sneakers must survive a respawn: re-apply the speed when a character loads.
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		if Bases.itemCount(player, "sneakers") > 0 then
			humanoid.WalkSpeed = 22
		end
	end)
end)

-- Twice a second, every player gets their own snapshot: cash, income, what
-- is on their base, the front brainrot on the belt, and the wave countdown.
task.spawn(function()
	while true do
		task.wait(0.5)
		local front = Belt.front()
		local beltNext = nil
		if front then
			beltNext = {
				uid = front.uid,
				name = front.character.name,
				rarity = front.character.rarity,
				mutation = front.mutation.name,
				rate = front.rate,
				price = front.price,
			}
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local snap = Bases.snapshot(player, {
				beltNext = beltNext,
				tsunamiIn = math.floor(Tsunami.secondsUntilWave() + 0.5),
				tsunamiWarning = Tsunami.isWarning(),
				carrying = Steal.getCarry(player),
			})
			if snap then
				stateRemote:FireClient(player, snap)
			end
		end
	end
end)
