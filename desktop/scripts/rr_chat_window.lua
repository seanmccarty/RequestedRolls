---This overrides the base panel script for the chat window to stop roll processing when dice animation suppression is on
function onDrop(x, y, draginfo)
	if ChatManager.onDrop(draginfo) then
		return true;
	end

	local bReturn = ActionsManager.actionDrop(draginfo, nil);
	if bReturn then
		local aDice = draginfo.getDiceData();
		--add supression handler to this line
		if aDice and #aDice > 0 and not (RRActionManager.shouldStopAnimationDice(aDice) or OptionsManager.isOption("MANUALROLL", "on")) then
			return;
		end
		return true;
	end
end