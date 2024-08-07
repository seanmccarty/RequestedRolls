local dbRootName = "requestsheet";
local createRequestWindowName = "RequestRolls";

-- Extension wide control of when extension specific debug is enabled
bDebug = false;

function onInit()
	if Session.IsHost then DB.createNode(dbRootName); end
	registerOptions();
	registerSlashHandlers();
	initializeDirtyState();
	runMigration();
end

--#region options manager

---Loads the options onto the settings page. Also, adds the shortcut item to the bar if enabled.
function registerOptions()
	OptionsManager.registerOption2("RR_option_label_pcRolls", true, "RR_option_header", "RR_option_label_pcRolls", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	

	OptionsManager.registerOption2("RR_option_label_alwaysShowManualDice", true, "RR_option_header", "RR_option_label_alwaysShowManualDice", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
			
	OptionsManager.registerOption2("RR_option_label_npcRolls", false, "RR_option_header", "RR_option_label_npcRolls", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	

	OptionsManager.registerOption2("RR_option_label_broadcastCancellation", false, "RR_option_header", "RR_option_label_broadcastCancellation", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });

	OptionsManager.registerOption2("RR_option_label_allowRollStaging", false, "RR_option_header", "RR_option_label_allowRollStaging", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });

	OptionsManager.registerOption2("RR_option_label_suppressDiceAnimations", true, "RR_option_header", "RR_option_label_suppressDiceAnimations", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
	
		--the button to show/hide the shortcut is only shown for the GM
	if Session.IsHost then
		OptionsManager.registerOption2("RR_option_label_sidebar", true, "RR_option_header", "RR_option_label_sidebar", "option_entry_cycler", 
			{ labels = "RR_option_val_hide", values = "hide", baselabel = "RR_option_val_show", baseval = "show", default = "show" });	
		
		--Now that options have been registered we can 	add the shortcut
		if 	OptionsManager.isOption("RR_option_label_sidebar", "show") then
			local tButton = { sIcon = "RR_sidebar", tooltipres = "RR_window_title", class = createRequestWindowName, path = dbRootName };
			DesktopManager.registerSidebarToolButton(tButton, 8);
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

--#region slash handler

local OOB_MSGTYPE_APPLYCLIENTSAVE = "applyClientSaveRR";
local OOB_MSGTYPE_APPLYNODICE = "applyNoDiceRR";

---Registers the slash handlers that RR uses. This groups the calls together to make onInit easier to read
function registerSlashHandlers()
	Comm.registerSlashHandler("RR", processRRCommandList);
	Comm.registerSlashHandler("RRrolls", processRRRolls);
	if Session.IsHost  then
		Comm.registerSlashHandler("RRconsole", processRRConsole);
		Comm.registerSlashHandler("RRclientsaves", processRRClientSaves);
		Comm.registerSlashHandler("RRnodice", processRRNoDice);
	end
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCLIENTSAVE, handleApplyClientSaveRR);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYNODICE, handleApplyClientNoDiceRR);
	Comm.registerSlashHandler("RRdebug",processRRdebug);
	Comm.registerSlashHandler("RRcmd",processRRcmd);
end

---Outputs the list of available commands to the chat log
---@param sCommand string not used
---@param sParams string not used
function processRRCommandList(sCommand, sParams)
	ChatManager.SystemMessage(Interface.getString("message_slashcommands"));
	ChatManager.SystemMessage("----------------");

	ChatManager.SystemMessage("/RR \t list of available RR commands");

	if Session.IsHost  then	
		ChatManager.SystemMessage("/RRconsole \t DM only - open the create request window");
		ChatManager.SystemMessage("/RRclientsaves \t DM only - sets clients to show popups for saves");
		ChatManager.SystemMessage("/RRnodice \t DM only - sets clients to suppress 3D dice" );
		ChatManager.SystemMessage("/RRcmd \t DM only - generates a roll request");
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

