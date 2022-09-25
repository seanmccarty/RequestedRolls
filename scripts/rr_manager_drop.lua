RRPROCESSROLL = "RRProcessRoll";

function onInit()
	CombatDropManager.setDragTypeDropCallback("RR", RRDropManager.onRRDragTypeDrop);
	ChatManager.registerDropCallback(RRPROCESSROLL,onChatDrop);
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