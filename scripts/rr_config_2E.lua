---When ruleset is 2E, overrides the standard RR get(Type)Roll
---2E does not define save_ltos and this is needed for the auto build for saves to work
function onInit()
	--in the other rulesets, save_ltos  uses the save name as the array key you can lookup against
	local aSave = {};
	for _,w in ipairs(DataCommon.pssavedata) do
		aSave[w] = 1;
	end
	DataCommon.save_ltos = aSave;

	RRRollManager.registerRollGetter("save",getSaveRoll);
	RRRollManager.registerRollGetter("check",getCheckRoll);
	RRRollManager.registerRollGetter("skill",getSkillRoll)
end

---2E uses the score from the character rather than a GM decided difficulty. The target DC is pulled the same way as the charsheet.
---@param rActor table the actor to roll
---@return table rRoll the roll to be done
function getCheckRoll(rActor, sCheck)
	-- local sCheck = DB.getValue("requestsheet.check.selected", ""):lower();
	local nodeActor = ActorManager.getCreatureNode(rActor);
	local nTargetDC = DB.getValue(nodeActor, "abilities.".. sCheck .. ".score", 0);
	local rRoll = ActionCheck.getRoll(rActor, sCheck, nTargetDC);

	return rRoll;
end


---2E does not have an equivalent getRoll for saves. This is pulled from perform roll. The target DC is pulled the same way as the charsheet.
---@param rActor table the actor to roll
---@return table rRoll the roll to be done
function getSaveRoll(rActor,sSave)
	-- local sSave = DB.getValue("requestsheet.save.selected", ""):lower();
	local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManagerADND.getSave(rActor, sSave);
	rRoll.nMod = nMod;
	local sPrettySaveText = DataCommon.saves_stol[sSave];
	rRoll.sDesc = "[SAVE] vs. " .. StringManager.capitalize(sPrettySaveText);
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);

	local nTargetDC = DB.getValue(nodeActor, "saves." .. sSave .. ".score", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	return rRoll;
end

---2E has the skills for NPCs defined the same way as PCs unlike 5E or the other rulesets. The target DC is pulled the same way as the charsheet.
---@param rActor table the actor to roll
---@return table rRoll the roll to be done
function getSkillRoll(rActor, sSkill)
	-- local sSkill = DB.getValue("requestsheet.skill.selected", "");
	local rRoll = nil;
	local nodeActor = ActorManager.getCreatureNode(rActor);
	for _,nodeSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
		if DB.getValue(nodeSkill, "name", ""):lower() == sSkill then
			local nTargetDC = DB.getValue(nodeSkill, "total", 20);
			rRoll = ActionSkill.getRoll(rActor, nodeSkill, nTargetDC);
			break;
		end
	end

	if not rRoll then
		rRoll = ActionSkill.getUnlistedRoll(rActor, sSkill);
	end

	return rRoll;
end
