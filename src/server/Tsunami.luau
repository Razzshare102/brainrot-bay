-- Brainrot Bay — the tsunami. Every three minutes the island gets a warning,
-- then a great wave sweeps across it from the sea: it knocks players off
-- their feet, makes thieves drop what they carry, and washes every brainrot
-- off the belt. Players who stand on their own base ride it out safely.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local Tsunami = {}

local Workspace = game:GetService("Workspace")

local wavePart = nil
local towerLight = nil
local state = "calm" -- calm | warning | wave
local clock = 0
local waveClock = 0
local onWave = nil -- (phase) -> nil; the server wires this to the client warning RemoteEvent

local WAVE_TRAVEL = 12 -- seconds for the wave to cross the island
local ISLAND_SPAN = 220 -- studs across, a little wider than the island

function Tsunami.init(wave, light, callback)
	wavePart = wave
	towerLight = light
	onWave = callback
end

function Tsunami.secondsUntilNext()
	if state == "calm" then
		return BrainrotData.TUNING.TsunamiEvery - clock
	elseif state == "warning" then
		return 0
	else
		return BrainrotData.TUNING.TsunamiEvery
	end
end

function Tsunami.isWarning()
	return state == "warning"
end

function Tsunami.phase()
	return state
end

local function startWarning()
	state = "warning"
	waveClock = 0
	if towerLight then
		towerLight.Color = Color3.fromRGB(255, 40, 40)
		towerLight.Material = Enum.Material.Neon
	end
	if onWave then
		onWave("warning")
	end
end

local function startWave()
	state = "wave"
	waveClock = 0
	if wavePart then
		wavePart.Transparency = 0.25
		wavePart.CFrame = CFrame.new(-ISLAND_SPAN / 2, 6, 0)
	end
	if onWave then
		onWave("wave")
	end
end

local function endWave()
	state = "calm"
	clock = 0
	if wavePart then
		wavePart.Transparency = 1
	end
	if towerLight then
		towerLight.Color = Color3.fromRGB(80, 255, 120)
		towerLight.Material = Enum.Material.SmoothPlastic
	end
	if onWave then
		onWave("calm")
	end
end

-- Step the tsunami clock. `sweep` is a callback the server passes that
-- knocks a player and drops what they carry; it is called once per player
-- the wave reaches.
function Tsunami.step(dt, sweep)
	if state == "calm" then
		clock += dt
		if clock >= BrainrotData.TUNING.TsunamiEvery then
			startWarning()
		end
	elseif state == "warning" then
		waveClock += dt
		if waveClock >= BrainrotData.TUNING.TsunamiWarn then
			startWave()
		end
	elseif state == "wave" then
		waveClock += dt
		local progress = math.clamp(waveClock / WAVE_TRAVEL, 0, 1)
		local x = -ISLAND_SPAN / 2 + progress * ISLAND_SPAN
		if wavePart then
			wavePart.CFrame = CFrame.new(x, 6, 0)
		end
		if sweep then
			sweep(x)
		end
		if progress >= 1 then
			endWave()
		end
	end
end

return Tsunami
