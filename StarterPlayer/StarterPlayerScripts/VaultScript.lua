-- @ScriptType: LocalScript
--// Vault System - Fixed & Optimized
--// Press Space near a VaultWall while moving forward → vault over with momentum

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- References (updated on respawn)
local humanoid
local rootPart
local animator

-- Configuration
local CONFIG = {
	VAULT_WALL_NAME    = "VaultWall",
	DETECTION_DISTANCE = 8,
	VAULT_DURATION     = 0.35,
	COOLDOWN           = 0.5,
	MIN_SPEED          = 1,
	ANIMATION_PATH     = "ReplicatedStorage.VaultAnimations.VaultAnimation.Vault2",  -- Path to KeyframeSequence
	MAX_HEIGHT         = 3.6,  -- Maximum height of vaultable object (Y axis)
	MAX_DEPTH          = 2,    -- Maximum depth of vaultable object (Z axis)
}

-- State
local vaulting = false
local lastVaultTime = 0

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function isOnCooldown()
	return tick() - lastVaultTime < CONFIG.COOLDOWN
end

local function findNearestVaultWall()
	local rootPos = rootPart.Position
	local closest, minDist = nil, CONFIG.DETECTION_DISTANCE

	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == CONFIG.VAULT_WALL_NAME then
			local dist = (rootPos - part.Position).Magnitude
			if dist < minDist then
				minDist = dist
				closest = part
			end
		end
	end

	return closest
end

local function isMovingForwardEnough()
	local velocity = rootPart.AssemblyLinearVelocity
	local speed = velocity.Magnitude
	if speed < CONFIG.MIN_SPEED then
		return false
	end

	local forward = rootPart.CFrame.LookVector
	local moveDir = velocity.Unit

	return moveDir:Dot(forward) > 0
end

local function getAnimator()
	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function playVaultAnimation()
	-- Get the KeyframeSequence from ReplicatedStorage
	local keyframeSeq = ReplicatedStorage:FindFirstChild(CONFIG.ANIMATION_PATH)
	if not keyframeSeq or not keyframeSeq:IsA("KeyframeSequence") then
		warn("[VaultScript] Failed to find KeyframeSequence at: " .. CONFIG.ANIMATION_PATH)
		return nil
	end

	-- Load the KeyframeSequence directly
	local track = getAnimator():LoadAnimation(keyframeSeq)
	if not track then
		warn("[VaultScript] Failed to load animation track")
		return nil
	end

	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	track:Play()

	return track
end

-- ─────────────────────────────────────────────
-- Core Vault Logic
-- ─────────────────────────────────────────────

local function tryVault()
	if vaulting or isOnCooldown() then return end
	if not humanoid or not rootPart then return end
	if not isMovingForwardEnough() then return end

	local wall = findNearestVaultWall()
	if not wall then return end

	-- Check if the wall is vaultable based on size
	local wallSize = wall.Size
	if wallSize.Y > CONFIG.MAX_HEIGHT or wallSize.Z > CONFIG.MAX_DEPTH then
		return -- Wall is too tall or too deep to vault
	end

	vaulting = true
	lastVaultTime = tick()

	-- Play animation
	local track = playVaultAnimation()

	-- Store original values
	local wallCanCollide = wall.CanCollide
	local autoRotate = humanoid.AutoRotate
	local originalJumpPower = humanoid.JumpPower

	-- Apply vault state
	humanoid.AutoRotate = false
	humanoid.JumpPower = 0
	wall.CanCollide = false

	-- Optional forward boost (makes it feel better)
	rootPart:ApplyImpulse(rootPart.CFrame.LookVector * 120)

	-- Restore after duration
	task.delay(CONFIG.VAULT_DURATION, function()
		if wall and wall.Parent then
			wall.CanCollide = wallCanCollide
		end

		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = autoRotate
			humanoid.JumpPower = originalJumpPower
		end

		if track then
			track:Stop()
		end

		vaulting = false
	end)
end

-- ─────────────────────────────────────────────
-- Input
-- ─────────────────────────────────────────────

local function onVaultInput(actionName, state)
	if state == Enum.UserInputState.Begin then
		tryVault()
	end
	return Enum.ContextActionResult.Pass
end

-- ─────────────────────────────────────────────
-- Setup
-- ─────────────────────────────────────────────

local function setup(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	getAnimator()
end

setup(character)
player.CharacterAdded:Connect(setup)

ContextActionService:BindAction(
	"Vault",
	onVaultInput,
	false,
	Enum.KeyCode.Space
)