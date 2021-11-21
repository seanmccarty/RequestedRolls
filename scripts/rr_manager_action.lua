--Overrides the function ActionsManger.roll so that the popup roll page can be managed just like manual rolls
--TODO: Fix how the popup override is integrated. Currently, it runs in addition to passing the roll like normal.

function onInit()
    ActionsManager.roll = rollOverride;
end

function rollOverride(rSource, vTargets, rRoll, bMultiTarget)
    if RFIA.bDebug then Debug.chat("rollOverride"); end
	
	--this portion is added to display the popup
    if ActionsManager.doesRollHaveDice(rRoll) then
    	--local wRequestedRoll = Interface.openWindow("RR_RollRequest", "");
    	--wRequestedRoll.addRoll(rRoll, rSource, vTargets);

		local wManualRoll = Interface.openWindow("manualrolls", "");
		wManualRoll.addRoll(rRoll, rSource, vTargets);
	end

    if ActionsManager.doesRollHaveDice(rRoll) then
		if not rRoll.bTower and OptionsManager.isOption("MANUALROLL", "on") then
			local wManualRoll = Interface.openWindow("manualrolls", "");
			wManualRoll.addRoll(rRoll, rSource, vTargets);
		else
			local rThrow = ActionsManager.buildThrow(rSource, vTargets, rRoll, bMultiTarget);
			Comm.throwDice(rThrow);
		end
	else
		if bMultiTarget then
			ActionsManager.handleResolution(rRoll, rSource, vTargets);
		else
			ActionsManager.handleResolution(rRoll, rSource, { vTargets });
		end
	end
end
