local fOriginalEffectNotifyExpire = nil;
local bSuspend = false;
function onInit()
	if Session.IsHost then
		DB.createNode("requestsheet.contest");
		DB.setPublic("requestsheet.contest",true);
	end

	fOriginalEffectNotifyExpire = EffectManager.notifyExpire;
	EffectManager.notifyExpire = RREffectNotifyExpire;

	-- insert into list of Actions and targetactions so that CombatDropManager and ActionsManager.actionDrop will process drops on the combat tracker
	ActionsManager.initAction("contest");
	table.insert(GameSystem.targetactions, "contest");
end

---Replace EffectManager.notifyExpire so that I can use the various modRolls without expiring effects that end up being unused
---Parameters match base implementation
function RREffectNotifyExpire(varEffect, nMatch, bImmediate)
	if not bSuspend then
		fOriginalEffectNotifyExpire(varEffect, nMatch, bImmediate);
	end
end

local aModHandlers = {};
function registerModGetter(sActionType, callback)
	aModHandlers[sActionType] = callback;
end

---Get roll type for specific contest roll
---@param sNode string the database path of the specific contest roll
---@return string rollType the overall type of the roll, e.g., skill, check
function getRollType(sNode)
	return DB.getValue(sNode..".rollType","");
end

---List available subTypes for the given contest roll
---@param sNode string the database path of the specific contest roll
---@param bIsOriginator boolean true if you wish to get subTypes for the originator, otherwise returns subTypes for targeted actors
---@return table tSubTypes a table of strings where each entry is an allowed subType, the table may be empty
function getSubTypes(sNode, bIsOriginator)
	local sComparator = "target";
	if bIsOriginator then
		sComparator = "originator";
	end
	local tSubTypes = {};

	-- for each child node in the contest node, if matches the actor type (originator or target), we collect the subType
	for _,v in pairs(DB.getChildren(sNode..".subtypes")) do
		if DB.getValue(v,"origin","")==sComparator then
			table.insert(tSubTypes,DB.getValue(v,"type",""));
		end
	end
	return tSubTypes;
end

---comment
---@param rActor table actor table or string
---@param sType string the main type of the roll
---@param tSubTypes string the table of subtypes they can yse
---@return string|nil sBestSubType the roll the character should use
function getBestSubType(rActor,sType,tSubTypes)
	if not tSubTypes then 
		return nil;
	end
	if #tSubTypes==1 then
		return tSubTypes[1];
	end
	local fRollResult = RRRollManager.getRollGetter(sType);
	local fModResult = aModHandlers[sType];

	-- lock the modifiers so we can get the full nMod for a roll without expiring the effect, setting suspend keeps them from being expired after the lock is lifted
	ActionsManager.lockModifiers()
	bSuspend = true;

	-- iterate through the subTypes to figure out which subType has the best numeric modifier.
	-- things like advantage or additional dice are not considered
	local sBest = "";
	local nBest = -99;
	for _,sSubType in pairs(tSubTypes) do
			
		local rRoll = fRollResult(rActor, sSubType);

		-- if this rollType has a modeRoll, use the function
		if fModResult then
			fModResult(rActor, nil, rRoll);
		end

		if rRoll.nMod>nBest then
			sBest = sSubType;
			nBest = rRoll.nMod;
		end
	end
	ActionsManager.unlockModifiers(false);
	bSuspend = false;
	return sBest;
end

---Common setup for onDragStart and onButtonPress
---@param sContestNode string the specific contest roll being executed
---@param rActor any
---@return table rRoll the rRoll to be executed
function setupContestRoll(sContestNode, rActor)
	local sType = RRContestManager.getRollType(sContestNode);
	local tSubTypes = RRContestManager.getSubTypes(sContestNode,true);
	local sBestSubType = RRContestManager.getBestSubType(rActor, sType, tSubTypes);
	local fRollResult = RRRollManager.getRollGetter(sType);
	local rRoll = fRollResult(rActor, sBestSubType);
	
	--bContest is what is used to trigger finishContest in ActionsManager.resolveAction
	rRoll.bContest = true;
	rRoll.sContestNode = sContestNode;

	return rRoll;
end

---onDragStart for rr_actions_contest_buttons
---@param sContestNode string the specific contest roll being executed
---@param rActor any
---@param draginfo any
---@return boolean isHandled indicates the drag was handled
function onDragStart(sContestNode, rActor, draginfo)
	local rRoll = RRContestManager.setupContestRoll(sContestNode, rActor);
	ActionsManager.performAction(draginfo, rActor, rRoll);

	-- set draginfo type so that CombatDropManager will process the roll, this will cease to be part of the roll after it is routed in CombatDropManager
	draginfo.setType("contest");
	return true;
end

---onButtonPress for rr_actions_contest_buttons
---@param sContestNode string the specific contest roll being executed
---@param rActor any
function onButtonPress(sContestNode, rActor)
	local rRoll = RRContestManager.setupContestRoll(sContestNode, rActor);
	local rTargets = TargetingManager.getFullTargets(rActor);
	--We have to convert target table to string or it will get lost when converted in buildThrow
	local rsTargets = {};
	for k,v in pairs(rTargets) do
		table.insert(rsTargets, ActorManager.getCreatureNodeName(v));
	end
	local sTargets = table.concat(rsTargets,"#||#");
	rRoll.contestTargets = sTargets;
	ActionsManager.performAction(nil, rActor, rRoll);
end

---Mirror parameters available in ActionsManager.resolveAction
---If the roll was setup to trigger a contest, trigger the second roll
---@param rSource any
---@param rTarget any
---@param rRoll any
function finishContest(rSource, rTarget, rRoll)
	if rRoll.bContest then
		local sType = rRoll.sType;
		local tSubTypes = RRContestManager.getSubTypes(rRoll.sContestNode,false);
		local nTotal = ActionsManager.total(rRoll);
		local rTargets = {};
		if rTarget then
			rTargets = {ActorManager.getCreatureNodeName(rTarget)};
		else
			local rsTargets = StringManager.split(rRoll.contestTargets,"#||#");
			for k,v in pairs(rsTargets) do
				table.insert(rTargets, DB.getPath(v));
			end
		end
		-- Process each target individually since they may all have different best subTypes
		for _,rTarget in pairs(rTargets) do
			local sBestSubType = RRContestManager.getBestSubType(rTarget, sType, tSubTypes);
			RRRollManager.requestRoll(sType, sBestSubType, {rTarget}, rRoll.bSecret, nTotal, "Contest with "..ActorManager.getDisplayName(rSource).." vs DC "..tostring(nTotal));
		end
		
		-- Debug.chat("old", rRoll,rTarget, "rSource",rSource)
	end
end
