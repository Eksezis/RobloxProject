-- @ScriptType: ModuleScript
local PlayerMovement = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RunConfig = require(game.ReplicatedStorage.RunConfig)

-- === Slide Settings ===
local slideActive = false
local slideCooldown = false
local slideMultiplier = 0.8
local slideDeceleration = 25
local slideCameraOffset = Vector3.new(0, -1.5, 0)
local slideCameraTilt = math.rad(8)
local slideTweenTime = 0.25
local slideSlowdownMultiplier = 0.5
local slideSlowdownDuration = 1.2 -- faster, smoother slowdown
local slideCooldownTime = 5

-- === Crouch Settings ===
local crouchActive = false
local crouchSpeedMultiplier = 0.5
local crouchHipHeightMultiplier = 0.4
local crouchCameraOffset = Vector3.new(0, -1.5, 0)
local crouchTweenTime = 0.25

function PlayerMovement:init()
	local plr = Players.LocalPlayer

	local function setupCharacter(char)
		local humanoid = char:WaitForChild("Humanoid")
		local root = char:WaitForChild("HumanoidRootPart")
		local originalHipHeight = humanoid.HipHeight
		local originalWalkSpeed = humanoid.WalkSpeed
		local originalCameraOffset = humanoid.CameraOffset

		-- Helper to check if player can stand
		local function canStand()
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {char}
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			local result = workspace:Raycast(root.Position, Vector3.new(0,3,0), rayParams)
			return result == nil
		end

		UIS.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.KeyCode ~= Enum.KeyCode.C then return end

			-- --- Slide ---
			if RunConfig.Sprinting and not slideActive and not slideCooldown and not RunConfig.Crouching then
				slideActive = true
				RunConfig.Sliding = true
				slideCooldown = true

				-- Camera tween for offset
				local cameraTween = TweenService:Create(
					humanoid,
					TweenInfo.new(slideTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{CameraOffset = slideCameraOffset}
				)
				cameraTween:Play()

				-- Reduce hitbox
				humanoid.HipHeight = originalHipHeight * 0.05

				local direction = root.CFrame.LookVector
				local currentSpeed = humanoid.WalkSpeed * slideMultiplier
				local cam = workspace.CurrentCamera
				local initialFOV = cam.FieldOfView
				local targetFOV = initialFOV - 5 -- slightly zoom in

				local conn
				conn = RunService.RenderStepped:Connect(function(delta)
					-- Smooth tilt left proportional to speed
					local tiltAngle = -slideCameraTilt * (currentSpeed / (humanoid.WalkSpeed * slideMultiplier))
					cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, tiltAngle * delta * 10)

					-- Smoothly zoom in
					cam.FieldOfView = cam.FieldOfView + (targetFOV - cam.FieldOfView) * delta * 5

					if currentSpeed <= 0 then
						conn:Disconnect()
						slideActive = false
						RunConfig.Sliding = false

						-- Tween camera offset back
						local resetTween = TweenService:Create(
							humanoid,
							TweenInfo.new(slideTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{CameraOffset = originalCameraOffset}
						)
						resetTween:Play()

						-- Restore hitbox
						humanoid.HipHeight = originalHipHeight

						-- Smoothly restore FOV
						task.spawn(function()
							while math.abs(cam.FieldOfView - initialFOV) > 0.1 do
								cam.FieldOfView = cam.FieldOfView + (initialFOV - cam.FieldOfView) * delta * 5
								task.wait()
							end
							cam.FieldOfView = initialFOV
						end)

						-- --- Smooth slowdown preserving momentum ---
						local finalVelocity = root.Velocity
						local slowdownTime = 0

						local slowdownConn
						slowdownConn = RunService.RenderStepped:Connect(function(slowDelta)
							slowdownTime = slowdownTime + slowDelta
							local t = math.clamp(slowdownTime / slideSlowdownDuration, 0, 1)

							-- interpolate speed between slide velocity and normal WalkSpeed
							local targetSpeed = originalWalkSpeed
							local currentMag = finalVelocity.Magnitude * (1 - t) + targetSpeed * t

							-- preserve direction from slide
							local moveDir = finalVelocity.Unit
							if moveDir.Magnitude == 0 then moveDir = root.CFrame.LookVector end
							root.Velocity = moveDir * currentMag
							humanoid.WalkSpeed = targetSpeed

							if t >= 1 then
								slowdownConn:Disconnect()
								humanoid.WalkSpeed = originalWalkSpeed
							end
						end)

						-- Cooldown
						task.delay(slideCooldownTime, function()
							slideCooldown = false
						end)

						return
					end

					-- Reduce speed over time
					currentSpeed = currentSpeed - slideDeceleration * delta
					if currentSpeed < 0 then currentSpeed = 0 end
				end)

				return
			end

			-- --- Crouch ---
			if not slideActive and not RunConfig.Sliding then
				if not crouchActive then
					if RunConfig.Sprinting or RunConfig.Running then return end
					crouchActive = true
					RunConfig.Crouching = true

					local hipTween = TweenService:Create(
						humanoid,
						TweenInfo.new(crouchTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{HipHeight = originalHipHeight * crouchHipHeightMultiplier}
					)
					local camTween = TweenService:Create(
						humanoid,
						TweenInfo.new(crouchTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{CameraOffset = crouchCameraOffset}
					)

					hipTween:Play()
					camTween:Play()
					humanoid.WalkSpeed = originalWalkSpeed * crouchSpeedMultiplier

				else
					if not canStand() then return end
					crouchActive = false
					RunConfig.Crouching = false

					local hipTween = TweenService:Create(
						humanoid,
						TweenInfo.new(crouchTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{HipHeight = originalHipHeight}
					)
					local camTween = TweenService:Create(
						humanoid,
						TweenInfo.new(crouchTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{CameraOffset = originalCameraOffset}
					)

					hipTween:Play()
					camTween:Play()
					humanoid.WalkSpeed = originalWalkSpeed
				end
			end
		end)
	end

	if plr.Character then
		setupCharacter(plr.Character)
	end

	plr.CharacterAdded:Connect(setupCharacter)
end

return PlayerMovement