-- @ScriptType: ModuleScript
local WallRunModule = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunConfig = require(ReplicatedStorage.RunConfig)

-- Wall Run Settings
local WALL_RUN_SPEED = 40
local WALL_RUN_DURATION = 2
local WALL_RUN_COOLDOWN = 0.5
local WALL_DETECT_DISTANCE = 3
local WALL_DETECT_HEIGHT = 4
local GRAVITY_DURING_WALL_RUN = 0
local JUMP_FORCE = 50

-- State Variables
local isWallRunning = false
local currentWall = nil
local wallRunDirection = 0 -- 1 for right, -1 for left
local wallRunTimer = 0
local wallRunCooldown = false
local originalGravity = 0

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

-- Raycast setup
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {character}

-- Helpers
local function isGrounded()
	return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function canStartWallRun()
	return not wallRunCooldown and not RunConfig.Crouching and not RunConfig.Sliding
end

-- Detect walls
local function findWall()
	local pos = hrp.Position
	local rightVec = hrp.CFrame.RightVector

	-- Raycast right
	local rightHit = workspace:Raycast(pos, rightVec * WALL_DETECT_DISTANCE, raycastParams)
	if rightHit and rightHit.Instance and rightHit.Instance:IsA("BasePart") then
		return rightHit.Instance, 1, rightHit.Normal
	end

	-- Raycast left
	local leftHit = workspace:Raycast(pos, -rightVec * WALL_DETECT_DISTANCE, raycastParams)
	if leftHit and leftHit.Instance and leftHit.Instance:IsA("BasePart") then
		return leftHit.Instance, -1, leftHit.Normal
	end

	return nil, 0, nil
end

-- Start wall run
local function startWallRun(wall, direction)
	if not canStartWallRun() then return end

	isWallRunning = true
	currentWall = wall
	wallRunDirection = direction
	wallRunTimer = WALL_RUN_DURATION
	RunConfig.WallRunning = true

	originalGravity = workspace.Gravity
	workspace.Gravity = GRAVITY_DURING_WALL_RUN
	humanoid.WalkSpeed = WALL_RUN_SPEED
end

-- Stop wall run
local function stopWallRun()
	isWallRunning = false
	currentWall = nil
	wallRunDirection = 0
	RunConfig.WallRunning = false

	workspace.Gravity = originalGravity
	humanoid.WalkSpeed = RunConfig.WalkSpeed

	wallRunCooldown = true
	task.delay(WALL_RUN_COOLDOWN, function()
		wallRunCooldown = false
	end)
end

-- Wall jump
local function wallJump()
	if not isWallRunning then return end

	local dir = hrp.CFrame.LookVector
	dir = dir - hrp.CFrame.RightVector * wallRunDirection * 0.5

	hrp.AssemblyLinearVelocity = Vector3.new(
		dir.X * JUMP_FORCE,
		JUMP_FORCE,
		dir.Z * JUMP_FORCE
	)

	stopWallRun()
end

-- Update loop
RunService.RenderStepped:Connect(function(delta)
	if not character or not character.Parent then
		character = player.Character
		if character then
			humanoid = character:WaitForChild("Humanoid")
			hrp = character:WaitForChild("HumanoidRootPart")
			raycastParams.FilterDescendantsInstances = {character}
		end
		return
	end

	if isGrounded() then
		if isWallRunning then stopWallRun() end
		return
	end

	if humanoid.MoveDirection.Magnitude < 0.1 then
		if isWallRunning then stopWallRun() end
		return
	end

	if isWallRunning then
		wallRunTimer = wallRunTimer - delta

		local wall, direction = findWall()
		if not wall or direction ~= wallRunDirection or wallRunTimer <= 0 then
			stopWallRun()
			return
		end

		-- Smooth wall run velocity
		local targetVel = hrp.CFrame.LookVector * WALL_RUN_SPEED
		hrp.AssemblyLinearVelocity = Vector3.new(
			targetVel.X,
			hrp.AssemblyLinearVelocity.Y * 0.1,
			targetVel.Z
		)
	else
		local wall, direction = findWall()
		if wall and direction ~= 0 then
			startWallRun(wall, direction)
		end
	end
end)

-- Jump input
UserInputService.JumpRequest:Connect(wallJump)

-- Character respawn
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	hrp = character:WaitForChild("HumanoidRootPart")
	raycastParams.FilterDescendantsInstances = {character}
	if isWallRunning then stopWallRun() end
end)

-- Module init
function WallRunModule:init()
	print("WallRunModule initialized")
end

return WallRunModule