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
			if DB.getValue(nodeSkill, "name", ""):lower() == sSkill then
				rRoll = ActionSkill.getRoll(rActor, nodeSkill);
				break;
			end
		end
	else
		local aSkills = RRRollManager.parseComponents(nodeActor);
		if aSkills then
			for k,node in pairs(aSkills) do
				if string.lower(node.sLabel) ==  string.lower(sSkill) then
					rRoll = {};
					rRoll.sType = "skill";
					rRoll.aDice = { "d20" };
					rRoll.sDesc = "[SKILL] " .. sSkill;
					rRoll.nMod = node.nMod;
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

---Copied from ActionSave.performConcentrationRoll
---@param rActor table the actor
---@return table rRoll the roll
function getConcentrationRoll(rActor)
	local rRoll = { };
	rRoll.sType = "concentration";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getSave(rActor, "constitution");
	rRoll.nMod = nMod;

	rRoll.sDesc = "[CONCENTRATION]";
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	return rRoll;
end