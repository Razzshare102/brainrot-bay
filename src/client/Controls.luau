-- Brainrot Bay — the controls. E buys or steals, Q slaps, F locks the base.
-- They are bound with ContextActionService, so the keys work even while the
-- camera scripts hold the arrow keys, and the same actions are the ones the
-- HUD's bottom buttons fire, so a key and a tap can never double-fire.

local ContextActionService = game:GetService("ContextActionService")

local Controls = {}

local actions = {}

function Controls.init(callbacks)
	actions.buyOrSteal = callbacks.buyOrSteal
	actions.slap = callbacks.slap
	actions.lock = callbacks.lock

	local function bind(name, key, fn)
		ContextActionService:BindAction(name, function(_, state)
			if state == Enum.UserInputState.Begin then
				fn()
			end
			return Enum.ContextActionResult.Sink
		end, false, key)
	end

	bind("BuyOrSteal", Enum.KeyCode.E, function()
		if actions.buyOrSteal then
			actions.buyOrSteal()
		end
	end)
	bind("Slap", Enum.KeyCode.Q, function()
		if actions.slap then
			actions.slap()
		end
	end)
	bind("LockBase", Enum.KeyCode.F, function()
		if actions.lock then
			actions.lock()
		end
	end)
end

-- The same three actions the HUD buttons call, so keys and taps share code.
function Controls.buyOrSteal()
	if actions.buyOrSteal then
		actions.buyOrSteal()
	end
end

function Controls.slap()
	if actions.slap then
		actions.slap()
	end
end

function Controls.lock()
	if actions.lock then
		actions.lock()
	end
end

return Controls
