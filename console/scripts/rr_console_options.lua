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