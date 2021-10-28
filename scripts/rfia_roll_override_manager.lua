--[[
Handles any saves if the roll override options are turned on.
]]


local OOB_MSGTYPE_RFIA_ROLL_REQUEST = "rfia_rolloverride";
local RFIA_OVERRIDE_TEMP = "RFIA_OVERRIDE_TEMP";
function onInit()
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RFIA_ROLL_REQUEST, onRollOverrideRequest);
		ActionsManager.initAction(RFIA_OVERRIDE_TEMP);
	end
end

--Unfortunately the stack mod is added after onMod is called, so we have to partially setup the request, then wait for onSave.
function requestSaveOverrideModSave(ctNode, isPc, rollOverrideData, rRoll)
	--Save the rRoll into the database. 
	createRequestSaveOverrideModSave(ctNode, isPc, rollOverrideData, rRoll);
end


function createRequestSaveOverrideModSave(ctNode, isPc, rollOverrideData, rRoll)

	owner = RFIAEntriesManager.getOwner(ctNode);
	requestList = RFIARequestManager.createOrGetRequestGroupForPlayer(owner);
	token =  RFIAEntriesManager.getToken(ctNode);
	rfiaRoll = RFIARollManager.getSaveOverrideRoll();
	request = addRequestSaveOverrideModSave(requestList, ctNode, RFIAEntriesManager.getEntryId(ctNode),rfiaRoll , token, isPc,rollOverrideData,  rRoll);
	
end
function addRequestSaveOverrideModSave(requestList, ctNode, identity, rfiaRoll, token, isPc, rollOverrideData, rRoll)
	--Debug.chat("addRequestSaveOverrideModSave");
	ctIdentity = RFIAEntriesManager.getCTEntryId(ctNode);
	requestNode = requestList.createChild();
	RFIAEntriesManager.setRollStateRequested(ctNode);
	--Add the requestId to the roll 
	rRoll["rollOverrideRequestId"] = requestNode.getName();
	request = RFIWrapper.wrapRequest(requestNode);
	request:setToken(token);
	request:setCtIdentity(ctIdentity);
	request:setIdentity(identity);
	request:setIsPc(isPc);
	request:setRollName(rfiaRoll.realname);
	request:setRollType(rfiaRoll.type);
	request:setRollId(rfiaRoll.id);
	request:setRollOverrideData(rollOverrideData);
	
	local sType = rRoll.sType;

	if sType ==  "death" then
		addDescriptionForDeathSave(request);
	elseif sType == "concentration" then
		addDescriptionForConcentrationSave(request);
	elseif sType == "save" then
		addDescriptionForSave(rRoll, request);
	else
		ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] ( sType not found)");
	end	
	--Debug.chat("addRequestSaveOverrideModSave",2);
end

function addDescriptionForSave(rRoll, request)
	
	local description = rRoll.sDesc
	local fromTargetCtId = rRoll.sSource;
	if fromTargetCtId ~= nil then
		local targetCTNode = RFIAEntriesManager.getEntryByPath(fromTargetCtId);
		local isIdentified =  DB.getValue(targetCTNode, "isidentified");
		
		targetName = "Error";

		if RFIAEntriesManager.isPcFromNode(targetCTNode) then
			targetName = DB.getValue(targetCTNode, "name");
		elseif isIdentified == 0 then
			targetName = DB.getValue(targetCTNode, "nonid_name");
		else
			targetName = DB.getValue(targetCTNode, "name");
		end
		
		description = description .. " VS " .. targetName;
	end
	request:setDescription(description);
end

function addDescriptionForConcentrationSave(request)
	request:setDescription("Concentration (Constitution) Save");
end


function addDescriptionForDeathSave(request)
	request:setDescription("Death Save");
end



function requestSaveOverrideOnSave(ctNode, rRoll)	
	updateRequestSaveOverrideOnSave(ctNode, rRoll);
end

