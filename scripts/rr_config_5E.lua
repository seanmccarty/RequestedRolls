---5E specific roll configurations
function onInit()
	RRRollManager.registerRollGetter("check",getCheckRoll)
	RRRollManager.registerRollGetter("skill",getSkillRoll);
	RRRollManager.registerRollGetter("concentration", getConcentrationRoll);
end

---5E uses a different name for the script
function getCheckRoll(rActor, sCheck)
	return ActionCheck.getRoll(rActor, sCheck);
end

---5E specific skill lookup
---@param rActor any the actor to roll
---@param sSkill any the skill to be rolled
---@return table rRoll
function getSkillRoll(rActor, sSkill)
	local rRoll = nil;
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if ActorManager.isPC(rActor) then
		for _,nodeSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
			if DB.getValue(nodeSkill, "name", ""):lower() == sSkill:lower() then
				rRoll = ActionSkill.getRoll(rActor, nodeSkill);
				break;
			end
		end
	else
		local aSkills = RRRollManager.parseComponents(nodeActor);
		if aSkills then
			for k,node in pairs(aSkills) do
				if string.lower(node.sLabel) ==  string.lower(sSkill) then
					rRoll = ActionSkill.getNPCRoll(rActor, sSkill, node.nMod)
					break;
				end
			end	
		end
	end
	if not rRoll then
		rRoll = ActionSkill.getUnlistedRoll(rActor, sSkill);
	end

	return rRoll;
end

---5E specific concentration roll
---@param rActor table the actor
---@return table rRoll the roll
function getConcentrationRoll(rActor)
	return ActionSave.getConcentrationRoll(rActor);
end