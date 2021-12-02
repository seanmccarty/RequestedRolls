function action(draginfo)

	local aParty = {};
	for _,v in pairs(window.getSelectedChars()) do
		local rActor = ActorManager.resolveActor(v);
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local sAbilityStat = DB.getValue("requestsheet.checkselected", ""):lower();
	
	ModifierStack.lock();
	for _,v in pairs(aParty) do
		performInitRoll(v);
	end
	ModifierStack.unlock(true);

	return true;
end

function onButtonPress()
    if (table.getn(window.getSelectedChars())>0) then
        return action();
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