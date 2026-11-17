-- Brainrot Bay: stealing, carrying and slapping. A steal lifts a brainrot
-- off a rival's base and welds it above your head; get it to your own base
-- before the timer runs out, or a slap sends it straight back home.

local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Bases = require(script.Parent.Bases)

local Steal = {}

local carries = {}
local lastSlapAt = {}

local function setAnchored(model, anchored)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = anchored
		end
	end
end

local function characterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

-- Give a carried brainrot back to its owner (slapped, timed out, or swept
-- away by the wave). The victim just lost a slot, so the base has room.
function Steal.dropCarry(player)
	local carry = carries[player]
	if not carry then
		return
	end
	carries[player] = nil
	if carry.weld then
		carry.weld:Destroy()
	end
	local victimState = Bases.getState(carry.victim)
	if victimState then
		setAnchored(carry.model, true)
		Bases.placeOwned(carry.victim, carry.entry, carry.model)
	else
		carry.model:Destroy()
	end
end

function Steal.getCarry(player)
	local carry = carries[player]
	if not carry then
		return nil
	end
	return { name = carry.entry.name, secondsLeft = math.max(0, math.ceil(carry.expiresAt - os.clock())) }
end

function Steal.trySteal(player, uid)
	if carries[player] then
		return false, "You are already carrying a brainrot!"
	end
	local owner, entry = Bases.findOwned(uid)
	if not owner or not entry then
		return false, "That brainrot is gone."
	end
	if owner == player then
		return false, "That brainrot is already yours."
	end
	if Bases.isLocked(owner) then
		return false, owner.DisplayName .. "'s base is locked!"
	end
	if not Bases.hasFreeSlot(player) then
		return false, "Your base is full. Buy an Extra Slot in the shop."
	end
	local root = characterRoot(player)
	if not root then
		return false, "No character yet."
	end
	local _, model = Bases.takeOwned(owner, uid)
	if not model then
		return false, "That brainrot is gone."
	end
	setAnchored(model, false)
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = model.PrimaryPart
	weld.C0 = CFrame.new(0, 4, 0)
	weld.Parent = root
	carries[player] = {
		entry = entry,
		victim = owner,
		model = model,
		weld = weld,
		expiresAt = os.clock() + GameConfig.CARRY_SECONDS,
	}
	return true, "Stole " .. entry.name .. "! Run it home in " .. tostring(GameConfig.CARRY_SECONDS) .. "s!"
end

function Steal.slap(player)
	local now = os.clock()
	if now - (lastSlapAt[player] or 0) < GameConfig.SLAP_COOLDOWN_SECONDS then
		return false, "Slap is recharging."
	end
	local root = characterRoot(player)
	if not root then
		return false, "No character yet."
	end
	local power = GameConfig.SLAP_FLING
	if Bases.itemCount(player, "glove") > 0 then
		power *= 2
	end
	local best = nil
	local bestDistance = GameConfig.SLAP_RANGE
	for _, other in ipairs(game:GetService("Players"):GetPlayers()) do
		if other ~= player then
			local otherRoot = characterRoot(other)
			if otherRoot then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance < bestDistance then
					best = other
					bestDistance = distance
				end
			end
		end
	end
	if not best then
		return false, "Nobody in slap range."
	end
	lastSlapAt[player] = now
	local victimRoot = characterRoot(best)
	if victimRoot then
		local away = victimRoot.Position - root.Position
		away = Vector3.new(away.X, 0, away.Z).Unit
		victimRoot.AssemblyLinearVelocity = away * power + Vector3.new(0, 28, 0)
	end
	if carries[best] then
		Steal.dropCarry(best)
		return true, "Slapped " .. best.DisplayName .. " and they dropped the brainrot!"
	end
	return true, "Slapped " .. best.DisplayName .. "!"
end

function Steal.init()
	task.spawn(function()
		while true do
			task.wait(0.5)
			local now = os.clock()
			for player, carry in pairs(carries) do
				local root = characterRoot(player)
				if not root then
					Steal.dropCarry(player)
				elseif now >= carry.expiresAt then
					Steal.dropCarry(player)
				else
					local state = Bases.getState(player)
					if state then
						local home = Bases.baseCenter(state.baseIndex)
						local flat = Vector3.new(root.Position.X - home.X, 0, root.Position.Z - home.Z)
						if flat.Magnitude < 11 then
							carries[player] = nil
							if carry.weld then
								carry.weld:Destroy()
							end
							setAnchored(carry.model, true)
							Bases.placeOwned(player, carry.entry, carry.model)
						end
					end
				end
			end
		end
	end)
end

return Steal
