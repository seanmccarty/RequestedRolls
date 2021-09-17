--[[
At the moment this makes the GM roll on behalf of the player, which is boring and rubbish! 
So lets create a special rfia_request roll for the player to roll. 

Here we overtake the 5e manager_action_save handlers. We always make sure to recall these methods eventually so nothing is missed out. 

]]
local bDebug = true;
function onInit()

	ActionsManager.registerModHandler("save", modSave);	
	ActionsManager.registerResultHandler("save", onSave);	
	
	ActionsManager.registerModHandler("death", modSave);
	ActionsManager.registerResultHandler("death", onDeathRoll);

	ActionsManager.registerModHandler("concentration", modSave);
	ActionsManager.registerResultHandler("concentration", onConcentrationRoll);
	
end



function modSave(rSource, rTarget, rRoll)
	if bDebug then Debug.chat("rfia mod save"); end
	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bManualSaveRollForNPCOn = RFIAOptionsManager.isManualSaveRollNpcOn();

	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bIsRFIAManualRequest = rRoll.bRFIARequestRoll ~=nil;
	local bShouldOverride = false;

	if not bInitialRequestSetupOccured and  not bIsRFIAManualRequest then
		if ActorManager.isPC(sSource) then
			if bManualSaveRollForPCOn then
				bShouldOverride = true;
			end
		else
			if bManualSaveRollForNPCOn then
				bShouldOverride = true;
			end
		end
	end
	
	if bShouldOverride then
		local dice = UtilityManager.copyDeep(rRoll.aDice);
		local rollOverrideData = UtilityManager.copyDeep(rRoll);
		rollOverrideData.aDice = dice;
		--We have now stopped the dice from rolling yay!
		rRoll.aDice = {};
		if Session.IsHost then
			ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
			RFIARollOverrideManager.requestSaveOverrideModSave(ctNode, ActorManager.isPC(sSource), rollOverrideData, rRoll);
		else
			RFIARollOverrideManager.notifyDMOfOverrideSave(rSource, rTarget, rollOverrideData);
		end
	else
		ActionSave.modSave(rSource, rTarget, rRoll);
	end
end

--Unfortunately the stack mod only gets added on after the modHandler, so we have to update it in the following methods;
function onSave(rSource, rTarget, rRoll)
	if bDebug then Debug.chat("rfia on save 2"); end

	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bManualSaveRollForNPCOn = RFIAOptionsManager.isManualSaveRollNpcOn();

	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bIsRFIAManualRequest = rRoll.bRFIARequestRoll ~=nil;
	local bShouldOverride = false;

	if not bInitialRequestSetupOccured and  not bIsRFIAManualRequest then
		if ActorManager.isPC(sSource) then
			if bManualSaveRollForPCOn then
				bShouldOverride = true;
			end
		else
			if bManualSaveRollForNPCOn then
				bShouldOverride = true;
			end
		end
	end

	if bShouldOverride then
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
		ActionSave.modSave(rSource, rTarget, rRoll);
	end
end

function onDeathRoll(rSource, rTarget, rRoll)

	if User.isHost() then 
		onDeathRollForHost(rSource, rTarget, rRoll);
	else
		onDeathRollForPlayer(rSource, rTarget, rRoll);
	end	
	
end


function onDeathRollForHost(rSource, rTarget, rRoll)

	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bManualSaveRollForNPCOn = RFIAOptionsManager.isManualSaveRollNpcOn();
	local bOverrideTurnedOn = ( bManualSaveRollForPCOn or bManualSaveRollForNPCOn);
	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bIsRFIAManualRequest = rRoll.bRFIARequestRoll ~=nil;
	local bShouldOverride = false;
	local ctNode;
	
	if bOverrideTurnedOn and  not bInitialRequestSetupOccured and  not bIsRFIAManualRequest then
		ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
		isPc = RFIAEntriesManager.isPcFromNode(ctNode);	
		if isPc and bManualSaveRollForPCOn then
			bShouldOverride = true;
		end
		if not isPc and bManualSaveRollForNPCOn then
			bShouldOverride = true;
		end
	end
	
	if  bShouldOverride then
		RFIARollOverrideManager.requestSaveOverrideOnSave(ctNode, rRoll);
	else
		ActionSave.onDeathRoll(rSource, rTarget, rRoll);
	end


end

function onDeathRollForPlayer(rSource, rTarget, rRoll)

	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bIsRFIAManualRequest = rRoll.bRFIARequestRoll ~=nil;

	if bManualSaveRollForPCOn and not bInitialRequestSetupOccured and not bIsRFIAManualRequest then
		-- Debug.console("Time to let the DM know that he should update a request!");
	else
		ActionSave.onDeathRoll(rSource, rTarget, rRoll);
	end

end



function onConcentrationRoll(rSource, rTarget, rRoll)

	if User.isHost() then 
		onConcentrationRollForHost(rSource, rTarget, rRoll);
	else
		onConcentrationRollForPlayer(rSource, rTarget, rRoll);
	end	

	
end

function onConcentrationRollForHost(rSource, rTarget, rRoll)

	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bManualSaveRollForNPCOn = RFIAOptionsManager.isManualSaveRollNpcOn();
	local bOverrideTurnedOn = ( bManualSaveRollForPCOn or bManualSaveRollForNPCOn);
	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bShouldOverride = false;
	local ctNode;
	
	
	if bOverrideTurnedOn and  not bInitialRequestSetupOccured then
		ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
		bShouldOverride = true;
	end	
	if bOverrideTurnedOn and  not bInitialRequestSetupOccured  then
		ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
		isPc = RFIAEntriesManager.isPcFromNode(ctNode);	
		if isPc and bManualSaveRollForPCOn then
			bShouldOverride = true;
		end
		if not isPc and bManualSaveRollForNPCOn then
			bShouldOverride = true;
		end
	end
	
	if  bShouldOverride then
		RFIARollOverrideManager.requestSaveOverrideOnSave(ctNode, rRoll);
	else	
		ActionSave.onConcentrationRoll(rSource, rTarget, rRoll);
	end

end

function onConcentrationRollForPlayer(rSource, rTarget, rRoll)

	local bManualSaveRollForPCOn = RFIAOptionsManager.isManualSaveRollPcOn();
	local bInitialRequestSetupOccured = (rRoll.bRollOverride ~= nil);
	local bIsRFIAManualRequest = rRoll.bRFIARequestRoll ~=nil;

	if bManualSaveRollForPCOn and not bInitialRequestSetupOccured then
		-- Debug.console("Time to let the DM know that he should update a request!");
	else
		ActionSave.onConcentrationRoll(rSource, rTarget, rRoll);
	end

end

