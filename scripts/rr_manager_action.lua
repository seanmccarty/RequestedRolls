function onInit()
    ActionsManager.roll = rollOverride;
end

function rollOverride(rSource, vTargets, rRoll, bMultiTarget)
    if RFIA.bDebug then Debug.chat("rollOverride"); end
    
    local wRequestedRoll = Interface.openWindow("RFIA_RollRequest", "");
    wRequestedRoll.addRoll(rRoll, rSource, vTargets);

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
