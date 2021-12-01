function onButtonPress()
    if (table.getn(window.getSelectedChars())>0) then
        return action();
    end
end	

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
	
	local sDice = DB.getValue("requestsheet.diceselected", ""):lower();
	
	ModifierStack.lock();
	for _,v in pairs(aParty) do
		performDiceRoll(v, sDice);
	end
	ModifierStack.unlock(true);

	return true;
end

function performDiceRoll(rActor, sDice)
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
    
    if sDice=="d20" then
		ActionsManager2.encodeAdvantage(rRoll);
    end

	ActionsManager.performAction(nil, rActor, rRoll);
end