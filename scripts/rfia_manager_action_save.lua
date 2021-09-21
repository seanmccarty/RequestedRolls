--[[
At the moment this makes the GM roll on behalf of the player, which is boring and rubbish! 
So lets create a special rfia_request roll for the player to roll. 

Here we overtake the 5e manager_action_save handlers. We always make sure to recall these methods eventually so nothing is missed out. 

]]
function onInit()

	ActionsManager.registerModHandler("save", modSave);	
	ActionsManager.registerResultHandler("save", onSave);	
	
	ActionsManager.registerModHandler("death", modSave);
	ActionsManager.registerResultHandler("death", onDeathRoll);

	ActionsManager.registerModHandler("concentration", modSave);
	ActionsManager.registerResultHandler("concentration", onConcentrationRoll);
	
end

function shouldOverride(rRoll, rSource)
	if RFIA.bDebug then Debug.chat("shouldOverride"); end
	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bManualSaveRollForNPCOn = RFIAOptionsManager.isManualSaveRollNpcOn();

	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bIsRFIAManualRequest = rRoll.bRFIARequestRoll ~=nil;

	if not bInitialRequestSetupOccured and  not bIsRFIAManualRequest then
		if ActorManager.isPC(rSource) then
			if bManualSaveRollForPCOn then
				return true;
			end
		else
			if bManualSaveRollForNPCOn then
				return true;
			end
		end
	end
	return false;
end


function modSave(rSource, rTarget, rRoll)
	if RFIA.bDebug then Debug.chat("rfia mod save"); end
	
	if shouldOverride(rRoll, rSource) then
		local dice = UtilityManager.copyDeep(rRoll.aDice);
		local rollOverrideData = UtilityManager.copyDeep(rRoll);
		rollOverrideData.aDice = dice;
		--We have now stopped the dice from rolling yay!
		rRoll.aDice = {};
		if Session.IsHost then
			ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
			RFIARollOverrideManager.requestSaveOverrideModSave(ctNode, ActorManager.isPC(rSource), rollOverrideData, rRoll);
		else
			RFIARollOverrideManager.notifyDMOfOverrideSave(rSource, rTarget, rollOverrideData);
		end
	else
		ActionSave.modSave(rSource, rTarget, rRoll);
	end
end

--Unfortunately the stack mod only gets added on after the modHandler, so we have to update it in the following methods;
function onSave(rSource, rTarget, rRoll)
	if RFIA.bDebug then Debug.chat("rfia on save 2"); end

	if shouldOverride(rRoll, rSource) then
		local dice = UtilityManager.copyDeep(rRoll.aDice);
		local rollOverrideData = UtilityManager.copyDeep(rRoll);
		rollOverrideData.aDice = dice;
		--We have now stopped the dice from rolling yay!
		rRoll.aDice = {};
		if Session.IsHost then
			ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
			RFIARollOverrideManager.requestSaveOverrideOnSave(ctNode, rRoll);
		else
			-- do nothing?
		end
	else
		ActionSave.onSave(rSource, rTarget, rRoll);
	end
end

function onDeathRoll(rSource, rTarget, rRoll)
	if RFIA.bDebug then Debug.chat("rfia on death"); end
	if  shouldOverride(rRoll, rSource) then
		if Session.IsHost then
			ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
			RFIARollOverrideManager.requestSaveOverrideOnSave(ctNode, rRoll);
		else
			--do nothing?
		end
	else
		ActionSave.onDeathRoll(rSource, rTarget, rRoll);
	end	
end

function onConcentrationRoll(rSource, rTarget, rRoll)
	if RFIA.bDebug then Debug.chat("rfia on concentration"); end
	if  shouldOverride(rRoll, rSource) then
		if Session.IsHost then
			ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
			RFIARollOverrideManager.requestSaveOverrideOnSave(ctNode, rRoll);
		else
			--do nothing?
		end
	else
		ActionSave.onConcentrationRoll(rSource, rTarget, rRoll);
	end		
end

