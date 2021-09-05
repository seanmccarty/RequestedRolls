function onInit()
	DB.addHandler(getDatabaseNode().getPath(), "onChildDeleted", onRequestDeleted);
	updateDisplay();
end


function filter(bOverrideSave, rollRequest)
	-- Debug.console("rfia_roll_request filter");
	rollOverrideData =rollRequest.getChild("rollOverrideData");
	if rollOverrideData == nil then
		return bOverrideSave == false;
	else 
		return bOverrideSave == true;
	end
end


function onRequestDeleted()
	numberOfRequest = getDatabaseNode().getChildCount();
	if numberOfRequest == 0 then
		parentcontrol.window.close();
	end
end


function updateDisplay()

	if dm_request_list.getWindowCount(true) == 0 then
		dm_request_title.setVisible(false);
	else
		dm_request_title.setVisible(true);
	end
	
	if override_save_request_list.getWindowCount(true) == 0 then
		override_save_request_title.setVisible(false);
	else
		override_save_request_title.setVisible(true);
	end
	
end