---Sends message to set all clients and the host to show popup rolls for saves
---@param sCommand string not used
---@param sParams string not used
function processRRClientSaves(sCommand, sParams)
	if Session.IsHost then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_APPLYCLIENTSAVE;
		Comm.deliverOOBMessage(msgOOB);
		ChatManager.SystemMessage("Clients set to show popup saves.");
	end
end

---handler for OOB_MSGTYPE_APPLYCLIENTSAVE
function handleApplyClientSaveRR()
	ChatManager.SystemMessage("The GM has set your client to show popups for saving throws via Requested Rolls.");
	OptionsManager.setOption("RR_option_label_pcRolls","on");
end

---Sends message to set all clients and the host to suppress 3d dice
---@param sCommand string not used
---@param sParams string not used
function processRRNoDice(sCommand, sParams)
	if Session.IsHost then
		local msgOOB = {};
		msgOOB.type = OOB_MSGTYPE_APPLYNODICE;
		Comm.deliverOOBMessage(msgOOB);
		ChatManager.SystemMessage("Clients set to suppress 3D dice.");
	end
end

---handler for OOB_MSGTYPE_APPLYNODICE
function handleApplyClientNoDiceRR()
	ChatManager.SystemMessage("The GM has set your client to not use 3D dice via Requested Rolls.");
	OptionsManager.setOption("RR_option_label_suppressDiceAnimations","on");
end

---Sets debug status. Flips status if on/off parameter is not passed.
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
end

---A working implementation of slash command. Advanced command to be added on request.
---@param sCommand string not used
---@param sParams string a string with entries separated by |. Each entry has the parameter name followed by a colon and the command
---All command except sType are optional. If no targets are specified, it will use the current selections from the console.
---sTargetType is all, PC, or NPC
--- /RRcmd type:check|subType:charisma|DC:10|target:KitKat the Kindly
function processRRcmd(sCommand, sParams)
	local _sType = "";
	local _sSubType = "";
	local _bSecret = false;
	local _nTargetDC = nil;
	local _sTargetType = "";
	local _tTargets = {};

	local cases = {
		["type"] = function (param) _sType = param; end,
		["subType"] = function (param) _sSubType = param; end,
		["secret"] = function (param) _bSecret = param == "true"; end,
		["DC"] = function (param) _nTargetDC = tonumber(param); end,
		["targetType"] = function (param) _sTargetType = param; end,
		["target"] = function(param)
			for _,entry in pairs(CombatManager.getCombatantNodes()) do
				if ActorManager.getDisplayName(entry) == param then
					local rActor = ActorManager.resolveActor(entry);
					if rActor then
						table.insert(_tTargets, rActor);
					end
				end
			end
		end
	}

	local entries = StringManager.split(sParams,"|",true);
	for _, entry in ipairs(entries) do
		local cmd = StringManager.split(entry,":",true);
		if cmd[1] and cmd[2] then
			cases[cmd[1]](cmd[2]);
		else
			ChatManager.SystemMessage("Malformed parameters for RR command: "..entry);
		end
	end
	if not(_sTargetType=="") then
		if _sTargetType=="all" then
			for _,entry in pairs(CombatManager.getCombatantNodes()) do
				table.insert(_tTargets, entry);
			end
		else
			_tTargets = RR.getAllCharactersByType(_sTargetType)
		end
	end
	Debug.chat(_tTargets)

	if #_tTargets==0 then
		_tTargets = RR.getSelectedChars();
	end
	RRRollManager.requestRoll(_sType, _sSubType, _tTargets, _bSecret, _nTargetDC);
end

--#endregion

---Checks through all combatants in the combat tracker for the number field that the selector button is tied to
---@return table selectedCharacters a list of selected characters
function getSelectedChars()
	local list = {};
	for _,entry in pairs(CombatManager.getCombatantNodes()) do
		if DB.getValue(entry,"RRselected")==1 then
			table.insert(list, entry);
		end
	end
	return list;
end

