local DICE = "dice";

---Add the new dice handlers needed for arbitrary dice, this is only used for rulesets that already have a handler for dice
function onInit()
	if ActionsManager2 then
		ActionsManager.registerModHandler("sDice",modSDiceRoll);
		DICE = "sDice";
	end
	
end

---Advantage doesn't apply to the advanced dice commands, and this need to return true
function modSDiceRoll(rSource, rTarget, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);
	return true;
end

---Main entry point for kicking off rolls from the console
---@param rollType string the roll type to be made
---@param nodeCT table optional - the database node of a single target for drop targeting. 
---                    If not given, it uses the selected characters from the console
---@return boolean end not used
function onButtonPress(rollType,nodeCT)
	local aParty = {};
	if nodeCT ~= nil then
		local rActor = ActorManager.resolveActor(nodeCT);
		if rActor then
			table.insert(aParty, rActor);
		end
	else
		if (table.getn(RR.getSelectedChars())>0) then
			for _,v in pairs(RR.getSelectedChars()) do
				local rActor = ActorManager.resolveActor(v);
				if rActor then
					table.insert(aParty, rActor);
				end
			end
		else
			return;
		end
	end

	if #aParty == 0 then
		aParty = nil;
		return;
	end
		
	ModifierStack.lock();
	for _,rActor in pairs(aParty) do
		local rRoll;
		if rollType == "init" then
			rRoll = getInitRoll(rActor);
		elseif rollType == "dice" then
			rRoll = getDiceRoll(rActor);
		elseif rollType == "check" then
			rRoll = getCheckRoll(rActor);
		elseif rollType == "save" then
			rRoll = getSaveRoll(rActor);
		elseif rollType == "skill" then
			rRoll = getSkillRoll(rActor);
		end

		rRoll.RR = true;

		if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
			rRoll.bSecret = true;
		end

		if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
			rRoll.bSecret = true;
			rRoll.bTower = true;
		end
	
		ActionsManager.performAction(nil, rActor, rRoll);
	end
	ModifierStack.unlock(true);

	if DB.getValue("requestsheet.deselectonroll",0)==1 then
		for _,entry in pairs(CombatManager.getCombatantNodes()) do
			DB.setValue(entry,"RRselected", "number", 0);
		end
	end
	return true;
end	

function getInitRoll(rActor)
	return ActionInit.getRoll(rActor, false);
end

---If it is a standard dice string, process through the normal channels.
---If it is a complex dice that uses expr, process through custom sDice handler that returns true so that ActionManager does not wipe out aDice.expr
---@param rActor any not used
---@return table rRoll 
function getDiceRoll(rActor)
	local sDice = DB.getValue("requestsheet.dice.selected", ""):lower();

	local rRoll = {};
	if DiceManager.isDiceString(sDice) then
		rRoll.sType = "dice"
		local aDice, nMod = DiceManager.convertStringToDice(sDice, true)
		rRoll.aDice = aDice;
		rRoll.nMod = nMod;
	else
		rRoll.sType = DICE;
		rRoll.aDice = {};
		rRoll.aDice.expr = sDice;
		rRoll.nMod = 0;

	end
    rRoll.sDesc = "[DICE] Roll a " .. sDice;

    if Interface.getRuleset()=="5E" and  rRoll.aDice[1] == "d20" then
		ActionsManager2.encodeAdvantage(rRoll);
    end

    return rRoll;
end

function getCheckRoll(rActor)
	local sCheck = DB.getValue("requestsheet.check.selected", ""):lower();
	local rRoll;
	if Interface.getRuleset()=="5E" then
		rRoll = ActionCheck.getRoll(rActor, sCheck);
	else
		rRoll = ActionAbility.getRoll(rActor, sCheck);
	end
	
	local nTargetDC = DB.getValue("requestsheet.check.dc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	
    return rRoll;
end

function getSaveRoll(rActor)
	local sSave = DB.getValue("requestsheet.save.selected", ""):lower();
	local rRoll = ActionSave.getRoll(rActor, sSave);
	
	local nTargetDC = DB.getValue("requestsheet.save.dc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	
    return rRoll;
end

function getSkillRoll(rActor)
	local sSkill = DB.getValue("requestsheet.skill.selected", "");
	local rRoll = {};
	
	if Interface.getRuleset()=="5E" then
		rRoll = E5skill(rActor, sSkill);
	else
		rRoll = E35skill(rActor, sSkill);
	end

	local nTargetDC = DB.getValue("requestsheet.skill.dc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	
    return rRoll;
end

---Takes a NPC and gets the skills and modifiers from its record to check its specified modifier
---@param nodeActor any the database node of the actor in question
---@return table aComponents a table of labels and modifiers found on the character
function parseComponents(nodeActor)
	local skillsString = DB.getValue(nodeActor, "skills");
	if skillsString == nil then
		return;
	end
	local aComponents = {};

	-- Get the comma-separated strings
	local aClauses, aClauseStats = StringManager.split(skillsString, ",;\r", true);

	-- Check each comma-separated string for a potential skill roll or auto-complete opportunity
	for i = 1, #aClauses do
		local nStarts, nEnds, sMod = string.find(aClauses[i], "([d%dF%+%-]+)%s*$");
		if nStarts then
			local sLabel = "";
			if nStarts > 1 then
				sLabel = StringManager.trim(aClauses[i]:sub(1, nStarts - 1));
			end
			local aDice, nMod = DiceManager.convertStringToDice(sMod);
			table.insert(aComponents, {sLabel = sLabel, nMod = nMod, });
		end
	end
	return aComponents;
end

---This lookup is used by rulesets other than 5E
---@param rActor any the actor to roll
---@param sSkill any the skill to be rolled
---@return table rRoll
function E35skill(rActor, sSkill)
	local rRoll = nil;
	local nodeActor = ActorManager.getCreatureNode(rActor);
	--if it is an NPC, parse for the particular skill. fall through if it is not found or it is a PC
	if not ActorManager.isPC(rActor) then
		local aSkills = parseComponents(nodeActor);
		if aSkills then
			for k,node in pairs(aSkills) do
				if string.lower(node.sLabel) ==  string.lower(sSkill) then
					rRoll = ActionSkill.getRoll(rActor, sSkill, node.nMod);
				end
			end
		end
	end
	-- look for the skill to have the pattern Skill (subskill) extract the part within and outside parentheses for the skill lookup
	if not rRoll then
		local sSubSkill = nil;
		local sSkillLookup = nil;
		if sSkill:match("%(%w+%)") then	
			sSubSkill = sSkill:match("%(%w+%)"):sub(2,-2);
			sSkillLookup = sSkill:match("%w+");
		else
			sSkillLookup = sSkill;
		end
		local  nSkillMod = CharManager.getSkillValue(rActor, sSkillLookup, sSubSkill);
		rRoll = ActionSkill.getRoll(rActor, sSkill, nSkillMod);
	end

	return rRoll;
end

---5E specific skill lookup
---@param rActor any the actor to roll
---@param sSkill any the skill to be rolled
---@return table rRoll
function E5skill(rActor, sSkill)
	local rRoll = nil;
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if ActorManager.isPC(rActor) then
		for _,nodeSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
			if DB.getValue(nodeSkill, "name", "") == sSkill then
				rRoll = ActionSkill.getRoll(rActor, nodeSkill);
				break;
			end
		end
	else
		local aSkills = parseComponents(nodeActor);
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