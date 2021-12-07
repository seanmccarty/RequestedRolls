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
		performCheckRoll(v, sAbilityStat);
	end
	ModifierStack.unlock(true);

	return true;
end

function onButtonPress()
    if (table.getn(window.getSelectedChars())>0) then
        return action();
    end
end	

--originally from actionCheck.performpartysheetroll
function performCheckRoll(rActor, sCheck)
	local rRoll;
	if User.getRulesetName()=="5E" then
		rRoll = ActionCheck.getRoll(rActor, sCheck);
	else
		rRoll = ActionAbility.getRoll(rActor, sCheck);
	end
	rRoll.RR = true;
	local nTargetDC = DB.getValue("requestsheet.checkdc", 0);
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