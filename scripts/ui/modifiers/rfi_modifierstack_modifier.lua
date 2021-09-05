-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onGainFocus()
	RFIAModifierStack.setAdjustmentEdit(true);
end

function onLoseFocus()
	RFIAModifierStack.setAdjustmentEdit(false);
end

function onWheel(notches)
	if not hasFocus() then
		RFIAModifierStack.adjustFreeAdjustment(notches);
	end

	return true;
end

function onValueChanged()
	if hasFocus() and RFIAModifierStack.adjustmentedit then
		RFIAModifierStack.setFreeAdjustment(getValue());
	end
end

function onClickDown(button, x, y)
	if button == 2 then
		RFIAModifierStack.reset();
		return true;
	end
end

function onDrop(x, y, draginfo)
	return window.base.onDrop(x, y, draginfo);
end

function onDragStart(button, x, y, draginfo)
	-- Create a composite drag type so that a simple drag into the chat window won't use the modifiers twice
	draginfo.setType("modifierstack");
	draginfo.setNumberData(RFIAModifierStack.getSum());

	local basedata = draginfo.createBaseData("number");
	basedata.setDescription(RFIAModifierStack.getDescription());
	basedata.setNumberData(RFIAModifierStack.getSum());
	
	return true;
end

function onDragEnd(draginfo)
	RFIAModifierStack.reset();
end
