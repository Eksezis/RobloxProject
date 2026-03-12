-- @ScriptType: LocalScript
for _,v in game.ReplicatedStorage.Resources.Movement:GetChildren() do
	if v:IsA("ModuleScript") then
		local module = require(v)
		module:init()
	end
end

--browar