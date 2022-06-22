function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DICETOWER, handleRRDiceTower);
    OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_CANCEL, handleRRCancel);
end

OOB_MSGTYPE_CANCEL = "RRcancel";
OOB_MSGTYPE_DICETOWER = "RRdicetower";


---Receive the roll from the client and output the details for the GM to see
---@param msgOOB table the data from notifyApplyCancel
function handleRRCancel(msgOOB)
	local rRoll = Utility.decodeJSON(msgOOB.rRoll);
	local rSource;
	if msgOOB.rSource then rSource = Utility.decodeJSON(msgOOB.rSource); end
	local msg = {font = "chatfont", icon = "dicetower_icon", text = "Cancelled a roll."};
	if rSource then
		msg.sender = ActorManager.getDisplayName(rSource);
	end
	if rRoll.sSaveDesc then
		msg.text = msg.text .. " " .. rRoll.sSaveDesc;
	else
		if rRoll.sDesc ~= "" then
			msg.text = msg.text .. " " .. rRoll.sDesc;
		end
	end
	if rRoll.sSource then
		msg.text = msg.text .. " [VS " .. ActorManager.getDisplayName(rRoll.sSource) .. "]";
	end
	local sDice = DiceManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	msg.text = msg.text .. " [" .. sDice .. "]";

	Comm.addChatMessage(msg);
end

---Send the cancelled roll back to host and output a simple message as a tower entry on the client
---@param rRoll table parameter from the manual roll entry
---@param rSource table parameter from the manual roll entry
function notifyApplyCancel(rRoll, rSource)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_CANCEL;
	msgOOB.rRoll = Utility.encodeJSON(rRoll);
	if rSource then msgOOB.rSource = Utility.encodeJSON(rSource); end
	Comm.deliverOOBMessage(msgOOB, "");

	local msg = {font = "chatfont", icon = "dicetower_icon", text = "Cancelled a roll."};
	if rSource then
		msg.sender = ActorManager.getDisplayName(rSource);
	end
	if rRoll.sDesc ~= "" then
		msg.text = msg.text .. " " .. rRoll.sDesc;
	end
	local sDice = DiceManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	msg.text = msg.text .. " [" .. sDice .. "]";

	Comm.addChatMessage(msg);
end

---Processes the hidden rolls that were sent from the console to the player.
---It needs to come back becuase only the host can make the hidden rolls.
---@param msgOOB table the OOB msg from sendTower
function handleRRDiceTower(msgOOB)
	local rRoll, rActor, vTargets = RRActionManager.deOOBifyAction(msgOOB);
	rRoll.sDesc = "[" .. Interface.getString("dicetower_tag") .. "] " .. (rRoll.sDesc or "");
	--remove the RR parameter so it does not popup again
	rRoll.RR = nil;
    if rRoll.aDice[1] and rRoll.aDice[1].result then
		DiceManager.handleManualRoll(rRoll.aDice);
        ActionsManager.handleResolution(rRoll, rActor, vTargets);
    else
        ActionsManager.roll(rActor, vTargets, rRoll);
    end
end

---Creates the outgoing roll and sends it to the hsot for execution
---@param rRoll table the same info to be passed to the manualRolls
---@param rSource table the same info to be passed to the manualRolls
---@param aTargets table the same info to be passed to the manualRolls
function sendTower(rRoll, rSource, aTargets)
    local msgOOB = RRActionManager.OOBifyAction(rRoll, rSource, aTargets, OOB_MSGTYPE_DICETOWER);

    Comm.deliverOOBMessage(msgOOB, "");
    if not Session.IsHost then
        local msg = {font = "chatfont", icon = "dicetower_icon", text = ""};
        if rSource then
            msg.sender = ActorManager.getDisplayName(rSource);
        end
        if rRoll.sDesc ~= "" then
            msg.text = rRoll.sDesc .. " ";
        end
        msg.text = msg.text .. "[" .. DiceManager.convertDiceToString(rRoll.aDice, rRoll.nMod) .. "]";
        
        Comm.addChatMessage(msg);
    end
end