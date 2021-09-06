local dbRootName = "RFIA_Root";
local buttonUpImage = "RFIA_DefaultButtonUp";
local buttonDownImage = "RFIA_DefaultButtonDown";
local tooltipTextKey = "RFIA_window_title";
local isSidebarInitialized = false;
local createRequestWindowName = "RequestRolls";
local rollRequestWindowName = "RFIA_RollRequest";

function onInit()
	registerNodes();
	updateButtons();
end

function getDbRootName()
	return dbRootName;
end

-- Create the root node
function registerNodes()
	if User.isHost() then 
		rootNode = DB.createNode(dbRootName);
	end
end

function updateButtons()

	if RFIAExtensionManager.isCoreSideBarThemeEnabled() or RFIAExtensionManager.isColoredSideBarThemeEnabled() then
		buttonUpImage = "RFIA_CoreSidebarButtonUp";
		buttonDownImage = "RFIA_CoreSidebarButtonDown";	
	elseif RFIAExtensionManager.is5EThemeEnabled() then
		buttonUpImage = "RFIA_5EThemeSidebarButtonUp";
		buttonDownImage = "RFIA_5EThemeSidebarButtonDown";			
	end
end


function openCreateRequestWindow()
	if User.isHost() then
		Interface.openWindow(createRequestWindowName, dbRootName);
	end
end


--function deprecated
function updateSidebarShortcut()
	-- Debug.console("updateSidebarShortcut isHideSideBarButtonOn", RFIAOptionsManager.isHideSideBarButtonOn());
	if RFIAOptionsManager.isHideSideBarButtonOn() then
		-- Debug.console("Returning");
		return;
	end

	if User.isHost() then
		--change to useing the desktop stack
		--registerSideBarShortcuts(createRequestWindowName, dbRootName);
		table.insert(Desktop.aCoreDesktopStack["host"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres=tooltipTextKey, class=createRequestWindowName, path=dbRootName});
	else
		requestListNode = RFIARequestManager.createOrGetRequestGroupForPlayer(User.getUsername());
		if requestListNode ~= nil then
			-- Debug.console("updateSidebarShortcut", rollRequestWindowName,requestListNode.getPath() );
			registerSideBarShortcuts(rollRequestWindowName, requestListNode.getPath());
			--table.insert(Desktop.aCoreDesktopStack["client"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres=tooltipTextKey, class=rollRequestWindowName, path=requestListNode.getPath()});
		end
	end
end

function createSideBarShortcut()
	table.insert(Desktop.aCoreDesktopStack["host"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres=tooltipTextKey, class=createRequestWindowName, path=dbRootName});
	--requestListNode = RFIARequestManager.createOrGetRequestGroupForPlayer(User.getUsername());
	--if requestListNode ~= nil then
		--registerSideBarShortcuts(rollRequestWindowName, requestListNode.getPath());
	--	table.insert(Desktop.aCoreDesktopStack["client"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres=tooltipTextKey, class=rollRequestWindowName, path=requestListNode.getPath()});
	--end
end

--functiion deprecated
function registerSideBarShortcuts(windowName, datanodePath)
	-- Debug.console("registerSideBarShortcut");
	if isSidebarInitialized == false then	
		-- Debug.console("rfia.lua registerSideBarShortcuts buttonUpImage", buttonUpImage);
		-- Debug.console("rfia.lua registerSideBarShortcuts buttonUpImage", buttonDownImage);
		-- Debug.console("rfia.lua registerSideBarShortcuts buttonUpImage", tooltipTextKey);
		-- Debug.console("rfia.lua registerSideBarShortcuts buttonUpImage", windowName);
		-- Debug.console("rfia.lua registerSideBarShortcuts buttonUpImage", datanodePath);

		DesktopManager.registerStackShortcut2(
			buttonUpImage,
			buttonDownImage,
			tooltipTextKey,
			windowName,
			datanodePath,
			true);
		
		if MenuManager  then
			--add better menu menu by loading to tree like your supposed to
			--MenuManager.addMenuItem(windowName, datanodePath, tooltipTextKey, "RFIA");
		end		
			
		isSidebarInitialized = true;
	end
end
--function deprecated
function deregisterSidebarShortcut()		
	if User.isHost() then
		DesktopManager.removeStackShortcut(createRequestWindowName);
	else
		requestListNode = RFIARequestManager.createOrGetRequestGroupForPlayer(User.getUsername());
		if requestListNode ~= nil then
			DesktopManager.removeStackShortcut(rollRequestWindowName);
		end		
	end
	isSidebarInitialized = false;
	DesktopManager.updateControls();
end

-- Select the roll to be requested
function selectRoll(rollNode)
	roll = RFIWrapper.wrapRoll(rollNode);
	RFIARollManager.selectRoll(roll);
	RFIARequestManager.updateCanRequestRoll();
end

function getRoll(name, category)
	return RFIARollManager.getRollNode(name, category);
end

function unselectRolls()
	RFIARollManager.resetSelectedRoll();
	RFIARequestManager.updateCanRequestRoll();
end



-- function selectNPCByName(name)
	-- RFIANpc.unselectAll();
	-- RFIANpc.selectPCByName(name);
	-- RFIARequestManager.updateCanRequestRoll();
-- end

-- function resetAllNPCState()
	-- RFIANpc.setAllRollState(0);
-- end