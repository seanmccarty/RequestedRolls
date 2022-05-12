--Overrides the function ActionsManger.roll so that the popup roll page can be managed just like manual rolls
--Added original function to fall through if not overridden
local fRollOriginal = nil;

function onInit()
	fRollOriginal = ActionsManager.roll;
    ActionsManager.roll = rollOverride;
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYROLL, handleApplyRollRR);
end

---Helper function for if strings start with a certain sequence
---@param String string the string to search
---@param Start string the string it should start with
---@return boolean boolean if string starts with the given sequence
function starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

OOB_MSGTYPE_APPLYROLL = "applyrollRR";

---Overrides the roll function in ActionManager so that we can add RR rolls after all normal processing has happened
---@param rSource table mirrors original function
---@param vTargets table|nil mirrors original function
---@param rRoll table mirrors original function
---@param bMultiTarget boolean mirrors original function
function rollOverride(rSource, vTargets, rRoll, bMultiTarget)
	--check to see if there is a player connected this should roll to if the host is set to auto-roll
	local sOwner = getControllingClient(rSource);
	local bBypass = false;
	if Session.IsHost == true and DB.getValue("requestsheet.autoroll", 0) == 1 then
		if sOwner then
			bBypass = false;
		else
			bBypass = true;
		end
	end

	if ActionsManager.doesRollHaveDice(rRoll) and not bBypass then
		DiceManager.onPreEncodeRoll(rRoll);
		--start where the new code is inserted
		--Checks if this save could be a roll that needs to be added but wasn't generated from console
		--For VS rolls, it is assumed they are already executing on the intended client for PC rolls
		--For NPC VS rolls, we have to send these as popups to the relevant client
		if rRoll.sSaveDesc and starts(rRoll.sSaveDesc, "[SAVE VS") then
			if Session.IsHost == true and sOwner then
				rRoll.RR = true;
				rRoll.bPopup = true;
			else
				if Session.IsHost == true then
					if (RR.isManualSaveRollPcOn() and ActorManager.isPC(rSource)) or (RR.isManualSaveRollNpcOn() and not ActorManager.isPC(rSource)) then
						ManualRollManager.addRoll(rRoll, rSource, vTargets);
						return;
					end
				else
					if RR.isManualSaveRollPcOn() then
						ManualRollManager.addRoll(rRoll, rSource, vTargets);
						return;
					end
				end
			end
		end

		--death auto and concentration rolls originate on host. They need to be sent to the players to check for the popup setting
		--stabilization is for 3.5E and PFRPG1 and 2
		if Session.IsHost == true then
			if rRoll.sType and (rRoll.sType == "death_auto" or rRoll.sType == "concentration" or rRoll.sType == "stabilization") then 
				rRoll.RR = true; 
				rRoll.bPopup = true;
			end
		end

		--rRoll.RR is only set when generated from the console or caught by an override so we can guarantee it needs to be displayed to user
		if rRoll.RR then
			notifyApplyRoll(rRoll, rSource, vTargets);
			return;
		end
		--end of new code insertion
	end
	--pass through if it wasn't caught to be displayed to user
	fRollOriginal(rSource, vTargets, rRoll, bMultiTarget);
end

--helper variable to make bools into numbers
--TODO: check if this is needed
local boolNum={ [true]=1, [false]=0};