---Gets all characters of a given type from the combattracker
---@param sType string PC or NPC for type
---@return table list the 
function getAllCharactersByType(sType)
	local isPC = false;
	if sType == "PC" then
		isPC = true;
	end
	local list = {};
	for _,entry in pairs(CombatManager.getCombatantNodes()) do
		if ActorManager.isPC(entry)==isPC then
			table.insert(list, entry);
		end
	end
	return list;
end

---Selects all characters of a given type for RR rolls
---@param sType string same as getAllCharactersByType(sType)
function characterSelectAllByType(sType)
	for _,entry in pairs(getAllCharactersByType(sType)) do
		DB.setValue(entry,"RRselected", "number", 1);
	end
end

---Selects all characters of a given type for RR rolls
---@param sType string same as getAllCharactersByType(sType)
function characterDeselectAllByType(sType)
	for _,entry in pairs(getAllCharactersByType(sType)) do
		DB.setValue(entry,"RRselected", "number", 0);
	end
end

function characterDeselectAll()
	for _,entry in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(entry,"RRselected", "number", 0);
	end
end

---Selects all characters of a given type for RR rolls
---@param sType string same as getAllCharactersByType(sType)
function characterSelectRandomByType(sType)
	local list = getAllCharactersByType(sType);
	local numberOfChars = #list;
	if numberOfChars > 0 then 
		RR.characterDeselectAllByType(sType);
		local randomIndex = math.random(numberOfChars);
		DB.setValue(list[randomIndex],"RRselected", "number", 1);
	end
end

---Clear selected characters and then select the same targets as the specificied actor
---If rActor is nil, it uses the currently active node in the CT
---@param rActor table the actor of interest
function mirrorTargeting(rActor)
	characterDeselectAll();
	if rActor == nil then
		rActor = CombatManager.getActiveCT();
	end

	for _,entry in pairs(TargetingManager.getFullTargets(rActor)) do
		DB.setValue(ActorManager.getCTNodeName(entry) .. ".RRselected", "number", 1);
	end
end

---Zeroes out the current selection and reuses other skill check code to select whoever has the skill proficiency 
---The button that uses this should be disabled  in rulesets where it is not applicable.
---@param sSkill string the skill to be used for targeting
function targetSkillProficency(sSkill)
	characterDeselectAll();
	for _,rActor in pairs(CombatManager.getCombatantNodes()) do
		local nodeActor = ActorManager.getCreatureNode(rActor);

		--if it is an NPC, parse for the particular skill. fall through if it is not found or it is a PC
		if not ActorManager.isPC(rActor) then
			local aSkills = RRRollManager.parseComponents(nodeActor);
			if aSkills then
				for k,node in pairs(aSkills) do
					if string.lower(node.sLabel) ==  string.lower(sSkill) then
						DB.setValue(ActorManager.getCTNodeName(rActor) .. ".RRselected", "number", 1);
					end
				end
			end
		else
			for _,nodeSkill in pairs(DB.getChildren(nodeActor, "skilllist")) do
				local sNodeName =  "label";
				--5E has a different node name
				if Interface.getRuleset()=="5E" then
					sNodeName = "name";
				end
				if DB.getValue(nodeSkill, sNodeName, "") == sSkill then
					if DB.getValue(nodeSkill, "prof", 0) > 0 then
						DB.setValue(ActorManager.getCTNodeName(rActor) .. ".RRselected", "number", 1);
					end
				end
			end
		end
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

---Comparator function to allow for natual sort. Particularly useful for dice strings
function naturalSort(a,b)
	local function conv(s)
		local res, dot = "", ""
		for n, m, c in tostring(s):gmatch"(0*(%d*))(.?)" do
			if n == "" then
				dot, c = "", dot..c
			else
				res = res..(dot == "" and ("%03d%s"):format(#m, m) or "."..n)
				dot, c = c:match"(%.?)(.*)"
			end
			res = res..c:gsub(".", "\0%0")
		end
		return res
	end
	local ca, cb = conv(a), conv(b)
	return ca < cb or ca == cb and a < b
end


