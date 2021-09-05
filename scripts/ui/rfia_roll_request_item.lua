function onInit()
	modifier_title.setVisible(false);
	registerHandlers();
end

function roll()	
	request = getRequest();
	RFIARollManager.performRoll(getRequest());
	request:destroy();
end

function cancel()
	request = getRequest();
	request:destroy();
end

function registerHandlers()
	request = getRequest();
	request:register(self);
end

function onClose()
	request = getRequest();
	request:unregister(self);
end

function updateDescription()
	request = getRequest();
	roll_button.setText(request:getDescription());
end

function updateIcon()
	request = getRequest();
	token = request:getToken();
end

function updateADV()

	request = getRequest();
	showAdv = request:getModifier("ADV") ~= "" and request:getModifier("ADV") ~= nil;
	adv.setVisible(showAdv);
	if showAdv then
		modifier_title.setVisible(true);
	end
	
end

function updateDIS()
	request = getRequest();
	showDis = request:getModifier("DIS") ~= "" and request:getModifier("DIS") ~= nil;
	dis.setVisible(showDis);
	
	if showDis then
		modifier_title.setVisible(true);
	end
end

function updateHIDDEN()
	request = getRequest();
	hidden.setVisible(request:isHidden());
	
	if request:isHidden() then
		modifier_title.setVisible(true);
	end
end

function updateDC()
	request = getRequest();
	showDC = request:getDC() ~= nil and request:getDC() ~= 0 and RFIAOptionsManager.isShdowDcOn();
	dc.setVisible(showDC);
	
	if showDC then
		valueString = tostring(request:getDC());
		dc.setValue("DC "..valueString);
		tooltipString = Interface.getString("RFI_dc_tooltip_modifier");
		tooltipString = tooltipString:gsub("DCVALUE", valueString);
		dc.setTooltipText(tooltipString);
		modifier_title.setVisible(true);
	end
end

function updateModValue()
	value = calculateFinalValue(request);
	showMod = value ~= 0;
	mod.setVisible(showMod);
	if showMod then
		valueString = tostring(value);
		if value > 0 then
			valueString = "+" .. value;
		end
		
		mod.setValue(valueString);
		tooltipString = Interface.getString("RFI_mod_tooltip_modifier");
		tooltipString = tooltipString:gsub("MOD", valueString);
		mod.setTooltipText(tooltipString);
		modifier_title.setVisible(true);
	end
end

function calculateFinalValue()
	request = getRequest();	
	value = getModValue(request, "ModValue");
	value = value + getModValue(request, "PLUS5", 5);
	value = value + getModValue(request, "PLUS2", 2);
	value = value + getModValue(request, "MINUS5", -5);
	value = value + getModValue(request, "MINUS2", -2);
	return value;
end

function getModValue(request, name, forceValue)
	valueString = request:getModifier(name);
	if valueString ~= "" then
		if forceValue ~= nil then
			return forceValue;
		else
			return tonumber(valueString);
		end
	end
	
	return 0;
end

function updateModDescription()
	request = getRequest();
	roll_button.setText(request:getDescription());
end

function getRequest()
	return RFIWrapper.wrapRequest(getDatabaseNode())
end