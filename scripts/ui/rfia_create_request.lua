
local CAN_REQUEST_ROLL = "RFIA_Root.canRequestRoll";


function onInit()
	-- Debug.console("rfia_create_request.lua onInit");
	updateRequestRollButtonVisibility();	
	DB.addHandler(CAN_REQUEST_ROLL, "onUpdate", updateRequestRollButtonVisibility); 
end

function onClose()
	DB.removeHandler(CAN_REQUEST_ROLL, "onUpdate", updateRequestRollButtonVisibility);
end

function updateRequestRollButtonVisibility()
	-- Debug.console("rfia_create_request.lua updateRequestRollButtonVisibility");
	canRequestRoll = DB.getValue(CAN_REQUEST_ROLL, 0);
	if canRequestRoll == 1 then
		request_roll_button.setVisible(true);
	else
		request_roll_button.setVisible(false);
	end
end

function filter(filter, roll, entryType)
	-- Debug.console("rfia_create_request.lua filter roll entryType", filter, roll, entryType);
	if entryType == "rfia_entry" then
		local class, recordname = DB.getValue(roll, "link","string","");
		return filter == class;
	else
		roll = RFIWrapper.wrapRoll(roll);
		
		index = filter:find("|");
		if index ~= nil then
			secondFilter = filter:sub(index+1);
			firstFilter = filter:sub(1, index-1);
			
			return firstFilter == roll:getCategory() or secondFilter == roll:getCategory();
		end
		return filter == roll:getCategory();
	end
end