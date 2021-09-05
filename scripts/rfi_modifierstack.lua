-- 

local control = nil;
freeadjustment = 0;
slots = {};

function registerControl(ctrl)
	control = ctrl;
end

function updateControl()
	if control then
		if adjustmentedit then
			control.label.setValue(Interface.getString("modstack_label_adjusting"));
		else
			control.label.setValue(Interface.getString("modstack_label_modifier"));
			
			if freeadjustment > 0 then
				control.label.setValue("(+" .. freeadjustment .. ")");
			elseif freeadjustment < 0 then
				control.label.setValue("(" .. freeadjustment .. ")");
			end
			
			control.modifier.setValue(getSum());
			
			control.base.resetCounters();
			for i = 1, #slots do
				control.base.addCounter();
			end
			
			if hoverslot and hoverslot ~= 0 and slots[hoverslot] then
				control.label.setValue(slots[hoverslot].description);
			end
		end
		
		if math.abs(control.modifier.getValue()) > 999 then
			control.modifier.setFont("modcollectorlabel");
		else
			control.modifier.setFont("modcollector");
		end
	end
end

function isEmpty()
	if freeadjustment == 0 and #slots == 0 then
		return true;
	end

	return false;
end

function getSum()
	local total = freeadjustment;
	
	for i = 1, #slots do
		total = total + slots[i].number;
	end
	
	return total;
end

function getDescription(forcebonus)
	local s = "";
	
	if not forcebonus and #slots == 1 and freeadjustment == 0 then
		s = slots[1].description;
	else
		local aMods = {};
		
		for i = 1, #slots do
			table.insert(aMods, string.format("%s %+d", slots[i].description, slots[i].number));
		end
		
		if freeadjustment ~= 0 then
			table.insert(aMods, string.format("%+d", freeadjustment));
		end
		
		s = table.concat(aMods, ", ");
	end
	
	return s;
end

function addSlot(description, number)
	if #slots < 6 then
		table.insert(slots, { ['description'] = description, ['number'] = number });
	end
	
	updateControl();
end

function removeSlot(number)
	table.remove(slots, number);
	updateControl();
end

function adjustFreeAdjustment(amount)
	freeadjustment = freeadjustment + amount;
	
	updateControl();
end

function setFreeAdjustment(amount)
	freeadjustment = amount;
	
	updateControl();
end

function setAdjustmentEdit(state)
	if control then
		if state then
			control.modifier.setValue(freeadjustment);
		else
			setFreeAdjustment(control.modifier.getValue());
		end
	end

	adjustmentedit = state;
	updateControl();
end

function reset()
	if control and control.modifier.hasFocus() then
		control.modifier.setFocus(false);
	end

	freeadjustment = 0;
	slots = {};
	updateControl();
end

function hoverDisplay(n)
	hoverslot = n;
	updateControl();
end

function getStack(forcebonus)
	local sDesc = "";
	local nMod = 0;
	
	if not isEmpty() then
		sDesc = getDescription(forcebonus);
		nMod = getSum();
	end
	
	return sDesc, nMod;
end

function onInit()
end