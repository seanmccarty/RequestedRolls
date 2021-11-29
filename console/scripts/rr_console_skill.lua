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
    local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if sNodeType ~= "pc" then

		return;
	end

	local rRoll = nil;
	for _,v in pairs(DB.getChildren(nodeActor, "skilllist")) do
		if DB.getValue(v, "name", "") == sSkill then
			rRoll = ActionSkill.getRoll(rActor, v);
			break;
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