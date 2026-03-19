-- @ScriptType: ModuleScript
local CrouchModule = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local RunConfig = require(game.ReplicatedStorage.RunConfig)

local crouchActive = false

-- ustawienia
local crouchSpeedMultiplier = 0.5
local crouchHipHeightMultiplier = 0.05
local cameraOffset = Vector3.new(0,-1.5,0)
local tweenTime = 0.25

function CrouchModule:init()

	local plr = Players.LocalPlayer

	local function setupCharacter(char)

		local humanoid = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")

		local originalHipHeight = humanoid.HipHeight
		local originalSpeed = humanoid.WalkSpeed
		local originalCameraOffset = humanoid.CameraOffset

		local crouchTweenInfo = TweenInfo.new(tweenTime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

		local function canStand()

			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {char}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist

			local result = workspace:Raycast(
				root.Position,
				Vector3.new(0,3,0),
				rayParams
			)

			return result == nil
		end

		UIS.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode ~= Enum.KeyCode.C then return end

			-- WŁĄCZ CROUCH
			if not crouchActive then

				if RunConfig.Sprinting then return end
				if RunConfig.Running then return end
				if RunConfig.Sliding then return end

				crouchActive = true
				RunConfig.Crouching = true

				local hipTween = TweenService:Create(
					humanoid,
					crouchTweenInfo,
					{HipHeight = originalHipHeight * crouchHipHeightMultiplier}
				)

				local camTween = TweenService:Create(
					humanoid,
					crouchTweenInfo,
					{CameraOffset = cameraOffset}
				)

				hipTween:Play()
				camTween:Play()

				humanoid.WalkSpeed = originalSpeed * crouchSpeedMultiplier

			else

				-- sprawdź czy można wstać
				if not canStand() then return end

				crouchActive = false
				RunConfig.Crouching = false

				local hipTween = TweenService:Create(
					humanoid,
					crouchTweenInfo,
					{HipHeight = originalHipHeight}
				)

				local camTween = TweenService:Create(
					humanoid,
					crouchTweenInfo,
					{CameraOffset = originalCameraOffset}
				)

				hipTween:Play()
				camTween:Play()

				humanoid.WalkSpeed = originalSpeed
			end
		end)
	end

	if plr.Character then
		setupCharacter(plr.Character)
	end

	plr.CharacterAdded:Connect(setupCharacter)

end

return CrouchModule 
-- !!!!!!!!!!!!!!!! OLD

--local CrouchModule = {}

--local Players = game:GetService("Players")
--local UIS = game:GetService("UserInputService")
--local TweenService = game:GetService("TweenService")

--local RunConfig = require(game.ReplicatedStorage.RunConfig)

--local crouchActive = false
--local inputConnection

---- settings
--local CROUCH_SPEED = 8
--local NORMAL_SPEED = 16
--local crouchHipHeightMultiplier = 0.05
--local cameraOffset = Vector3.new(0,-1.5,0)
--local tweenTime = 0.25

--function CrouchModule:init()

--	local plr = Players.LocalPlayer

--	local function setupCharacter(char)

--		local humanoid = char:WaitForChild("Humanoid")
--		local root = char:WaitForChild("HumanoidRootPart")

--		local originalHipHeight = humanoid.HipHeight
--		local originalCameraOffset = humanoid.CameraOffset

--		local crouchTweenInfo = TweenInfo.new(
--			tweenTime,
--			Enum.EasingStyle.Quad,
--			Enum.EasingDirection.Out
--		)

--		local function canStand()

--			local rayParams = RaycastParams.new()
--			rayParams.FilterDescendantsInstances = {char}
--			rayParams.FilterType = Enum.RaycastFilterType.Blacklist

--			local result = workspace:Raycast(
--				root.Position + Vector3.new(0,1,0),
--				Vector3.new(0,3,0),
--				rayParams
--			)

--			return result == nil
--		end


--		local function crouch()

--			crouchActive = true
--			RunConfig.Crouching = true

--			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)

--			local hipTween = TweenService:Create(
--				humanoid,
--				crouchTweenInfo,
--				{HipHeight = originalHipHeight * crouchHipHeightMultiplier}
--			)

--			local camTween = TweenService:Create(
--				humanoid,
--				crouchTweenInfo,
--				{CameraOffset = cameraOffset}
--			)

--			hipTween:Play()
--			camTween:Play()

--			humanoid.WalkSpeed = CROUCH_SPEED

--			-- stabilize movement
--			humanoid:Move(Vector3.zero,true)

--		end


--		local function uncrouch()

--			if not canStand() then return end

--			crouchActive = false
--			RunConfig.Crouching = false

--			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)

--			local hipTween = TweenService:Create(
--				humanoid,
--				crouchTweenInfo,
--				{HipHeight = originalHipHeight}
--			)

--			local camTween = TweenService:Create(
--				humanoid,
--				crouchTweenInfo,
--				{CameraOffset = originalCameraOffset}
--			)

--			hipTween:Play()
--			camTween:Play()

--			humanoid.WalkSpeed = NORMAL_SPEED

--			humanoid:Move(Vector3.zero,true)

--		end


--		if inputConnection then
--			inputConnection:Disconnect()
--		end

--		inputConnection = UIS.InputBegan:Connect(function(input, processed)

--			if processed then return end
--			if input.KeyCode ~= Enum.KeyCode.C then return end

--			if not crouchActive then

--				if RunConfig.Sprinting then return end
--				if RunConfig.Running then return end
--				if RunConfig.Sliding then return end

--				crouch()

--			else

--				uncrouch()

--			end

--		end)

--	end


--	if plr.Character then
--		setupCharacter(plr.Character)
--	end

--	plr.CharacterAdded:Connect(setupCharacter)

--end

--return CrouchModule