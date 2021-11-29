function onButtonPress()
    if (table.getn(RRConsole.getSelectedChars())>0) then
        return action();
    end
end	

function action(draginfo)

	local aParty = {};
	for _,v in pairs(RRConsole.getSelectedChars()) do
		local rActor = ActorManager.resolveActor(v);
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local sAbilityStat = DB.getValue("requestsheet.skillselected", "");
	
	ModifierStack.lock();
	for _,v in pairs(aParty) do
		performSkillRoll(v, sAbilityStat);
	end
	ModifierStack.unlock(true);

	return true;
end

function performSkillRoll(rActor, sSkill)
	local rRoll = nil;
    local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);

	if sNodeType ~= "pc" then
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
				
					if Session.IsHost and CombatManager.isCTHidden(ActorManager.getCTNode(rActor)) then
						rRoll.bSecret = true;
					end
					break;
				end
			end	
		end
		if not rRoll then 
			rRoll = {};
			rRoll.sType = "skill";
			rRoll.aDice = { "d20" };
			
			local nMod = 0;
			local bADV = false;
			local bDIS = false;
			local sAddText = "";
			
			local sAbility = nil;
			if DataCommon.skilldata[sSkill] then
				sAbility = DataCommon.skilldata[sSkill].stat;
			end
			if sAbility then
				nMod, bADV, bDIS, sAddText = ActorManager5E.getCheck(rActor, sAbility, sSkill);
			end
			
			rRoll.nMod = nMod;
				
			rRoll.sDesc = "[SKILL] " .. sSkill;
			if sAddText and sAddText ~= "" then
				rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
			end
			if bADV then
				rRoll.sDesc = rRoll.sDesc .. " [ADV]";
			end
			if bDIS then
				rRoll.sDesc = rRoll.sDesc .. " [DIS]";
			end
		end
	else
		for _,v in pairs(DB.getChildren(nodeActor, "skilllist")) do
			if DB.getValue(v, "name", "") == sSkill then
				rRoll = ActionSkill.getRoll(rActor, v);
				break;
			end
		end

	end

	if not rRoll then
		rRoll = ActionSkill.getUnlistedRoll(rActor, sSkill);
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