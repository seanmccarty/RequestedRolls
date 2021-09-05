currentFoldName = ""
defaultFilter = ""

function onInit()
	if foldName ~= nil then
		currentFoldName = foldName[1];
	end
	
	if filter ~= nil then
		defaultFilter = filter[1];
	end
	
	applyFilter();
end

function onFilter( w )
	local isGroupFold = DB.getValue("RFIA_Root.ui."..currentFoldName, 0);
	local currentFilter = defaultFilter;
	if isGroupFold == 1 then
		currentFilter = "";
	end

	return window.filter(currentFilter, w.getDatabaseNode());
end

function toggleFold()
	nodePath = "RFIA_Root.ui."..currentFoldName;
	local isGroupFold = DB.getValue(nodePath, 0);
	if isGroupFold == 0 then
		DB.setValue(nodePath, "number", 1);
	else
		DB.setValue(nodePath, "number", 0);
	end
	
	applyFilter();
end

function isFold()
	return DB.getValue("RFIA_Root.ui."..currentFoldName, 0) == 1;
end