-- @ScriptType: LocalScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

local GRAB_DISTANCE = 6
local GRAB_HEIGHT = 4
local isGrabbing = false
local grabbedLedge = nil

-- Raycast params
local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {character}
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Update raycast filter when character changes
local function updateRaycastFilter()
	rayParams.FilterDescendantsInstances = {character}
end

-- Check for ledge above and in front
local function findLedge()
	-- Start ray from slightly above the player's head
	local origin = root.Position + Vector3.new(0, 3, 0)
	
	-- Raycast in an upward-forward direction
	local forward = root.CFrame.LookVector
	local upward = Vector3.new(0, 1, 0)
	local direction = (forward + upward).Unit * GRAB_DISTANCE

	local result = workspace:Raycast(origin, direction, rayParams)

	if result and result.Instance then
		if CollectionService:HasTag(result.Instance, "ledge") then
			return result.Instance, result.Position, result.Normal
		end
	end

	return nil
end

-- Grab logic
local function grabLedge(ledgePart, hitPosition, hitNormal)
	isGrabbing = true
	grabbedLedge = ledgePart

	-- Disable platform stand to allow climbing
	humanoid.PlatformStand = true
	root.Anchored = true

	-- Calculate the top of the ledge at the hit position
	local ledgeCFrame = ledgePart.CFrame
	local ledgeUp = ledgeCFrame.UpVector
	local ledgeRight = ledgeCFrame.RightVector
	local ledgeLook = ledgeCFrame.LookVector
	local ledgeFront = ledgeCFrame.FrontVector
	local ledgeBack =  ledgeCFrame.BackVector
	local ledgeTop = ledgeCFrame.UpVector * ledgePart.Size.Y / 2
	local ledgeBottom = ledgeCFrame.UpVector * -ledgePart.Size.Y / 2
	local ledgeLeft = ledgeCFrame.LeftVector
	
	-- Calculate offset from ledge center using player's position (not hit position)
	-- This keeps the player at their lateral position relative to the ledge
	local offsetFromCenter = root.Position - ledgeCFrame.Position
	local rightOffset = offsetFromCenter:Dot(ledgeRight)
	local lookOffset = offsetFromCenter:Dot(ledgeLook)
	
	-- Clamp to stay within ledge bounds
	rightOffset = math.clamp(rightOffset, -ledgePart.Size.X/2 + 1, ledgePart.Size.X/2 - 1)
	lookOffset = math.clamp(lookOffset, -ledgePart.Size.Z/2 + 1, ledgePart.Size.Z/2 - 1)
	
	-- Calculate the edge position (where player should grab)
	local edgePosition = ledgeCFrame.Position + 
		(ledgeRight * rightOffset) + 
		(ledgeLook * lookOffset) + 
		(ledgeUp * (ledgePart.Size.Y / 2))
	
	-- Position player slightly below the ledge edge
	local grabHeight = 3.5 -- How far below the ledge to grab
	local newPosition = edgePosition - (ledgeUp * grabHeight)
	
	-- Push player back from the edge using the ledge's forward direction (not hitNormal)
	-- This is more reliable than hitNormal which can be unpredictable
	local pushBackDistance = 1.5
	newPosition = newPosition - (ledgeCFrame.LookVector * pushBackDistance)
	
	-- Face the ledge using the ledge's backward direction
	local lookDirection = ledgeCFrame.LookVector
	
	-- Create a stable CFrame with proper up vector
	local rightVector = lookDirection:Cross(Vector3.new(0, 1, 0)).Unit
	local upVector = rightVector:Cross(lookDirection).Unit
	root.CFrame = CFrame.fromMatrix(newPosition, rightVector, upVector, lookDirection)
	
	-- Stop any spinning by zeroing out angular velocity
	root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

-- Release logic
local function releaseLedge()
	isGrabbing = false
	grabbedLedge = nil

	root.Anchored = false
	humanoid.PlatformStand = false
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	
	-- Give a small boost upward
	root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E and not isGrabbing then
		local ledge, hitPos, hitNormal = findLedge()
		if ledge then
			grabLedge(ledge, hitPos, hitNormal)
		end
	elseif input.KeyCode == Enum.KeyCode.Space and isGrabbing then
		releaseLedge()
	end
end)

-- Reset if character respawns
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	
	-- Reset state
	isGrabbing = false
	grabbedLedge = nil
	
	-- Update raycast filter with new character
	updateRaycastFilter()
end)

-- Initialize raycast filter
updateRaycastFilter()