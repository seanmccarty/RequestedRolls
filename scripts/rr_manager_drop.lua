function onInit()
	CombatDropManager.setDragTypeDropCallback("RR", RRDropManager.onRRDragTypeDrop);
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
