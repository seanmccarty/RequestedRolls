--Overrides the function ActionsManger.roll so that the popup roll page can be managed just like manual rolls
--TODO: Fix how the popup override is integrated. Currently, it runs in addition to passing the roll like normal.
--TODO: pass back dice tower rolls

function onInit()
    ActionsManager.roll = rollOverride;
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYROLL, handleApplyRollRR);
end

function starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

OOB_MSGTYPE_APPLYROLL = "applyrollRR";

function rollOverride(rSource, vTargets, rRoll, bMultiTarget)
    if RFIA.bDebug then Debug.chat("rollOverride"); end
	
	--this portion is added to display the popup
    --if ActionsManager.doesRollHaveDice(rRoll) then
    	--local wRequestedRoll = Interface.openWindow("RR_RollRequest", "");
    	--wRequestedRoll.addRoll(rRoll, rSource, vTargets);

		--local wManualRoll = Interface.openWindow("manualrolls", "");
		--wManualRoll.addRoll(rRoll, rSource, vTargets);
		
	--end

    if ActionsManager.doesRollHaveDice(rRoll) then
		if (RFIAOptionsManager.isManualSaveRollPcOn() and ActorManager.isPC(rSource)) or (RFIAOptionsManager.isManualSaveRollNpcOn() and not ActorManager.isPC(rSource)) then
			if rRoll.sSaveDesc and starts(rRoll.sSaveDesc, "[SAVE VS") then
				local wManualRoll = Interface.openWindow("manualrolls", "");
				wManualRoll.addRoll(rRoll, rSource, vTargets);
				return;
			end
		end
		if rRoll.RR then
			notifyApplyRoll(rRoll, rSource, vTargets);
			return;
		end

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

function handleApplyRollRR(msgOOB)
	if RFIA.bDebug then Debug.chat("postMsgOOB",msgOOB); end
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rRoll = {};
	rRoll.sSource = msgOOB.sSource;
	rRoll.aDice, rRoll.nMod = StringManager.convertStringToDice(msgOOB.sDice);
	rRoll.sType = msgOOB.sType;
	rRoll.sDesc = msgOOB.sDesc;
	rRoll.bSecret = msgOOB.bSecret;
	rRoll.bTower = msgOOB.bTower;
	rRoll.nTarget = tonumber(msgOOB.nTarget) or nil;
	--rRoll.RR = msgOOB.RR;
	
	--local nTotal = tonumber(msgOOB.nTotal) or 0;
	--applyAttack(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
	if RFIA.bDebug then Debug.chat("postsendroll", rRoll); end
	local wManualRoll = Interface.openWindow("manualrolls", "");
	wManualRoll.addRoll(rRoll, rActor, nil);
end

function notifyApplyRoll(rRoll, rSource, vTargets)
	local msgOOB = {};
	if RFIA.bDebug then Debug.chat("vRoll", rRoll); end
	if RFIA.bDebug then Debug.chat("vSource", rSource); end
	if RFIA.bDebug then Debug.chat("vTargets", vTargets); end
	msgOOB.type = OOB_MSGTYPE_APPLYROLL;

	msgOOB.sSourceNode = rSource.sCTNode;
	msgOOB.sSource = rRoll.sSource;
	msgOOB.sType = rRoll.sType;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod, true);
	msgOOB.bSecret = boolNum[rRoll.bSecret];
	msgOOB.bTower = boolNum[rRoll.bTower];
	msgOOB.RR = boolNum[rRoll.RR];
	msgOOB.nTarget = rRoll.nTarget;
	if RFIA.bDebug then Debug.chat("preMsgOOB",msgOOB);end

	needsBroadcast(rSource, msgOOB);
--maybe make a loop through the roll object with object constructors and then lopp throuhg on the other end?

	
	--Comm.deliverOOBMessage(msgOOB);
end

function needsBroadcast(rTarget, msgOOB)
    local sTargetNodeType, nodeTarget = ActorManager.getTypeAndNode(rTarget);
	if nodeTarget and (sTargetNodeType == "pc") then
		if Session.IsHost then
			local sOwner = DB.getOwner(nodeTarget);
			if sOwner ~= "" then
				for _,vUser in ipairs(User.getActiveUsers()) do
					if vUser == sOwner then
						for _,vIdentity in ipairs(User.getActiveIdentities(vUser)) do
							if nodeTarget.getName() == vIdentity then
								Comm.deliverOOBMessage(msgOOB, sOwner);
								return;
							end
						end
					end
				end
			end
		else
			if DB.isOwner(nodeTarget) then
				handleApplyRollRR(msgOOB);
				Debug.chat("uh oh this should have been unreachable in needsBroadcast")
				return;
			end
		end
	end
    handleApplyRollRR(msgOOB);
end