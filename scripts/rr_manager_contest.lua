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
function RREffectNotifyExpire(varEffect, nMatch, bImmediate)
	if not bSuspend then
		fOriginalEffectNotifyExpire(varEffect, nMatch, bImmediate);
	end
end

local aModHandlers = {};
function registerModGetter(sActionType, callback)
	aModHandlers[sActionType] = callback;
end

function getRollType(sNode)
	return DB.getValue(sNode..".rollType","");
end

function getSubTypes(sNode, bIsOriginator)
	local sComparator = "target";
	if bIsOriginator then
		sComparator = "originator";
	end
	local tSubTypes = {};
	for _,v in pairs(DB.getChildren(sNode..".subtypes")) do
		if DB.getValue(v,"origin","")==sComparator then
			table.insert(tSubTypes,DB.getValue(v,"type",""));
		end
	end
	return tSubTypes;
end

function getBestSubType(rActor,sType,tSubTypes)
	if not tSubTypes then 
		return nil;
	end
	if #tSubTypes==1 then
		return tSubTypes[1];
	end
	local fRollResult = RRRollManager.getRollGetter(sType);
	local fModResult = aModHandlers[sType];
	ActionsManager.lockModifiers()
	bSuspend = true;
	local sBest = "";
	local nBest = -99;
	for _,sSubType in pairs(tSubTypes) do
			
		local rRoll = fRollResult(rActor, sSubType);
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

function setupContestRoll(contestNode, rActor)
	local sType = RRContestManager.getRollType(contestNode);
	local tSubTypes = RRContestManager.getSubTypes(contestNode,true);
	local sBestSubType = RRContestManager.getBestSubType(rActor, sType, tSubTypes);
	local fRollResult = RRRollManager.getRollGetter(sType);
	local rRoll = fRollResult(rActor, sBestSubType);
	rRoll.bContest = true;
	rRoll.contestNode = contestNode;

	return rRoll;
end

function onDragStart(contestNode, rActor, draginfo)
	local rRoll = RRContestManager.setupContestRoll(contestNode, rActor);
	ActionsManager.performAction(draginfo, rActor, rRoll);
	draginfo.setType("contest");
	return true;
end

function onButtonPress(contestNode, rActor)
	local rRoll = RRContestManager.setupContestRoll(contestNode, rActor);
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

function finishContest(rSource, rTarget, rRoll)
	if rRoll.bContest then
		local sType = rRoll.sType;
		local tSubTypes = RRContestManager.getSubTypes(rRoll.contestNode,false);
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
