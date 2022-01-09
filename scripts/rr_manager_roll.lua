function onButtonPress(rollType)
    if (table.getn(RR.getSelectedChars())>0) then
        local aParty = {};
        for _,v in pairs(RR.getSelectedChars()) do
            local rActor = ActorManager.resolveActor(v);
            if rActor then
                table.insert(aParty, rActor);
            end
        end
        if #aParty == 0 then
            aParty = nil;
        end
            
        ModifierStack.lock();
        for _,v in pairs(aParty) do
            if rollType == "init" then
                performInitRoll(v);
            elseif rollType == "dice" then
                performDiceRoll(v);
            elseif rollType == "check" then
                performCheckRoll(v);
            elseif rollType == "save" then
                performSaveRoll(v);
            elseif rollType == "skill" then
                performSkillRoll(v);
            end
        end
        ModifierStack.unlock(true);
    
        return true;
    end
end	

function performInitRoll(rActor)
	local rRoll = ActionInit.getRoll(rActor, false);
	rRoll.RR = true;
	if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performDiceRoll(rActor)
	local sDice = DB.getValue("requestsheet.diceselected", ""):lower();

	local rRoll = {};
    rRoll.sType = "dice"
	rRoll.aDice = { sDice };
    rRoll.sDesc = "Roll a " .. sDice;
    rRoll.nMod = 0;
	rRoll.RR = true;

    if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end
    
    if User.getRulesetName()=="5E" and sDice=="d20" then
		ActionsManager2.encodeAdvantage(rRoll);
    end

	ActionsManager.performAction(nil, rActor, rRoll);
end

function performCheckRoll(rActor)

	local sCheck = DB.getValue("requestsheet.checkselected", ""):lower();
	local rRoll;
	if User.getRulesetName()=="5E" then
		rRoll = ActionCheck.getRoll(rActor, sCheck);
	else
		rRoll = ActionAbility.getRoll(rActor, sCheck);
	end
	rRoll.RR = true;
	local nTargetDC = DB.getValue("requestsheet.checkdc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performSaveRoll(rActor)
	local sSave = DB.getValue("requestsheet.saveselected", ""):lower();
	local rRoll = ActionSave.getRoll(rActor, sSave);
	rRoll.RR = true;
	local nTargetDC = DB.getValue("requestsheet.savedc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performSkillRoll(rActor)
	local sSkill = DB.getValue("requestsheet.skillselected", "");
	local rRoll = nil;
    
	if User.getRulesetName()=="5E" then
		rRoll = E5skill(rActor, sSkill);
	else
		rRoll = E35skill(rActor, sSkill);
	end

	if not rRoll then
		ChatManager.Message("This ruleset does not support unlisted rolls", false, rActor);
		return;
	end

	if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
		rRoll.bSecret = true;
	end

	rRoll.RR = true;
	local nTargetDC = DB.getValue("requestsheet.skilldc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);

end

---comment
---@param nodeActor any the database node of the actor in question
---@return table aComponents a table of labels and modifiers found on the character
function parseComponents(nodeActor)
	skillsString = DB.getValue(nodeActor, "skills");
	if skillsString == nil then
		return;
	end
	aComponents = {};

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
			local aDice, nMod = StringManager.convertStringToDice(sMod);
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
	rRoll = nil;
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
	rRoll = nil;
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
					local nMod = node.nMod;
					rRoll = {};
					rRoll.sType = "skill";
					rRoll.aDice = { "d20" };
					rRoll.sDesc = "[SKILL] " .. sSkill;
					rRoll.nMod = nMod;
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