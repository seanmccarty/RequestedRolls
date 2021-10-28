local RFIA_MODIFIERS = "RFIA_Root.modifiers";

function onInit()
	createNodes();
end

function createNodes()
	if Session.IsHost then 
		createNode(RFIA_MODIFIERS);
		populateModifiers();
	end
end

function createNode(name)
	rootNode = DB.createNode(name);
	rootNode.delete();
	rootNode = DB.createNode(name)
end

function populateModifiers()
	if User.getRulesetName()=="5E" then
		createModifier("ADV", "number");
		createModifier("DIS", "number");
	end
	createModifier("PLUS2", "number");
	createModifier("PLUS5", "number");
	createModifier("MINUS2", "number");
	createModifier("MINUS5", "number");
	createModifier("HIDDEN", "number");
	createModifier("DC", "number");
end

function createModifier(name)
	node = DB.createChild(RFIA_MODIFIERS, name, "number");
	node.setValue(0);	
end

function setModifier(name, value)
	node = DB.getChild(RFIA_MODIFIERS, name);
	node.setValue(value);
	-- local wndMod = getModifiersWindow();
	-- wndMod.setButtonWithName(name,value);
end

function clearAllModifierButtons()

	local wndMod = getModifiersWindow();
	wndMod.clearButtons()
	RFIAModifierStack.reset();
	
	-- for _,modifier in pairs(getModifiers()) do
		-- node.setValue(0);
	-- end
end

function getModifiers()
	return DB.getChildren(RFIA_MODIFIERS);
end

function getModifiersWindow()
	return Interface.findWindow("RequestRolls", RFIA.getDbRootName()).RFIA_modifiers_subwindow.subwindow;
end
