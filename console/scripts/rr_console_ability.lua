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
	
	local sAbilityStat = DB.getValue("requestsheet.checkselected", ""):lower();
	
	ModifierStack.lock();
	for _,v in pairs(aParty) do
		ActionCheck.performPartySheetRoll(nil, v, sAbilityStat);
	end
	ModifierStack.unlock(true);

	return true;
end

function onButtonPress()
    if (table.getn(RRConsole.getSelectedChars())>0) then
        return action();
    end
end	