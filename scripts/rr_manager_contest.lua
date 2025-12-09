function onInit()
	if Session.IsHost then
		DB.createNode("requestsheet.contest");
		DB.setPublic("requestsheet.contest",true);
	end

	-- insert into list of Actions and targetactions so that CombatDropManager and ActionsManager.actionDrop will process drops on the combat tracker
	ActionsManager.initAction("contest");
	table.insert(GameSystem.targetactions, "contest");

end

function getRollType()
	return DB.getValue("requestsheet.contest.id-00001.rollType","");
end

-- TODO not just first
function getFirstTargetSubType()
	return DB.getValue("requestsheet.contest.id-00001.subtypes.id-00002.type","");
end