--We now need to update the modifier. 
function updateRequestSaveOverrideOnSave(ctNode, rRoll)

	rollOverrideRequestId = rRoll["rollOverrideRequestId"];
	owner = RFIAEntriesManager.getOwner(ctNode);
	if rollOverrideRequestId == nil then
		ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] ( rollOverrideRequestId not found)");
		return;
	end
	
	requestNode = RFIARequestManager.getRequestById(rollOverrideRequestId, owner);
	
	--We have the request node, now we need to update the rollOverrideData with the new mod
	local rollOverrideData = requestNode.getChild("rollOverrideData");
	local sDiceCurrent = DB.getValue(rollOverrideData, "sDice", "");
	local aDice, nMod = StringManager.convertStringToDice(sDiceCurrent);
	
	local newMod = rRoll.nMod;
	local sDiceNew = StringManager.convertDiceToString(aDice, newMod);
	DB.setValue(rollOverrideData, "sDice", "string", sDiceNew); 
	DB.setValue(rollOverrideData, "sDesc", "string", rRoll.sDesc); 
	message = RFIARequestManager.createRequestMessage(owner);
	
	request = RFIWrapper.wrapRequest(requestNode);
		--Sort out modifiers for UI
	if User.getRulesetName()=="5E" then
		updateModifierForUi(rRoll.sDesc, "ADV", "%[ADV%]", request)
		updateModifierForUi(rRoll.sDesc, "DIS", "%[DIS%]", request)
	end
	if rRoll.nTarget ~= 0 and rRoll.nTarget ~= nil then
		request:setModifier("DC", rRoll.nTarget);
	end
	
	modDescription = "";
	if newMod > 0 then
		modDescription = "+" .. tostring(newMod);
	elseif newMod < 0 then
		modDescription = "-" .. tostring(newMod);
	else 
		modDescription = tostring(newMod);
	end

	request:setModifier("ModDescription", modDescription);
	request:setModifier("ModValue", newMod);

	 
	if RFIAOwnershipManager.isOwnerDm(owner) then
		RFIARequestManager.onRollRequest(message);
	else
		Comm.deliverOOBMessage(message, owner);
	end
end

function updateModifierForUi(description, name, reg, request)
	local stringMatch = string.match(description, reg)
	if stringMatch ~= nil then
		request:setModifier(name, name);
	end
end	

function notifyDMOfOverrideSave(rSource, rTarget, rRoll)
	msg = createMessage(rSource, rTarget, rRoll);
	Comm.deliverOOBMessage(msg, "");
end

function createMessage(rSource, rTarget, rRoll)
		local message = {};
		
		message.type = OOB_MSGTYPE_RFIA_ROLL_REQUEST;
		
		--What we need for rSource
		message.sCreatureNode =  rSource.sCreatureNode;
		
		--Now add the roll details
		message.roll_sSource	=rRoll.sSource
		message.roll_nTarget	=rRoll.nTarget
		message.roll_sType	=rRoll.sType
		message.roll_sSaveDesc	=rRoll.sSaveDesc
		message.roll_sDesc	=rRoll.sDesc;
		--Convert to string using stringManager.
		local sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod );
		message.roll_sDice	=sDice;
		
	return message;
end

function onRollOverrideRequest(message)
	--Debug.chat("rolloverriderequest",message);
	
	local sSource = message.sCreatureNode;
	local rSource = ActorManager.getActor("pc", sSource);
	local rRoll = {};
	rRoll.sSource = message.roll_sSource
	rRoll.nTarget = message.roll_nTarget
	rRoll.sType = message.roll_sType
	rRoll.sSaveDesc = message.roll_sSaveDesc
	rRoll.sDesc = message.roll_sDesc
	
	local aDice, nMod = StringManager.convertStringToDice(message.roll_sDice);
	rRoll.aDice = aDice;
	rRoll.nMod = nMod;

	local ctNode = RFIAEntriesManager.getEntryByPath(rSource.sCTNode);
	requestSaveOverrideModSave(ctNode, ActorManager.isPC(sSource), rRoll, rRoll);
	ActionsManager.lockModifiers();
	--NOTE comment out the below line
	--ActionSave.modSave(rSource, nill, rRoll);
	--Temp change the type
	local originalType = UtilityManager.copyDeep(rRoll.sType);
	rRoll.sType = RFIA_OVERRIDE_TEMP;
	ActionsManager.applyModifiers(rSource, nil, rRoll, false);
	ActionsManager.unlockModifiers(true);
	--Change the type back
	rRoll.sType = originalType;
	requestSaveOverrideOnSave(ctNode, rRoll);
end
