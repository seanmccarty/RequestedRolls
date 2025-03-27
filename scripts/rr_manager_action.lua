--Overrides the function ActionsManger.roll so that the popup roll page can be managed just like manual rolls
--Added original function to fall through if not overridden
local fRollOriginal = nil;

function onInit()
	fRollOriginal = ActionsManager.roll;
    ActionsManager.roll = rollOverride;
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYROLL, handleApplyRollRR);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ALLROLLS, handleAllRollsRR);
end

---Helper function for if strings start with a certain sequence
---@param String string the string to search
---@param Start string the string it should start with
---@return boolean boolean if string starts with the given sequence
function starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

OOB_MSGTYPE_APPLYROLL = "applyrollRR";
OOB_MSGTYPE_ALLROLLS = "allrollsRR";

--the default roll types that originate on host
local sTypes = {
	["concentration"] = { },
	["death_auto"] = { },
	["stabilization"] = { }, 
	["parcelseeharvest"] = {},
	["parcelharvest"] = {}
};

--a list of the start of sSaveDesc that should trigger a popup
--[ONGOING SAVE is for Better Combat Effects
local saveDescs = {
	"[SAVE VS","[ONGOING SAVE"
};

---Registers rolls that are created on the host side that need to be sent to the client for popup
---@param newType string the new roll type to be registered
function registerRollType(newType)
	sTypes[newType] = {};
end

---Unregisters rolls added via registerRollType
---@param sType string the roll type to be unregistered
function unregisterRollType(sType)
	if sTypes then
		sTypes[sType] = nil;
	end
end

---Registers rolls that have a sSaveDesc that starts with a specific string as needing to be shown as popup. These can originate on host or client.
---@param newDesc string the new sSaveDesc to be unregistered
function registerSaveDescription(newDesc)
	table.insert(saveDescs, newDesc);
end

---Unregisters rolls added via registerRollDescription
---@param sDesc string the sSaveDesc to be unregistered
function unregisterSaveDescription(sDesc)
	for i,s in ipairs(saveDescs) do
		if s==sDesc then
			table.remove(saveDescs,i);
			return;
		end
	end
end

---Determines whether a given rolls save description is registered as a popup
---@param sDesc string the string to be checked
---@return boolean bool is this is a popup type save
function isPopupSaveDesc(sDesc)
	for i,s in ipairs(saveDescs) do
		if starts(sDesc,s) then
			return true;
		end
	end
	return false;
end

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

	--if if it starts with the dicetower_tag then it is a roll that was dropped on the tower and should be bypassed
	if rRoll.sDesc and starts(rRoll.sDesc,"[" .. Interface.getString("dicetower_tag") .. "]") then
		bBypass = true;
	end

	if ActionsManager.doesRollHaveDice(rRoll) and not bBypass then
		DiceManager.onPreEncodeRoll(rRoll);
		--start where the new code is inserted
		--Checks if this save could be a roll that needs to be added but wasn't generated from console
		--For VS rolls, it is assumed they are already executing on the intended client for PC rolls
		--For NPC VS rolls, we have to send these as popups to the relevant client
		if rRoll.sSaveDesc and isPopupSaveDesc(rRoll.sSaveDesc) then
			if Session.IsHost == true and sOwner then
				rRoll.RR = true;
				rRoll.bPopup = true;
			else
				local bShowPopup = false;
				if Session.IsHost == true then
					if (RR.isManualSaveRollPcOn() and ActorManager.isPC(rSource)) or (RR.isManualSaveRollNpcOn() and not ActorManager.isPC(rSource)) then
						bShowPopup = true;
					end
				else
					if RR.isManualSaveRollPcOn() then
						bShowPopup = true;
					end
				end
				if bShowPopup == true then
					if bMultiTarget then
						ManualRollManager.addRoll(rRoll, rSource, vTargets);
					else
						ManualRollManager.addRoll(rRoll, rSource, { vTargets });
					end
					return;
				end
			end
		end

		--death auto and concentration rolls originate on host. They need to be sent to the players to check for the popup setting
		--stabilization is for 3.5E and PFRPG1 and 2
		if Session.IsHost == true then
			if rRoll.sType and sTypes[rRoll.sType] then 
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

	--if this is a complex dice string, the aDice is blank and expr will be set, and I dont want to deal with dice expressions
	if shouldStopAnimationRoll(rRoll) then
		evalRoll(rRoll);
		ActionsManager.handleResolution(rRoll, rSource, vTargets);
	else
		--pass through if it wasn't caught to be displayed to user
		fRollOriginal(rSource, vTargets, rRoll, bMultiTarget);
	end
end

---Checks if the expression has dice before checking if it should be stopped. The onDrop function for chat does not have rRoll, so it just has the dice.
---@return boolean stopAnimation 
function shouldStopAnimationRoll(rRoll)
	if ActionsManager.doesRollHaveDice(rRoll) then
		return shouldStopAnimationDice(rRoll.aDice);
	else
		return false;
	end
end

---Checks if the dice qualify for being stopped because the expression isn't a dice math, that suppression is enabled, and that manual rolls are not turned on
---@param aDice table the aDice table
---@return boolean stopAnimation 
function shouldStopAnimationDice(aDice)
	if ((not aDice.expr) or DiceManager.isDiceString(aDice.expr))
	and OptionsManager.isOption("RR_option_label_suppressDiceAnimations","on")
	and OptionsManager.isOption("MANUALROLL","off") then
		return true;
	else
		return false;
	end
end

---Assigns random numerical results to each die in the roll
---@param rRoll table the rRoll that will be processed without animation
function evalRoll(rRoll)
	DiceManager.onPreEncodeRoll(rRoll);
	local nTotal = 0;

	for index,w in ipairs(rRoll.aDice) do
		if rRoll.aDice[index] then
			if type(rRoll.aDice[index]) ~= "table" then
				local rDieTable = {};
				rDieTable.type = rRoll.aDice[index];
				rRoll.aDice[index] = rDieTable;
			end

			local nDieSides = string.match(rRoll.aDice[index].type,"%d+");
			local nValue = math.random(nDieSides);
			nTotal = nTotal + nValue;

			if rRoll.aDice[index].type:sub(1,1) == "-" then
				rRoll.aDice[index].result = -nValue;
			else
				rRoll.aDice[index].result = nValue;
			end
			rRoll.aDice[index].value = rRoll.aDice[index].result;
		end
	end
	rRoll.aDice.total = nTotal;
	DiceManager.handleManualRoll(rRoll.aDice);
end

---Processes console rolls received
---@param msgOOB table the OOB message for adding the roll to manualRolls
function handleApplyRollRR(msgOOB)
	local rRoll, rSource, vTargets = deOOBifyAction(msgOOB);
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

---Takes an action with the three parameters and turns it into an OOB msg
---@param rRoll table the same info to be passed to the manualRolls
---@param rSource table the same info to be passed to the manualRolls
---@param vTargets table the same info to be passed to the manualRolls
---@param sType string the OOB_MSGTYPE to be assigned
---@return table msgOOB
function OOBifyAction(rRoll, rSource, vTargets, sType)
	local msgOOB = {};
	if RR.bDebug then Debug.chat("rRoll", rRoll); end
	if RR.bDebug then Debug.chat("rSource", rSource); end
	if RR.bDebug then Debug.chat("vTargets", vTargets); end
	msgOOB.type = sType;
	msgOOB.rRoll = Utility.encodeJSON(rRoll);
	if rSource then 
		--ongoing save effects codes the actor as a string, this is to catch if other people do that as wellfa
		if type(rSource) ~= "table" then rSource = ActorManager.resolveActor(rSource); end
		msgOOB.rSource = Utility.encodeJSON(rSource);
	 end
	if vTargets then msgOOB.vTargets = Utility.encodeJSON(vTargets); end
	return msgOOB;
end

---Takes an OOB msg of an action and turns it back into tables
---@param msgOOB table the received OOB msg
---@return table rRoll 
---@return table|nil rSource
---@return table|nil vTargets
function deOOBifyAction(msgOOB)
	if RR.bDebug then Debug.chat("postMsgOOB",msgOOB); end
	local rRoll = Utility.decodeJSON(msgOOB.rRoll);
	local rSource = nil;
	if msgOOB.rSource then rSource = Utility.decodeJSON(msgOOB.rSource); end
	local vTargets = nil;
	if msgOOB.vTargets then vTargets = Utility.decodeJSON(msgOOB.vTargets); end;
	if vTargets and #vTargets==0 then
		vTargets=nil;
	end
	return rRoll, rSource, vTargets;
end


---Creates the outgoing roll for the user, passes the completed message to needsBroadcast for distribution
---@param rRoll table the same info to be passed to the manualRolls
---@param rSource table the same info to be passed to the manualRolls
---@param vTargets table the same info to be passed to the manualRolls
function notifyApplyRoll(rRoll, rSource, vTargets)
	local msgOOB = OOBifyAction(rRoll, rSource, vTargets, OOB_MSGTYPE_APPLYROLL);

	needsBroadcast(rSource, msgOOB);
end

---Checks if the rSource is connected. If so they player is sent an OOBmsg that processes all the rolls. 
---@param rSource table the database node for the CTNODE
---@param bMakeRoll boolean true to make rolls, false to delete
function notifyAllRolls(rSource, bMakeRoll)
	local sOwner = getControllingClient(rSource);
	if sOwner then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_ALLROLLS;
		msgOOB.sCTNodeID = ActorManager.getCTNodeName(rSource);
		if bMakeRoll then
			msgOOB.bMakeRoll = "true";
		else
			msgOOB.bMakeRoll = "false";
		end
		Comm.deliverOOBMessage(msgOOB, sOwner);

		local msg = {icon = "portrait_gm_token"};
		if bMakeRoll then
			msg.text = Interface.getString("RR_msg_rollAll_GM")..ActorManager.getDisplayName(rSource);
		else
			msg.text = Interface.getString("RR_msg_rollCancel_GM")..ActorManager.getDisplayName(rSource);
		end
		Comm.addChatMessage(msg);
	else
		ChatManager.SystemMessage(Interface.getString("RR_msg_rollNotConnected"));
	end
end

---Opens the manual roll window and makes all the rolls for the given CTNode using the custom control I added
---Also, posts a message so the player knows what happened
---@param msgOOB table the message from notifyMakeAllRolls
function handleAllRollsRR(msgOOB)
	local sCTNodeID = msgOOB.sCTNodeID;
	local bMakeRoll = msgOOB.bMakeRoll == "true";
	local wMain = Interface.openWindow("manualrolls", "");
	local bActioned = false;
	for _,vEntry in pairs(wMain.list.getWindows()) do
		if vEntry.CTNodeID.getValue() == sCTNodeID then
			bActioned = true;
			if bMakeRoll then
				vEntry.processRoll();
			else
				vEntry.processCancel();
			end
		end
	end
	if bActioned then
		local msg = {icon = "portrait_gm_token", secret=true};
		if bMakeRoll then
			msg.text = Interface.getString("RR_msg_rollAll_player")
		else
			msg.text = Interface.getString("RR_msg_rollCancel_player")
		end
		Comm.addChatMessage(msg);
	end
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

---For a given actor, determines who the owning client is and if they are connected. Returns nil for those owned by the GM or if the owner is not connected
---Prefers DB node owners, otherwise it checks for NPCowner from the extension Assistant GM
---This does not check if the identity is active before establishing ownership
---@param rActor table the actor who the owner needs to be determined for
---@return string|nil sOwner the controlling client if they are connected. otherwise returns nil
function getControllingClient(rActor)
	local sNode = ActorManager.getCreatureNodeName(rActor);
	local sOwner = DB.getOwner(sNode);
	local userList = User.getActiveUsers();
	if sOwner == nil then
		sOwner = DB.getValue(sNode..".NPCowner",nil);
	end
	for _, value in pairs(userList) do
		if value == sOwner then
			return sOwner;
		end
	end

	return nil;
end

---DEPRECATE as unused
---For a given cohort actor, determine the root character node that owns it
---@param rActor table the actor we need the root commander for
---@return string|nil nodePath the root character node of the chain
function getRootCommander(rActor)
	local sRecord = ActorManager.getCreatureNodeName(rActor);
	local aRecordPathSansModule, _ = UtilityManager.parsePath(sRecord);
	if aRecordPathSansModule[1] and aRecordPathSansModule[2] then
		return aRecordPathSansModule[1] .. "." .. aRecordPathSansModule[2];
	end
	return nil;
end