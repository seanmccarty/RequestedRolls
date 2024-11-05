function onInit()
	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
end

function onEditModeChanged()
	local bEditMode = WindowManager.getEditMode(window, "sheet_iedit");
	for _,w in ipairs(getWindows()) do
			w.idelete.setVisible(bEditMode);
	end
end

function addEntry(bFocus)
	local w = createWindow();
	w.show.setValue(1);
	w.show_expander.setValue(0);
	if bFocus and w then
		w.name.setFocus();
	end
	return w;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

--TODO delete after constructing initial rolls in RR onInit for other rulesets
-- checks 
function constructDefaultChecks()
	buildList(DataCommon.ability_ltos,DataCommon.psabilitydata);
end

-- default saves, ability data is for non-5E rulesets
function constructDefaultSaves()
	if DataCommon.save_ltos then 
		aSave = DataCommon.save_ltos;
	else
		aSave = DataCommon.ability_ltos;
	end

	if DataCommon.pssavedata then 
		aPsSave = DataCommon.pssavedata;
	else
		aPsSave = DataCommon.psabilitydata;
	end

	buildList(aSave, aPsSave);
end