--Overrides the function ActionsManger.roll so that the popup roll page can be managed just like manual rolls
--TODO: Fix how the popup override is integrated. Currently, it runs in addition to passing the roll like normal.

function onInit()
    ActionsManager.roll = rollOverride;
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYROLL, handleApplyRoll);

end

OOB_MSGTYPE_APPLYROLL = "applyroll";

function rollOverride(rSource, vTargets, rRoll, bMultiTarget)
    if RFIA.bDebug then Debug.chat("rollOverride"); end
	
	--this portion is added to display the popup
    if ActionsManager.doesRollHaveDice(rRoll) then
    	--local wRequestedRoll = Interface.openWindow("RR_RollRequest", "");
    	--wRequestedRoll.addRoll(rRoll, rSource, vTargets);

		--local wManualRoll = Interface.openWindow("manualrolls", "");
		--wManualRoll.addRoll(rRoll, rSource, vTargets);
		notifyApplyRoll(rRoll, rSource, vTargets);
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

local boolNum={ [true]=1, [false]=0 }

function handleApplyRoll(msgOOB)
	Debug.chat("postMsgOOB",msgOOB);
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rRoll = {};
	rRoll.sSource = msgOOB.sSource;
	rRoll.aDice, rRoll.nMod = StringManager.convertStringToDice(msgOOB.sDice);
	rRoll.sType = msgOOB.sType;
	rRoll.sDesc = msgOOB.sDesc;
	rRoll.bSecret = msgOOB.bSecret;
	rRoll.bTower = msgOOB.bTower;
	
	--local nTotal = tonumber(msgOOB.nTotal) or 0;
	--applyAttack(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
	Debug.chat("postsendroll", rRoll);
	local wManualRoll = Interface.openWindow("manualrolls", "");
	wManualRoll.addRoll(rRoll, rActor, nil);
end

function notifyApplyRoll(rRoll, rSource, vTargets)
	local msgOOB = {};
	Debug.chat("vRoll", rRoll);
	Debug.chat("vSource", rSource);
	Debug.chat("vTargets", vTargets);
	msgOOB.type = OOB_MSGTYPE_APPLYROLL;

	msgOOB.sSourceNode = ActorManager.resolveActor(rActor);
	msgOOB.sSource = rRoll.sSource;
	msgOOB.sType = rRoll.sType;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod, true);
	msgOOB.bSecret = boolNum[rRoll.bSecret];
	msgOOB.bTower = boolNum[rRoll.bTower];
	Debug.chat("preMsgOOB",msgOOB);
	Comm.deliverOOBMessage(msgOOB);
end
