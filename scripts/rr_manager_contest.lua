function onInit()
	if Session.IsHost then
		DB.createNode("requestsheet.contest");
		DB.setPublic("requestsheet.contest",true);
	end

	-- insert into list of Actions and targetactions so that CombatDropManager and ActionsManager.actionDrop will process drops on the combat tracker
	ActionsManager.initAction("contest");
	table.insert(GameSystem.targetactions, "contest");
end

function getRollType(sNode)
	return DB.getValue(sNode..".rollType","");
end

-- TODO not just first
function getFirstTargetSubType(sNode)
	return DB.getValue(sNode..".subtypes.id-00002.type","");
end
function getFirstOriginSubType(sNode)
	return DB.getValue(sNode..".subtypes.id-00001.type","");
end

function setupContestRoll(contestNode, rActor)
	local fRollResult = RRRollManager.getRollGetter(RRContestManager.getRollType(contestNode));
	local rRoll = fRollResult(rActor, RRContestManager.getFirstOriginSubType(contestNode));
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
		local rollType = rRoll.sType;
		local subType = RRContestManager.getFirstTargetSubType(rRoll.contestNode);
		-- TODO rolls without a subType, such as initiative
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
		RRRollManager.requestRoll(rollType, subType, rTargets, rRoll.bSecret, nTotal, "Contest with "..ActorManager.getDisplayName(rSource).." vs DC "..tostring(nTotal));
		-- Debug.chat("old", rRoll,rTarget, "rSource",rSource)
	end
end
