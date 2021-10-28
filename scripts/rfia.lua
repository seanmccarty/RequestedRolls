local dbRootName = "RFIA_Root";
local buttonUpImage = "RFIA_DefaultButtonUp";
local buttonDownImage = "RFIA_DefaultButtonDown";
local tooltipTextKey = "RFIA_window_title";
local createRequestWindowName = "RequestRolls";

bDebug = false;

function onInit()
	registerNodes();
	updateButtons();
end

function getDbRootName()
	return dbRootName;
end

-- Create the root node
function registerNodes()
	if Session.IsHost then 
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
	if Session.IsHost then
		Interface.openWindow(createRequestWindowName, dbRootName);
	end
end

function createSideBarShortcut()
	table.insert(Desktop.aCoreDesktopStack["host"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres=tooltipTextKey, class=createRequestWindowName, path=dbRootName});
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