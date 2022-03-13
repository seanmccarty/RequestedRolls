local buttonUpImage = "RFIA_DefaultButtonUp";
local buttonDownImage = "RFIA_DefaultButtonDown";
local dbRootName = "requestsheet";
local createRequestWindowName = "RequestRolls";

bDebug = false;

function onInit()
	if Session.IsHost then DB.createNode(dbRootName); end
    registerOptions();
	registerSlashHandlers();
    registerExtensions();
	initializeDirtyState();
	runMigration();
end

--#region options manager

---Loads the options onto the settings page. Also, adds the shortcut item to the bar if enabled.
function registerOptions()
	-- This option is not currently used
	--OptionsManager.registerOption2("RR_option_label_showDC", false, "RR_option_header", "RR_option_label_showDC", "option_entry_cycler", 
	--		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" });
			
	OptionsManager.registerOption2("RR_option_label_pcRolls", true, "option_header_client", "RR_option_label_pcRolls", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	

	OptionsManager.registerOption2("RR_option_label_alwaysShowManualDice", true, "option_header_client", "RR_option_label_alwaysShowManualDice", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
			
	OptionsManager.registerOption2("RR_option_label_npcRolls", false, "RR_option_header", "RR_option_label_npcRolls", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
	
	OptionsManager.registerOption2("RR_option_label_modAfterDisplay", false, "RR_option_header", "RR_option_label_modAfterDisplay", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });

	OptionsManager.registerOption2("RR_option_label_rollJSON", false, "RR_option_header", "RR_option_label_rollJSON", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });

	OptionsManager.registerOption2("RR_option_label_broadcastCancellation", false, "RR_option_header", "RR_option_label_broadcastCancellation", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	
		--the button to show/hide the shortcut is only shown for the GM
	if Session.IsHost then
		OptionsManager.registerOption2("RR_option_label_sidebar", true, "RR_option_header", "RR_option_label_sidebar", "option_entry_cycler", 
			{ labels = "RR_option_val_hide", values = "hide", baselabel = "RR_option_val_show", baseval = "show", default = "show" });	
		
		--Now that options have been registered we can 	add the shortcut
		if 	OptionsManager.isOption("RR_option_label_sidebar", "show") then
			local tButton = { sIcon = "RR_sidebar", tooltipres = "RR_window_title", class = createRequestWindowName, path = dbRootName };
			DesktopManager.registerSidebarToolButton(tButton, 8);

			--table.insert(Desktop.aCoreDesktopStack["host"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres="RR_window_title", class=createRequestWindowName, path=dbRootName});
		end
	end
end

---Checks if the automatic vs throws option is on for PCs.
---On means it should popup a throw when a vs throw is made against the player.
---@return boolean "true if option is on"
function isManualSaveRollPcOn()
	return OptionsManager.isOption("RR_option_label_pcRolls", "on");
end

---Checks if the automatic vs throws option is on for NPCs.
---On means it should popup a throw when a vs throw is made against the player.
---@return boolean "true if option is on"
function isManualSaveRollNpcOn()
	return OptionsManager.isOption("RR_option_label_npcRolls", "on");
end

--#endregion

--#region Extensions

---Checks if certain extensions are loaded. Enables a central point to manage the names.
function registerExtensions()
	--currently empty
end

---Lists loaded extension names to the console
function listExtensions()
    for _, extension in ipairs(Extension.getExtensions()) do
    	Debug.console("listExtension", Extension.getExtensionInfo(extension).name);
    end
end

---Loops through the extension list checking extension names
---@param extensionName string the name of the extension to be checked
---@return boolean bool is the extension enabled
function isExtensionEnabled(extensionName)
    for _, extension in ipairs(Extension.getExtensions()) do
    	if Extension.getExtensionInfo(extension).name == extensionName then
			return true;
		end
    end
	return false;
end

--#endregion

--#region slash handler

---Registers the slash handlers that RR uses. This groups the calls together to make onInit easier to read
function registerSlashHandlers()
	Comm.registerSlashHandler("RR", processRRCommandList);
	Comm.registerSlashHandler("RRrolls", processRRRolls);
	if Session.IsHost  then
		Comm.registerSlashHandler("RRconsole", processRRConsole);
	end
	Comm.registerSlashHandler("RRdebug",processRRdebug);
end

---Outputs the list of available commands to the chat log
---@param sCommand string not used
---@param sParams string not used
function processRRCommandList(sCommand, sParams)
	ChatManager.SystemMessage(Interface.getString("message_slashcommands"));
	ChatManager.SystemMessage("----------------");

	ChatManager.SystemMessage("/RR \t list of available rfia commands");

	if Session.IsHost  then	
		ChatManager.SystemMessage("/RRconsole \t DM only - open the create request window");
	end	

	ChatManager.SystemMessage("/RRrolls \t open the rolls window");
	ChatManager.SystemMessage("/RRdebug <on/off> \t sets the debug status");
end

---Opens the rolls window to make the actual rolls
---@param sCommand string not used
---@param sParams string not used
function processRRRolls(sCommand, sParams)
	Interface.openWindow("manualrolls", "");
end

---Opens the console window, if host, to send rolls to users
---@param sCommand string not used
---@param sParams string not used
function processRRConsole(sCommand, sParams)
	if Session.IsHost  then		
		Interface.openWindow(createRequestWindowName, dbRootName);
	end	
end

---Sets debug status. Flips status if on/off parameter is not passed.
---Also lists current extensions to the log.
---@param sCommand string not used
---@param sParams string|nil on or off
function processRRdebug(sCommand, sParams)
	sParams = StringManager.trim(sParams);
	if sParams == "off" then
		RR.bDebug = false;
	else
		if sParams == "on" then
			RR.bDebug = true;
		else
			RR.bDebug = not RR.bDebug;
		end
	end
	ChatManager.SystemMessage("RR debug mode is ".. tostring(RR.bDebug));
	if RR.bDebug then
		listExtensions();
	end
end

--#endregion

---comment Checks through all combatants for the number field that the selector button is tied to
---@return table selectedCharacters a list of selected characters
function getSelectedChars()
    list = {};
    for _,entry in pairs(CombatManager.getCombatantNodes()) do
        if DB.getValue(entry,"RRselected")==1 then
            table.insert(list, entry);
        end
    end
    return list;
end

---Clear selected characters and then select the same as the currently active node in the CT
function mirrorTargeting()
	for _,entry in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(entry,"RRselected", "number", 0);
	end
	for _,entry in pairs(TargetingManager.getFullTargets(CombatManager.getActiveCT())) do
		DB.setValue(entry.sCTNode .. ".RRselected", "number", 1);
	end
end

---Initialize the OOB handler and go through all combat tracker nodes and set them that they have no pending rolls
function initializeDirtyState()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYDIRTY, handleApplyDirtyRR);
	for _, value in pairs(DB.getChildren("combattracker.list")) do
		DB.setValue(DB.getPath(value,"RRdirty"),"number",0);
	end
end

OOB_MSGTYPE_APPLYDIRTY = "applydirtyRR";

---Sets the RRdirty status for a given node
---@param msgOOB table 
function handleApplyDirtyRR(msgOOB)
	DB.setValue(msgOOB.sCTNode .. ".RRdirty","number",tonumber(msgOOB.isDirty));
end

---Send the status of whether there are more rolls to the host so that it can be updated
---@param sCTNode string the string representation of the CTnode to be set
---@param isDirty number 0 means all rolls are done, 1 means they have rolls to do
function notifyApplyDirty(sCTNode, isDirty)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYDIRTY;
	msgOOB.sCTNode = sCTNode;
	msgOOB.isDirty = isDirty;
	Comm.deliverOOBMessage(msgOOB, "");
end

---Migrates the nodes to data structure v2.3
function runMigration()
	migrateNode("requestsheet.checklist","requestsheet.check.list" );
	migrateNode("requestsheet.savelist","requestsheet.save.list" );
	migrateNode("requestsheet.skilllist","requestsheet.skill.list" );

	migrateNode("requestsheet.checkdc","requestsheet.check.dc");
	migrateNode("requestsheet.checkselected","requestsheet.check.selected");
	migrateNode("requestsheet.checklistcollapsed","requestsheet.check.collapsed");
	migrateNode("requestsheet.savedc","requestsheet.save.dc");
	migrateNode("requestsheet.saveselected","requestsheet.save.selected");
	migrateNode("requestsheet.savelistcollapsed","requestsheet.save.collapsed");
	migrateNode("requestsheet.skilldc","requestsheet.skill.dc");
	migrateNode("requestsheet.skillselected","requestsheet.skill.selected");
	migrateNode("requestsheet.skilllistcollapsed","requestsheet.skill.collapsed");

end

---Copies a source node to the destination and deletes the source node
---@param source string the node to be moved
---@param destination string the node to which you want the data copied
function migrateNode(source, destination)
	if DB.findNode(source) and DB.findNode(destination) == nil then
		DB.copyNode(source,destination);
		DB.deleteNode(source);
	end
end