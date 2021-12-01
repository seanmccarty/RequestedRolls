function onInit()
	-- Debug.console("rfia_entry.lua onInit");
	-- if selfCheck() then
		-- updateDisplay()
		-- registerChildNodes(getDatabaseNode());
	-- end
	local node = getDatabaseNode();
	registerLinkNode(node);
	checkEntryFromInit(node);
end


--Filter seems to be really slow, so instead we are doing our own filter and just closing the entry if it doesnt belong.
function selfCheck()
	-- Debug.console("rfia_entry.lua selfCheck windowlist", windowlist);
	-- Debug.console("rfia_entry.lua selfCheck windowlist.window", windowlist.window);
	-- Debug.console("rfia_entry.lua selfCheck windowlist.entryType", windowlist.parameters[1].listType[1]);
	entryNode = getDatabaseNode();
	local class, recordname = DB.getValue(entryNode, "link","string","");
	-- Debug.console("rfia_entry.lua selfCheck class", class);
	-- Debug.console("rfia_entry.lua selfCheck recordname", recordname);
	-- Debug.console("rfia_entry.lua selfCheck windowlist.parameters[1].listType[1] == class", windowlist.parameters[1].listType[1] == class)
	if windowlist.parameters[1].listType[1] ~= class then
		-- Debug.console("Closing myself");
		close();
		return false;
	end
	return true;
end


function onClose()
	deregisterChildNodes(getDatabaseNode());
end

function registerLinkNode(node)
	DB.addHandler(node.getPath() .. ".link", "onUpdate", checkEntryFromHandler);
end

function checkEntryFromInit(node)
	class, recordname = DB.getValue(node.getPath() .. ".link");
	checkEntry(class, node);
end

function checkEntryFromHandler(linkNode)
	class, recordname = DB.getValue(linkNode.getPath());
	checkEntry(class, linkNode.getParent());
end

function checkEntry(class, node)
	if class ~= nil and class ~= "" then
		if selfCheck() then
			-- Debug.console("Self check successful going to update now! node", node);
			updateDisplay();
			registerChildNodes(node);
		end
	end
end

function registerChildNodes(node)
		DB.addHandler(node.getPath() .. ".name", "onUpdate", onNameUpdated);
		DB.addHandler(node.getPath() .. ".nonid_name", "onUpdate", onNameUpdated);
		DB.addHandler(node.getPath() .. ".isidentified", "onUpdate", onNameUpdated);
		DB.addHandler(node.getPath() .. ".rollStatusForRFIA","onUpdate", updateRollStatusDisplay);
end

function deregisterChildNodes(node)
	-- Debug.console("deregisterChildNodes");
	DB.removeHandler(node.getPath() .. ".link", "onUpdate", checkEntryFromHandler);
	DB.removeHandler(node.getPath() .. ".name", "onUpdate", onNameUpdated);
	DB.removeHandler(node.getPath() .. ".nonid_name", "onUpdate", onNameUpdated);	
	DB.removeHandler(node.getPath() .. ".isidentified", "onUpdate", onNameUpdated);
	DB.removeHandler(node.getPath() .. ".rollStatusForRFIA","onUpdate", updateRollStatusDisplay);
end

function onNameUpdated()
	-- Debug.console("rfia_entry.lua onNameUpdated");
	updateDisplay();
end

function updateDisplay()
	-- Debug.console("rfia_entry.lua updateDisplay for ",  getDatabaseNode());
	updateToolTipText();
	updateToggleDisplay();
	updateRollStatusDisplay()
end

function updateToolTipText()
	-- Debug.console("rfia_entry.lua updateToolTipText");
	selection.setTooltipText(name.getValue());
end

function updateToggleDisplay()
	-- Debug.console("rfia_entry.lua updateToggleDisplay");
	if isSelectedForRFIA.getValue() == 0 then
		selection.setIcon("RFI_PcUnselected");
	else 
		selection.setIcon("RFI_PcSelected");
	end
end

function updateRollStatusDisplay()
	-- Debug.console("rfia_entry.lua updateRollStatusDisplay");
	local status = rollStatusForRFIA.getValue();
	if status == 1 then
		roll_status.setIcon("RFI_RollNotDone");
		roll_status.setVisible(true);
	elseif status == 2 then
		roll_status.setIcon("RFI_RollDone");
		roll_status.setVisible(true);
	else
		roll_status.setVisible(false);
		roll_status.setIcon("");
	end
end

function toggleEntry()
	-- Debug.console("rfia_entry.lua toggleEntry");
	if isSelectedForRFIA.getValue() == 0 then
		setEntrySelected();
	else 
		setEntryUnselected();
	end	
end

function setEntrySelected()
	-- Debug.console("rfia_entry.lua setEntrySelected");
	selection.setIcon("RFI_PcSelected");
	isSelectedForRFIA.setValue(1);
end
function setEntryUnselected()
	-- Debug.console("rfia_entry.lua setEntryUnselected");
	selection.setIcon("RFI_PcUnselected");
	isSelectedForRFIA.setValue(0);
end


function onHover(state)
	-- Debug.console("rfia_entry.lua onHover");
	if state == true then
		selection.setIcon("RFI_PcHover");
	else
		updateToggleDisplay();
	end
end