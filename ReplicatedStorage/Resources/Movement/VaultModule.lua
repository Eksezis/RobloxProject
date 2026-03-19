-- @ScriptType: ModuleScript
-- VaultModule.lua
-- ModuleScript version of the Vault System

local VaultModule = {}

-- Services
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Default Configuration
VaultModule.CONFIG = {
	VAULT_WALL_NAME    = "VaultWall",
	DETECTION_DISTANCE = 8,
	VAULT_DURATION     = 0.35,
	COOLDOWN           = 0.5,
	MIN_SPEED          = 1,
	ANIMATION_PATH     = "ReplicatedStorage.VaultAnimations.VaultAnimation.Vault2",
	MAX_HEIGHT         = 3.6,
	MAX_DEPTH          = 2,
	FORWARD_IMPULSE    = 120,
}

-- State
local vaulting = false
local lastVaultTime = 0
local player = Players.LocalPlayer
local character, humanoid, rootPart, animator

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function isOnCooldown()
	return tick() - lastVaultTime < VaultModule.CONFIG.COOLDOWN
end

local function findNearestVaultWall()
	if not rootPart then return nil end
	local rootPos = rootPart.Position
	local closest, minDist = nil, VaultModule.CONFIG.DETECTION_DISTANCE

	for _, part in ipairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == VaultModule.CONFIG.VAULT_WALL_NAME then
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
	if not rootPart then return false end
	local velocity = rootPart.AssemblyLinearVelocity
	local speed = velocity.Magnitude
	if speed < VaultModule.CONFIG.MIN_SPEED then
		return false
	end

	local forward = rootPart.CFrame.LookVector
	local moveDir = velocity.Unit
	return moveDir:Dot(forward) > 0
end

local function getAnimator()
	if not humanoid then return nil end
	animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function playVaultAnimation()
	local keyframeSeq = ReplicatedStorage:FindFirstChild(VaultModule.CONFIG.ANIMATION_PATH)
	if not keyframeSeq or not keyframeSeq:IsA("KeyframeSequence") then
		warn("[VaultModule] Failed to find KeyframeSequence at: " .. VaultModule.CONFIG.ANIMATION_PATH)
		return nil
	end

	local track = getAnimator():LoadAnimation(keyframeSeq)
	if track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		track:Play()
	else
		warn("[VaultModule] Failed to load animation track")
	end

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

	local wallSize = wall.Size
	if wallSize.Y > VaultModule.CONFIG.MAX_HEIGHT or wallSize.Z > VaultModule.CONFIG.MAX_DEPTH then
		return
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

	-- Forward impulse
	rootPart:ApplyImpulse(rootPart.CFrame.LookVector * VaultModule.CONFIG.FORWARD_IMPULSE)

	-- Restore after duration
	task.delay(VaultModule.CONFIG.VAULT_DURATION, function()
		if wall and wall.Parent then wall.CanCollide = wallCanCollide end
		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = autoRotate
			humanoid.JumpPower = originalJumpPower
		end
		if track then track:Stop() end
		vaulting = false
	end)
end

-- ─────────────────────────────────────────────
-- Input Handling
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

function VaultModule:init()
	player.CharacterAdded:Connect(setup)
	setup(player.Character or player.CharacterAdded:Wait())

	-- Bind input
	ContextActionService:BindAction("Vault", onVaultInput, false, Enum.KeyCode.Space)
end

-- ─────────────────────────────────────────────
-- Public API
-- ─────────────────────────────────────────────

VaultModule.TryVault = tryVault
VaultModule.Setup = setup
VaultModule.IsVaulting = function() return vaulting end

return VaultModule