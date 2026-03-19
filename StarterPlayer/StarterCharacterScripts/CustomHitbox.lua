-- @ScriptType: LocalScript
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local RunConfig = require(game.ReplicatedStorage.RunConfig)

-- Create custom hitbox
local hitbox = Instance.new("Part")
hitbox.Name = "CustomHitbox"
hitbox.Size = Vector3.new(4.2, 5.5, 2)
hitbox.Transparency = 0.5
hitbox.CanCollide = true
hitbox.Anchored = false
hitbox.Parent = character

-- Weld hitbox to HumanoidRootPart
local weld = Instance.new("Weld")
weld.Name = "HitboxWeld"
weld.Part0 = root
weld.Part1 = hitbox
weld.C0 = CFrame.new(0, -0.2, 0)
weld.Parent = root

-- Only disable collisions for torso/upper body parts
for _, part in ipairs(character:GetDescendants()) do
	if part:IsA("BasePart") and part ~= hitbox then
		if part.Name ~= "LeftFoot" and part.Name ~= "RightFoot" and part.Name ~= "LowerTorso" then
			part.CanCollide = false
		end
	end
end

-- Track crouch state
local crouched = false

-- Helper function to set hitbox instantly
local function setHitbox(size, offset)
	hitbox.Size = size
	weld.C0 = CFrame.new(offset)
end

-- Helper function to smoothly lerp hitbox size and offset
local function lerpHitbox(targetSize, targetOffset, duration)
	local startSize = hitbox.Size
	local startOffset = weld.C0.Position
	local elapsed = 0
	while elapsed < duration do
		local dt = RunService.RenderStepped:Wait()
		elapsed = elapsed + dt
		local alpha = math.clamp(elapsed / duration, 0, 1)
		hitbox.Size = startSize:Lerp(targetSize, alpha)
		local newPos = startOffset:Lerp(targetOffset, alpha)
		weld.C0 = CFrame.new(newPos)
	end
	hitbox.Size = targetSize
	weld.C0 = CFrame.new(targetOffset)
end

-- Check if there is space above to uncrouch
local function canUncrouch()
	local normalHeight = 5.5
	local origin = root.Position
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {character}
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local ray = workspace:Raycast(origin, Vector3.new(0, normalHeight - hitbox.Size.Y, 0), params)
	return not ray
end


UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Prevent jump via Space key
	if input.KeyCode == Enum.KeyCode.Space and crouched then
		humanoid.Jump = false
	end

	-- Crouch / Slide
	if input.KeyCode == Enum.KeyCode.C then
		-- Sliding while sprinting
		if RunConfig.Sprinting then
			setHitbox(Vector3.new(4.2, 2.2, 2), Vector3.new(0, -1.8, 0))
			print("Sliding 🔼")
			task.spawn(function()
				lerpHitbox(Vector3.new(4.2, 5.5, 2), Vector3.new(0, -0.2, 0), 2)
				print("Slide finished, hitbox normal 🔽")
			end)
		elseif not RunConfig.Running then
			-- Normal crouch toggle
			if crouched then
				if canUncrouch() then
					crouched = false
					setHitbox(Vector3.new(4.2, 5.5, 2), Vector3.new(0, -0.2, 0))
					print("Uncrouched 🔽")
				else
					print("Cannot uncrouch, space blocked!")
				end
			else
				crouched = true
				setHitbox(Vector3.new(4.2, 2.2, 2), Vector3.new(0, -1.8, 0))
				print("Crouched 🔼")
			end
		end
	end
end)

-- Single RunService loop for keeping collisions off
RunService.Stepped:Connect(function()
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part ~= hitbox then
			if part.Name ~= "LeftFoot" and part.Name ~= "RightFoot" and part.Name ~= "LowerTorso" then
				part.CanCollide = false
			end
		end
	end
end)

print("Custom hitbox with slide/crouch and jump-prevention loaded ✅")