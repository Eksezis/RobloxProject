-- @ScriptType: ModuleScript
-- || Made by: @a2x4440 || --

local RunConfig = {}

print("RunConfig module loaded")

-- \\ SETTINGS \\

RunConfig.BaseWalkSpeed = 16
RunConfig.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
RunConfig.RunSpeed = 25 -- Speed while running
RunConfig.SprintSpeed = 32.67 -- Speed while sprinting

RunConfig.WalkFov = workspace.Camera.FieldOfView
RunConfig.RunFov = 80 -- Camera FieldOfView while running
RunConfig.SprintFov = 85 -- Camera FieldOfView while sprinting

RunConfig.CanRun = true -- If the player is able to run
RunConfig.CanSprint = true -- If the player is able to sprint

RunConfig.RunKey = Enum.KeyCode.LeftShift -- The key to press to run
RunConfig.TransitionSpeed = 0.5 -- Time it takes to go from walking to running
RunConfig.SprintTransitionSpeed = 3 -- Time it takes before you start sprinting

RunConfig.RunAnimationId = "rbxassetid://1234567890" -- EXAMPLE: "rbxassetid://1234567890"
-- RunConfig.SprintAnimationId = "rbxassetid://132238923550570" -- Your custom sprint animation (ID seems incorrect)
RunConfig.SprintAnimationId = "rbxassetid://1773420659" -- Known working R6 sprint animation for testing

-- Animation from BestRunAnimR6 Sprint model (KeyframeSequences cannot be used at runtime)
-- RunConfig.SprintAnimationInstance = game.ReplicatedStorage.SprintAnimation
RunConfig.ChangeAnimationProirity = true -- Turn this off if your animations are bugging

































-- !!WARNING: DO NOT CHANGE!! --
RunConfig.Walking = false
RunConfig.Running = false
RunConfig.Sprinting = false
RunConfig.Crouching = false
RunConfig.Sliding = false
RunConfig.WallRunning = false

print("RunConfig settings loaded:")
print("CanRun:", RunConfig.CanRun)
print("CanSprint:", RunConfig.CanSprint)
print("RunKey:", RunConfig.RunKey.Name)
print("RunSpeed:", RunConfig.RunSpeed)
print("SprintAnimationId:", RunConfig.SprintAnimationId)

return RunConfig
