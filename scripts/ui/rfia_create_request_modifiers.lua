if User.getRulesetName()=="5E" then
	local ADV_MODIFIER = "RFIA_Root.modifiers.ADV";
	local DIS_MODIFIER = "RFIA_Root.modifiers.DIS";
end
local HIDDEN_MODIFIER = "RFIA_Root.modifiers.HIDDEN";
local DC_MODIFIER = "RFIA_Root.modifiers.DC";

function onInit()
	-- Debug.console("rfia_create_request_modifiers.lua onInit");
	RFIAModifierStack.registerControl(self);
	updateModifierButtons();
	updateDCModifier();
	DB.addHandler(DC_MODIFIER, "onUpdate", updateDCModifier);
end

function onClose()
	RFIAModifierStack.registerControl(nil);
	DB.removeHandler(DC_MODIFIER, "onUpdate", updateDCModifier);
end

function updateModifierButtons()
	-- Debug.console("rfia_create_request_modifiers.lua updateModifierButtons");
	if User.getRulesetName()=="5E" then
		updateButton(ADV, ADV_MODIFIER);
		updateButton(DIS, DIS_MODIFIER);
	end
	updateButton(HIDDEN, HIDDEN_MODIFIER);
end

function updateDCModifier()
	-- Debug.console("rfia_create_request_modifiers.lua updateDCModifier");
	value = DB.getValue(DC_MODIFIER, 0);
	DC.setValue(value);
end

function clearButtons()
	-- Debug.console("rfia_create_request_modifiers.lua clearButtons");
	if User.getRulesetName()=="5E" then
		clearButton(ADV);
		clearButton(DIS);
	end
	clearButton(HIDDEN);
end

function clearButton(button)
	-- Debug.console("rfia_create_request_modifiers.lua clearButton");
	button.setValue(0);
end

function updateButton(button, dbName)
	-- Debug.console("rfia_create_request_modifiers.lua updateButton");
	value = DB.getValue(dbName, 0);
	if value ~= 0 then
		button.setValue(value);
	else
		button.setValue(0);
	end
	
end