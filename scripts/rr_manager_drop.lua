RRPROCESSROLL = "RRProcessRoll";
RRTOWERDROP = "RRTowerDrop";
RRSTAGEDREASON = "RRStagedReason";
local fDiceTowerOnDrop;

function onInit()
	CombatDropManager.setDragTypeDropCallback("RR", RRDropManager.onRRDragTypeDrop);
	ChatManager.registerDropCallback(RRPROCESSROLL, onChatDrop);
	ChatManager.registerDropCallback(RRSTAGEDREASON, onChatDropStagedReason)
	fDiceTowerOnDrop = DiceTowerManager.onDrop;
	DiceTowerManager.onDrop = onDiceTowerDrop;
end

---This allows RR roll triggers to be dragged onto the actual combat tracker as valid drag and drops
---@param tCustom any
---@return boolean
function onRRDragTypeDrop(tCustom)
	local rTarget = ActorManager.resolveActor(tCustom.sTargetPath);
	if not rTarget then
		return false;
	end
	local sType = tCustom.draginfo.getDescription();
	RRRollManager.onButtonPress(sType,tCustom.sTargetPath);
	return true;
end

---Handler for when the processRoll button is dragged into the chat box
---@param draginfo any
---@return boolean true to show the drop was handled
function onChatDrop(draginfo)
	draginfo.window.processRoll();
	return true;
end

---Handler for when the reasons string from the staged roll entry is dragged into the chat box
---@param draginfo any
---@return boolean true to show the drop was handled
function onChatDropStagedReason(draginfo)
	draginfo.window.action();
	return true;
end

function onDiceTowerDrop(draginfo)
	if draginfo.getType() == RRDropManager.RRPROCESSROLL then
		draginfo.setDescription(RRTOWERDROP);
	end
	return fDiceTowerOnDrop(draginfo);
end