--[[
Listens to the CT, if skills are changed for an entry then we update.
]]

function onInit()
	if User.isHost() then
		registerToCTEvents();
	end
end


function registerToCTEvents()
	DB.addHandler(CombatManager.CT_LIST, "onChildAdded", onCtItemAdded);
	initCurrentCTItems();
end

function onCtItemAdded(nodeParent, nodeChildAdded)
	DB.addHandler(nodeChildAdded.getPath(), "onDelete", deregisterChildNodes);
	RFIAEntriesManager.initCT(nodeChildAdded);
	registerChildNodes(nodeChildAdded);
end

function registerChildNodes(nodeChildAdded)
	      DB.addHandler(nodeChildAdded.getPath() .. ".skills", "onUpdate", onSkillsChanged);
end

function deregisterChildNodes(nodeChildAdded)
	   DB.removeHandler(nodeChildAdded.getPath() .. ".skills", "onUpdate", onSkillsChanged);
end

function initCurrentCTItems()
	for _,node in pairs(RFIAEntriesManager.getCTEntries()) do
		registerChildNodes(node);
	end
end

function onSkillsChanged(node)
	RFIAEntriesManager.initialiseNpcEntrySkills(node.getParent());
end

