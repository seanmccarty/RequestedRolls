local DICE = "dice";

---Add the new dice handlers needed for arbitrary dice, this is only used for rulesets that already have a handler for dice
---Most rulesets use common script names. See the configuration files for specific overrides.
function onInit()
	if ActionsManager2 then
		ActionsManager.registerModHandler("sDice",modSDiceRoll);
		DICE = "sDice";
	end

	registerRollGetter("init",getInitRoll);
	registerRollGetter("dice",getDiceRoll);
	registerRollGetter("save",getSaveRoll);
	registerRollGetter("check",getCheckRoll);
	registerRollGetter("skill",getSkillRoll);
	registerRollGetter("table",getTableRoll);
end

local aRollHandlers = {};
function registerRollGetter(sActionType, callback)
	aRollHandlers[sActionType] = callback;
end
function unregisterRollGetter(sActionType)
	if aRollHandlers then
		aRollHandlers[sActionType] = nil;
	end
end

function getRollGetter(sActiontype)
	return aRollHandlers[sActiontype] or nil;
end

---Determine which ruleset dependent handlers are available
---@return table handlers all registered handlers currently available
function listAvailableHandlers()
	local list = {};
	for k, _ in pairs(aRollHandlers) do
		table.insert(list,k);
	end
	return list;
end

---Advantage doesn't apply to the advanced dice commands, and this need to return true
function modSDiceRoll(rSource, rTarget, rRoll)
	ActionsManager2.encodeDesktopMods(rRoll);
	return true;
end

---Initate a roll request from the console or a chat command
---Parameters except for sRollType and tActors are optional
---If a client initiates the roll, it is passed to the host so it can then pass it to the correct client for popup
---@param sRollType string the registered primary roll type to be rolled, e.g. skill
---@param sSubType string|nil the specific stat for the roll, e.g. Perception
---@param tActors table database nodes of the actors that will be executing the rolls
---@param bSecret boolean|nil
---@param nTargetDC number|nil
---@param sDesc string|nil
function requestRoll(sRollType, sSubType, tActors, bSecret, nTargetDC, sDesc)
	if not Session.IsHost then
		local tTransfer = {};
		tTransfer.sRollType = sRollType;
		tTransfer.sSubType = sSubType;
		tTransfer.tActors = tActors;		
		tTransfer.bSecret = bSecret;
		tTransfer.nTargetDC = nTargetDC;
		tTransfer.sDesc = sDesc;
		RR.notifyApplyRollRequestRR(tTransfer);

		local msg = {text = "Requested roll sent to host for execution.", secret=true};
		Comm.addChatMessage(msg);
		return;
	end
	if tActors==nil or #tActors==0 then
		ChatManager.SystemMessage("No valid actors for roll.");
		return;
	end

	local fRollResult = aRollHandlers[sRollType];
	if not fRollResult then
		ChatManager.SystemMessage("Roll type does not exist.");
		return;
	end

	ModifierStack.lock();
	local rRoll = {};
	local sActors = "";
	for _,rActor in pairs(tActors) do
		rRoll = fRollResult(rActor, sSubType);
		rRoll.RR = true;
		if not (Interface.getRuleset()=="2E") then
			rRoll.nTarget = nTargetDC;
		end
		if bSecret == true then
			rRoll.bSecret = true;
			rRoll.bTower = true;
		end

		if sDesc then
			rRoll.sDesc = rRoll.sDesc .. " " .. sDesc;
		end
	
		ActionsManager.performAction(nil, rActor, rRoll);
		sActors = sActors..ActorManager.getDisplayName(rActor).."; ";
	end
	ModifierStack.unlock(true);
	local msg = {text = "Requested "..rRoll.sDesc.. "- "..sActors, secret=true};
	Comm.addChatMessage(msg);
end

---Main entry point for kicking off rolls from the console
---@param sRollType string the roll type to be made
---@param nodeCT table optional - the database node of a single target for drop targeting. 
---                    If not given, it uses the selected characters from the console
---@return boolean end not used
function onButtonPress(sRollType,nodeCT)
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
		end
	end
	-- if #aParty == 0 then
	-- 	aParty = nil;
	-- end

	-- tables are case-sensitive, all other rolls are lowercase for comparison
	local sSubType = DB.getValue("requestsheet.rolls."..sRollType..".selected", "");
	if sRollType~="table" then
		sSubType = DB.getValue("requestsheet.rolls."..sRollType..".selected", ""):lower();
	end
	local nTargetDC = DB.getValue("requestsheet.rolls."..sRollType..".dc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end

	local bSecret=false;
	if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		bSecret = true;
	end

	local sDesc = DB.getValue("requestsheet.rollreason", nil);

	requestRoll(sRollType, sSubType, aParty, bSecret, nTargetDC, sDesc)

		
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
function getDiceRoll(rActor, sDice)
	local rRoll = {};
	if DiceManager.isDiceString(sDice) then
		rRoll.sType = "dice"
		local aDice, nMod = DiceManager.convertStringToDice(sDice, true)
		rRoll.aDice = DiceRollManager.getActorDice(aDice, rActor);
		rRoll.nMod = nMod;
	else
		rRoll.sType = DICE;
		rRoll.aDice = {};
		rRoll.aDice.expr = sDice;
		rRoll.nMod = 0;

	end
    rRoll.sDesc = "[DICE] Roll a " .. sDice;

	if (Interface.getRuleset()=="5E" or Interface.getRuleset()=="Shadowdark") and  rRoll.aDice[1].type == "d20" then
		ActionsManager2.encodeAdvantage(rRoll);
    end

    return rRoll;
end

function getCheckRoll(rActor, sCheck)
	return ActionAbility.getRoll(rActor, sCheck);
end

function getSaveRoll(rActor, sSave)
	return ActionSave.getRoll(rActor, sSave);
end

---This lookup is used by rulesets other than 5E
---@param rActor any the actor to roll
---@param sSkill any the skill to be rolled
---@return table rRoll
function getSkillRoll(rActor, sSkill)
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

---Modified from TablerManager.performRoll
---@param _ any typically rActor, unused
---@param sTableName string the full name of the table, case-sensitive
---@return table rRoll 
function getTableRoll(_, sTableName)
	local nodeTable = TableManager.findTable(sTableName)
	local rRoll = {};
	rRoll.aDice, rRoll.nMod = TableManager.getTableDice(nodeTable);
	rRoll.sType = "table";
	rRoll.sDesc = string.format("[%s] %s", Interface.getString("table_tag"), StringManager.capitalizeAll(DB.getValue(nodeTable, "name", "")));
	rRoll.sNodeTable = DB.getPath(nodeTable);

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