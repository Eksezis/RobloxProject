-- @ScriptType: LocalScript
--// Vault System - Optimized
--// Press Space near a VaultWall while moving forward → vault over with momentum

local Players              = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService           = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- References (updated on respawn)
local humanoid
local rootPart

-- Configuration
local CONFIG = {
	VAULT_WALL_NAME   = "VaultWall",
	DETECTION_DISTANCE = 5,
	VAULT_DURATION    = 0.3,
	COOLDOWN          = 0.5,
	MIN_SPEED         = 1,           -- studs/sec
}

-- State
local vaulting = false
local lastVaultTime = 0
local connection    -- heartbeat connection (cleaned up on destroy)

-- ────────────────────────────────────────────────────────────────
--  Helpers
-- ────────────────────────────────────────────────────────────────

local function isOnCooldown()
	return tick() - lastVaultTime < CONFIG.COOLDOWN
end

local function findNearestVaultWall()
	local rootPos = rootPart.Position
	local closest, minDist = nil, CONFIG.DETECTION_DISTANCE + 0.1

	for _, part in workspace:GetDescendants() do
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

	-- Must be moving mostly forward (dot > 0)
	return moveDir:Dot(forward) > 0
end

-- ────────────────────────────────────────────────────────────────
--  Core Vault Logic
-- ────────────────────────────────────────────────────────────────

local function tryVault()
	if vaulting or isOnCooldown() then
		return
	end

	if not isMovingForwardEnough() then
		return
	end

	local wall = findNearestVaultWall()
	if not wall then
		return
	end

	vaulting = true
	lastVaultTime = tick()

	-- PLAY VAULT ANIMATION
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://92573172770792"

	local track = humanoid:LoadAnimation(anim)
	track.Priority = Enum.AnimationPriority.Action
	track:Play()

	-- Store original properties
	local wallCanCollide   = wall.CanCollide
	local autoRotate       = humanoid.AutoRotate
	local originalJumpPower = humanoid.JumpPower

	-- Apply vault changes
	humanoid.AutoRotate  = false
	humanoid.JumpPower   = 0
	wall.CanCollide      = false

	-- Wait → restore
	task.delay(CONFIG.VAULT_DURATION, function()
		-- Only restore if objects still exist
		if wall and wall.Parent then
			wall.CanCollide = wallCanCollide
		end

		if humanoid and humanoid.Parent then
			humanoid.AutoRotate = autoRotate
			humanoid.JumpPower  = originalJumpPower
		end

		vaulting = false
	end)
end

-- ────────────────────────────────────────────────────────────────
--  Input
-- ────────────────────────────────────────────────────────────────

local function onVaultInput(actionName, state, inputObj)
	if state == Enum.UserInputState.Begin then
		tryVault()
	end
	return Enum.ContextActionResult.Pass   -- let jump still work when vault not possible
end

-- ────────────────────────────────────────────────────────────────
--  Setup / Cleanup
-- ────────────────────────────────────────────────────────────────

local function setup(character)
	humanoid = character:WaitForChild("Humanoid", 5)
	rootPart = character:WaitForChild("HumanoidRootPart", 5)

	if not (humanoid and rootPart) then return end

	-- Clean previous connection if exists
	if connection then
		connection:Disconnect()
		connection = nil
	end

	connection = RunService.Heartbeat:Connect(function()
		if vaulting then return end
	end)
end

-- Initial setup
setup(character)

-- Respawn handling
player.CharacterAdded:Connect(setup)

-- Bind input (only once)
ContextActionService:BindAction(
	"Vault",
	onVaultInput,
	false,
	Enum.KeyCode.Space
)

-- Optional cleanup (good practice)
player.CharacterRemoving:Connect(function()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end)
