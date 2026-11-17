-- Brainrot Bay — the effects. Small, cheap juice: a red flash across the
-- screen while the tsunami warning runs, a pulse on the carrying banner, and
-- a golden flash when a purchase lands. Nothing here touches the game state;
-- it only makes what happened easier to feel.

local Effects = {}

local player = game:GetService("Players").LocalPlayer

local flashFrame = nil
local flashClock = 0
local flashing = false

function Effects.init()
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("BrainrotBayGui")
	flashFrame = Instance.new("Frame")
	flashFrame.Name = "WarningFlash"
	flashFrame.Size = UDim2.fromScale(1, 1)
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
	flashFrame.BackgroundTransparency = 1
	flashFrame.BorderSizePixel = 0
	flashFrame.Parent = gui
end

-- Start or stop the red warning flash (the tsunami is coming).
function Effects.setWarningFlash(on)
	flashing = on
	if not on and flashFrame then
		flashFrame.BackgroundTransparency = 1
	end
end

-- A one-shot golden flash for a purchase or a rebirth.
function Effects.goldFlash()
	if not flashFrame then
		return
	end
	flashFrame.BackgroundColor3 = Color3.fromRGB(255, 220, 80)
	flashFrame.BackgroundTransparency = 0.55
	task.delay(0.25, function()
		if flashFrame and not flashing then
			flashFrame.BackgroundTransparency = 1
		end
	end)
end

-- Called every frame: pulse the warning flash while it is on.
function Effects.step(dt)
	if flashing and flashFrame then
		flashClock += dt
		local pulse = (math.sin(flashClock * 6) + 1) / 2
		flashFrame.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
		flashFrame.BackgroundTransparency = 0.85 - pulse * 0.25
	end
end

return Effects