---Processes console rolls received
---@param msgOOB table the OOB message for adding the roll to manualRolls
function handleApplyRollRR(msgOOB)
	if RR.bDebug then Debug.chat("postMsgOOB",msgOOB); end
	local rRoll = Utility.decodeJSON(msgOOB.rRoll);
	local rSource = Utility.decodeJSON(msgOOB.rSource);
	local vTargets = Utility.decodeJSON(msgOOB.vTargets);
	if vTargets and #vTargets==0 then
		vTargets=nil;
	end
	--If the roll is being passed because of popup status and the user is set to get the popup rolls, add it to the manual rolls.
	--On clients, NPCs and PCs share the PC setting so only one check is needed
	--Otherwise roll directly
	if Session.IsHost == true then
		if rRoll.bPopup and not ((RR.isManualSaveRollPcOn() and ActorManager.isPC(rSource)) or (RR.isManualSaveRollNpcOn() and not ActorManager.isPC(rSource))) then
			local rThrow = ActionsManager.buildThrow(rSource, vTargets, rRoll, true);
			Comm.throwDice(rThrow);
			return;
		end
	else
		if rRoll.bPopup and not RR.isManualSaveRollPcOn() then
			local rThrow = ActionsManager.buildThrow(rSource, vTargets, rRoll, true);
			Comm.throwDice(rThrow);
			return;
		end
	end
	
	ManualRollManager.addRoll(rRoll, rSource, vTargets);


end

---Creates the outgoing roll for the user, passes the completed message to needsBroadcast for distribution
---@param rRoll table the same info to be passed to the manualRolls
---@param rSource table the same info to be passed to the manualRolls
---@param vTargets table the same info to be passed to the manualRolls
function notifyApplyRoll(rRoll, rSource, vTargets)
	local msgOOB = {};
	if RR.bDebug then Debug.chat("rRoll", rRoll); end
	if RR.bDebug then Debug.chat("rSource", rSource); end
	if RR.bDebug then Debug.chat("vTargets", vTargets); end
	msgOOB.type = OOB_MSGTYPE_APPLYROLL;

	msgOOB.rRoll = Utility.encodeJSON(rRoll);
	if rSource then msgOOB.rSource = Utility.encodeJSON(rSource); end
	if vTargets then msgOOB.vTargets = Utility.encodeJSON(vTargets); end
	needsBroadcast(rSource, msgOOB);
--TODO:maybe make a loop through the roll object with object constructors and then loop through on the other end?
end

---This determines whether to broadcast or handle the oobmsg locally.
---This is a separate function from the notifyApplyRoll so that I can use the return to end execution early
---@param rSource table	passed through from notifyApplyRoll, determines who the message gets sent to
---@param msgOOB string the message from notifyApplyRoll
function needsBroadcast(rSource, msgOOB)
	
	local sOwner = getControllingClient(rSource);
	if sOwner then
		Comm.deliverOOBMessage(msgOOB, sOwner);
		return;
	end
    handleApplyRollRR(msgOOB);
end

---For a given actor, determines who the owning client is and if they are connected. Returns nil for inactive identities and those owned by the GM
---@param rActor table the actor who the owner needs to be determined for
---@return string|nil sOwner the controlling client if they are connected. otherwise returns nil
function getControllingClient(rActor)
	local isControlled = false;
	local sNode = nil;
	if ActorManager.isPC(rActor) then
		sNode = ActorManager.getCreatureNodeName(rActor);
	else
		if FriendZone and FriendZone.isCohort(rActor) then
			sNode = getRootCommander(rActor);
		end
	end

	--There will be an active identity if the client is connected. If sNode is still nil, nothing will be found
	for _, value in pairs(User.getAllActiveIdentities()) do
		if "charsheet." .. value == sNode then
			isControlled = true;
		end
	end
	
	if isControlled then
		return DB.getOwner(sNode);
	else
		return nil;
	end	
end

---For a given cohort actor, determine the root character node that owns it
---@param rActor table the actor we need the root commander for
---@return string|nil nodePath the root character node of the chain
function getRootCommander(rActor)
	local sRecord = ActorManager.getCreatureNodeName(rActor);
	local sRecordSansModule = StringManager.split(sRecord, "@")[1];
	local aRecordPathSansModule = StringManager.split(sRecordSansModule, ".");
	if aRecordPathSansModule[1] and aRecordPathSansModule[2] then
		return aRecordPathSansModule[1] .. "." .. aRecordPathSansModule[2];
	end
	return nil;
end