local RFIA_REQUESTS = "RFIA_Root.requestGroups";
local OOB_MSGTYPE_RFIA_ROLL_REQUEST = "rfia_rollrequest";

function onInit()
	createNodes();
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RFIA_ROLL_REQUEST, onRollRequest);
end

function createNodes()
	if User.isHost() then 
		deleteAndCreateRequestsNode();
		updateCanRequestRoll();
		createOrGetRequestGroupForPlayer(RFIAOwnershipManager.getDMUsername());
	end
end

function deleteAndCreateRequestsNode()
	rootNode = DB.createNode(RFIA_REQUESTS);
	rootNode.delete();
	rootNode = DB.createNode(RFIA_REQUESTS)
end



function updateCanRequestRoll()	
	if RFIARollManager.getSelectedRoll():isValid() and RFIAEntriesManager.isAnyoneSelected() then
		DB.setValue("RFIA_Root.canRequestRoll", "number", 1);
	else
		DB.setValue("RFIA_Root.canRequestRoll", "number", 0);
	end
end

function notifyRollRequestTo(roll, selectedEntryList)
	if not roll:isValid() then
		return;
	end
	
	for i=1, table.getn(selectedEntryList) do
		-- Debug.console("selectedEntryList[i]", selectedEntryList[i]);
		notifyRollRequest(selectedEntryList[i], roll);
	end
end

function requestRoll()
	if User.isHost() then
		roll = RFIARollManager.getSelectedRoll();
		selectedEntryList = RFIAEntriesManager.getSelectedEntries();
		notifyRollRequestTo(roll, selectedEntryList);
		RFIAModifierManager.clearAllModifierButtons();
	end
end


function notifyRollRequest(entry, roll)
	
	RFIAEntriesManager.setRollStateRequested(entry);
	owner = RFIAEntriesManager.getOwner(entry);
	-- Debug.console("notifyRollRequest entry", entry);
	-- Debug.console("notifyRollRequest owner", owner);
	requestList = createOrGetRequestGroupForPlayer(owner);
	token =  RFIAEntriesManager.getToken(entry);
	isPc = RFIAEntriesManager.isPcFromNode(entry);
	request = addRequest(requestList, RFIAEntriesManager.getCTEntryId(entry), RFIAEntriesManager.getEntryId(entry), RFIARollManager.getRollInfoById(roll:getId()), token, isPc);
	message = createRequestMessage(owner);
	-- Debug.console("notifyRollRequest owner", owner);
	-- Debug.console("notifyRollRequest message", message);
	-- Debug.console("notifyRollRequest isOwnerDm", RFIAOwnershipManager.isOwnerDm(owner));
	
	if RFIAOwnershipManager.isOwnerDm(owner) then
		onRollRequest(message);
	else
		Comm.deliverOOBMessage(message, owner);
	end
end


function createOrGetRequestGroupForPlayer(username)

	local requestGroupNode = getRequestGroup(username);	
	if requestGroupNode == nil then
		requestGroupNode = DB.createChild(RFIA_REQUESTS);
		requestsNode = requestGroupNode.createChild("requests");
		DB.setValue(requestGroupNode, "owner", "string", username);
		DB.addHolder(requestGroupNode, username, true);
		DB.addHandler(requestsNode.getPath(),"onChildAdded", handleNewRequest);
		return requestsNode;
	else
		return getRequestList(username);
	end
	
	return nil;
end

function handleNewRequest(nodeParent, nodeChild)
	DB.addHandler(nodeChild.getPath(),"onDelete", handleDeletedRequest);
end

--Checks to see if the ct entry has any more rolls and updates the image as necessary. 
-- Also removes handlers 
function handleDeletedRequest(request)

	requestList = request.getParent().getChildren();
	ctIdentity = DB.getValue(request,"ctIdentity");
	
	requestListCount = -1;
	
	for _,request in pairs(requestList) do
		if DB.getValue(request,"ctIdentity") == ctIdentity then
			requestListCount = requestListCount + 1;
		end
	end
	
	RFIAEntriesManager.updateRollState(requestListCount, ctIdentity);
	DB.removeHandler(request.getPath(),"onDelete", handleDeletedRequest);	
end


function createRequestMessage(username)
	local message = {};
	message.type = OOB_MSGTYPE_RFIA_ROLL_REQUEST;
	message.username = username;
	return message;
end

function onRollRequest(message)
	-- Debug.console("onRollRequest message", message);
	--NOTE comment out
	--RFIA.updateSidebarShortcut();
	requestList = createOrGetRequestGroupForPlayer(message.username);
	Interface.openWindow("RFIA_RollRequest", requestList);
end

function openRollRequestListForDm()
	if User.isHost() then
		requestList = createOrGetRequestGroupForPlayer(RFIAOwnershipManager.getDMUsername());
		Interface.openWindow("RFIA_RollRequest", requestList);
	end
end

function openRollRequestListForUser(username)
	requestList = createOrGetRequestGroupForPlayer(username);
	Interface.openWindow("RFIA_RollRequest", requestList);
end

function getRequestList(username)
	for _,requestGroup in pairs(DB.getChildren(RFIA_REQUESTS)) do
		owner = DB.getValue(requestGroup, "owner", "");
		if owner == username then
			return DB.getChild(requestGroup, "requests");
		end
	end
end

function getRequestListForEntry(entry)

		local requestList = {};
		entryId = entry.getName();		
		for _,requestGroup in pairs(DB.getChildren(RFIA_REQUESTS)) do
			list = DB.getChild(requestGroup, "requests");
			if list ~= nil then
				for _,request in pairs(list.getChildren()) do
					entryId = DB.getValue(request, "ctIdentity");
					if entryId == entryId then
						table.insert(requestList,request);
					end
				end
			end
		end
end

function addRequest(requestList, ctIdentity, identity, roll, token, isPc)
	
	requestNode = requestList.createChild();
	request = RFIWrapper.wrapRequest(requestNode);
	request:setToken(token);
	request:setCtIdentity(ctIdentity);
	request:setIdentity(identity);
	request:setIsPc(isPc);
	request:setRollName(roll.realname);
	request:setRollType(roll.type);
	request:setDescription(roll.description);
	request:setRollId(roll.id);
	
	for _,modifier in pairs(RFIAModifierManager.getModifiers()) do
		if modifier.getValue() ~= 0 and modifier.getValue() ~= nil then
			request:setModifier(modifier.getName(), modifier.getValue());
		end
	end
		
	local modDescription, modValue = RFIAModifierStack.getStack(false);
	request:setModifier("ModDescription", modDescription);
	request:setModifier("ModValue", modValue);
end

function getRequestById(requestId, username)
	requestGroup = getRequestGroup(username);
	path = requestGroup.getPath();
	path = path .. ".requests." .. requestId;
	return DB.findNode(path);
end

function getRequestGroup(username)
	for _,requestGroup in pairs(DB.getChildren(RFIA_REQUESTS)) do
		owner = DB.getValue(requestGroup, "owner", "");
		if owner == username then
			return requestGroup;
		end
	end
end