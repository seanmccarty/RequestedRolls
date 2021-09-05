---
--- 
---

function onInit()
	registerHandlers();
	updateName();
	updateSelected();
end

function registerHandlers()
	local roll = getRoll();
	roll:register(self);
end

function onClose()
	local roll = getRoll();
	roll:unregister(self);
end

function updateName()
	local roll = getRoll();
	setButtonText(roll:getName());
end

function updateSelected()
	local roll = getRoll();
	local isSelected = roll:isSelected();
	if isSelected == 1 then
		select_button.setValue(1);
	else
		select_button.setValue(0);
	end
end

function setButtonText(text)
	select_button.setStateText(0, text);
	select_button.setStateText(1, text);
end

function getRoll()
	return RFIWrapper.wrapRoll(getDatabaseNode())
end