-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer

local JUMP_POWER = 40
local JUMP_COOLDOWN = 0.8

local humanoid = nil
local lastJumpTime = 0
local lastLandTime = 0

-- Setup humanoid and connect Landed event
local function setupCharacter(character)
	humanoid = character:WaitForChild("Humanoid")
	humanoid.UseJumpPower = true
	humanoid.JumpPower = JUMP_POWER

	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			lastLandTime = tick()
		elseif newState == Enum.HumanoidStateType.Jumping then
			lastJumpTime = tick()
		end
	end)
end

-- Handle jump input early to block spamming
local function handleJump(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	local now = tick()

	-- Enforce cooldown AND require small delay after landing (e.g. 0.1s)
	if (now - lastJumpTime < JUMP_COOLDOWN) or (now - lastLandTime < 0.1) then
		return Enum.ContextActionResult.Sink -- block jump
	end

	lastJumpTime = now
	return Enum.ContextActionResult.Pass -- allow jump
end

ContextActionService:BindAction(
	"JumpCooldown",
	handleJump,
	false,
	Enum.KeyCode.Space
)

if player.Character then
	setupCharacter(player.Character)
end

player.CharacterAdded:Connect(setupCharacter)