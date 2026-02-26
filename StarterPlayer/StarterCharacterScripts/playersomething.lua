-- @ScriptType: LocalScript
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Configuration
local JUMP_POWER = 40      -- Lower jump height (default is 50)
local JUMP_COOLDOWN = 0.67-- Time between jumps (seconds)

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Apply reduced jump settings
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JUMP_POWER

	local lastJumpTime = 0
	local jumpLocked = false

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Jumping then
			local currentTime = tick()

			-- If still on cooldown, cancel jump immediately
			if jumpLocked or (currentTime - lastJumpTime < JUMP_COOLDOWN) then
				humanoid:ChangeState(Enum.HumanoidStateType.Landed)
				return
			end

			-- Start cooldown
			lastJumpTime = currentTime
			jumpLocked = true

			-- Disable jumping completely
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

			task.delay(JUMP_COOLDOWN, function()
				if humanoid and humanoid.Parent then
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
					jumpLocked = false
				end
			end)
		end
	end)
end

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)