-- Brainrot Bay: the tsunami. Every three minutes the sea comes for the
-- island: ten seconds of warning, then a wall of water sweeps from north
-- to south, flinging players and dropping whatever they are carrying.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Steal = require(script.Parent.Steal)

local Tsunami = {}

local nextWaveAt = 0
local warning = false

function Tsunami.secondsUntilWave()
	return math.max(0, nextWaveAt - os.clock())
end

function Tsunami.isWarning()
	return warning
end

local function flingPlayers(waveZ)
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local pos = root.Position
			if math.abs(pos.X) < 85 and math.abs(pos.Z - waveZ) < 15 then
				root.AssemblyLinearVelocity = Vector3.new(0, 30, GameConfig.TSUNAMI_FLING)
				Steal.dropCarry(player)
			end
		end
	end
end

local function runWave()
	warning = false
	local wave = Instance.new("Part")
	wave.Name = "TsunamiWave"
	wave.Size = Vector3.new(170, 14, 26)
	wave.Color = Color3.fromRGB(30, 120, 220)
	wave.Material = Enum.Material.SmoothPlastic
	wave.Transparency = 0.15
	wave.Anchored = true
	wave.CanCollide = false
	wave.Parent = workspace
	local z = -80
	while z < 80 do
		z += 4
		wave.CFrame = CFrame.new(0, 9, z)
		flingPlayers(z)
		task.wait(0.12)
	end
	wave:Destroy()
end

function Tsunami.init()
	nextWaveAt = os.clock() + GameConfig.TSUNAMI_PERIOD_SECONDS
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			local left = nextWaveAt - now
			if left <= GameConfig.TSUNAMI_WARNING_SECONDS and left > 0 then
				warning = true
			elseif left <= 0 then
				runWave()
				nextWaveAt = os.clock() + GameConfig.TSUNAMI_PERIOD_SECONDS
			end
		end
	end)
end

return Tsunami
