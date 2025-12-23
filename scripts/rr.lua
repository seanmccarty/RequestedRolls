local dbRootName = "requestsheet";
local createRequestWindowName = "RequestRolls";

-- Extension wide control of when extension specific debug is enabled
bDebug = false;

function onInit()
	if Session.IsHost then DB.createNode(dbRootName); end
	registerOptions();
	registerSlashHandlers();
	if Session.IsHost then
		initializeDirtyState();
		-- must run migration before attempting to initialize roll lists
		runMigration();
		if DB.findNode("requestsheet.rolls") == nil then
			initializeRollLists();
		end

		-- 2.20 migration step, check must occur after the rolls are initialized or it will block the rest of the roll types
		if DB.findNode("requestsheet.rolls.table") == nil then
			setComboConfiguration("table","Table",5,0,200);
		end
	end
end

---Used to configure the expander trays on the RR console
---@param rollType string the name for the node used in the database to hold these
---@param display_name string the display name
---@param sort_order number the order it should appear in on the console
---@param dc_show number 0 to hide, 1 to show
---@param button_width number the width in pixels for the button in the expander trays
function setComboConfiguration(rollType, display_name, sort_order,dc_show,button_width)
	DB.setValue("requestsheet.rolls."..rollType..".display_name", "string", display_name);
	DB.setValue("requestsheet.rolls."..rollType..".sort_order", "number", sort_order);
	DB.setValue("requestsheet.rolls."..rollType..".dc_show", "number", dc_show);
	DB.setValue("requestsheet.rolls."..rollType..".button_width", "number", button_width);
end

function setDefaultRollOptions(rollType, rollEntries)
	local node = DB.createNode("requestsheet.rolls."..rollType..".list");
	for _,w in ipairs(rollEntries) do
		local node2 = DB.createChild(node);
		DB.setValue(node2,"name","string",w);
		DB.setValue(node2, "show", "number", "1");
	end
end

function initializeRollLists()
	setComboConfiguration("dice","Die",4,0,100);
	local dice = {"d4","d6","d8","d10","d20","d100"};
	setDefaultRollOptions("dice",dice);

	setComboConfiguration("table","Table",5,0,200);
	-- no defaults for tables

	if Interface.getRuleset()=="CoreRPG" then
		setComboConfiguration("skill","Skill",3,1,65)
	end

	local nShowDC = 1;
	if Interface.getRuleset()=="2E" then
		nShowDC = 0;
	end
	-- For each of the rollTypes, where the data is stored depends on the ruleset, try the common names in each rulset until one of them is found
	if DataCommon then
		local abilityData = DataCommon.psabilitydata;
		if abilityData == nil then
			abilityData = DataCommon.abilities;
		end
		if abilityData then 
			setComboConfiguration("check","Check",1,nShowDC,65);
			setDefaultRollOptions("check", abilityData);
		end
		-- TODO add cleaner handling of initialization
		local saveData = DataCommon.pssavedata;
		if saveData==nil then
			saveData = DataCommon.psabilitydata;
		end
		if saveData==nil then
			saveData = DataCommon.saves;
		end
		if Interface.getRuleset()=="4E" then
			saveData = nil;
		end
		if saveData then 
			setComboConfiguration("save","Save",2,nShowDC,65);
			setDefaultRollOptions("save",saveData);
		end

		if DataCommon.skilldata then
			setComboConfiguration("skill","Skill",3,nShowDC,125);
			--cannot use normal setDefaultRollOptions becuase skilldata has a different format
			local node = DB.createNode("requestsheet.rolls.skill.list");
			for k, _ in pairs(DataCommon.skilldata) do
				local node2 = DB.createChild(node);
				DB.setValue(node2,"name","string",k);
				DB.setValue(node2, "show", "number", "1");
			end
		end

		if Interface.getRuleset()=="2E" then
			setComboConfiguration("skill","Skill",3,nShowDC,125);
		end
	end
end

--#region options manager

---Loads the options onto the settings page. Also, adds the shortcut item to the bar if enabled.
function registerOptions()
	OptionsManager.registerOptionData({sKey = "RR_option_label_pcRolls", bLocal = true, sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_pcRolls"});	

	OptionsManager.registerOptionData({sKey = "RR_option_label_alwaysShowManualDice", bLocal = true, sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_alwaysShowManualDice"});	
			
	OptionsManager.registerOptionData({sKey = "RR_option_label_npcRolls", sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_npcRolls"});	

	OptionsManager.registerOptionData({sKey = "RR_option_label_broadcastCancellation", sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_broadcastCancellation"});

	OptionsManager.registerOptionData({sKey = "RR_option_label_allowRollStaging", sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_allowRollStaging",tCustom = { default = "on" } });

	OptionsManager.registerOptionData({sKey = "RR_option_label_suppressDiceAnimations", bLocal = true, sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_suppressDiceAnimations"});
	
		--the button to show/hide the shortcut is only shown for the GM
	if Session.IsHost then
		OptionsManager.registerOptionData({sKey ="RR_option_label_sidebar", bLocal = true, sGroupRes ="RR_option_header", sLabelRes = "RR_option_label_sidebar", 
			tCustom = { labelsres = "RR_option_val_hide", values = "hide", baselabelres = "RR_option_val_show", baseval = "show", default = "show" }});	
		
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
local OOB_MSGTYPE_APPLYROLLREQUEST = "applyRollRequestRR";

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
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYROLLREQUEST, handleApplyRollRequestRR);
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
	local _sDesc = "";

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
		end,
		["desc"] = function (param) _sDesc = param; end
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

	if #_tTargets==0 then
		_tTargets = RR.getSelectedChars();
	end
	RRRollManager.requestRoll(_sType, _sSubType, _tTargets, _bSecret, _nTargetDC, _sDesc);
end

---Handler for OOB_MSGTYPE_APPLYROLLREQUEST
---Receives the argument table from a client call to requestRoll and executes it on host
---@param msgOOB table 
function handleApplyRollRequestRR(msgOOB)
	local tArgTable = Utility.decodeJSON(msgOOB.tArgTable);
	local tDatabasePaths = {};
	for k,v in pairs(tArgTable.tActors) do
		table.insert(tDatabasePaths,DB.findNode(v) or nil);
	end
	-- encodeJSON does not work on database nodes, so we have to convert it back from the strings we transferred
	tArgTable.tActors = tDatabasePaths;

	RRRollManager.requestRoll(tArgTable.sRollType or "", tArgTable.sSubType or "", tArgTable.tActors or {}, tArgTable.bSecret or false, tArgTable.nTargetDC or nil, tArgTable.sDesc or "");
end

---Encodes a table of arguments from requestRoll so that the host can execute it and pass it to the correct client
---@param tArgTable any the table of arguments passed from requestRoll
function notifyApplyRollRequestRR(tArgTable)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYROLLREQUEST;
	local tStringPaths = {};
	for k,v in pairs(tArgTable.tActors) do
		table.insert(tStringPaths,DB.getPath(v));
	end
	-- encodeJSON does not work on database nodes, so we convert it to string paths before encoding
	tArgTable.tActors = tStringPaths;

	msgOOB.tArgTable = Utility.encodeJSON(tArgTable);
	Comm.deliverOOBMessage(msgOOB, "");
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

---Migrates the nodes to data structure v2.3 and then 2.17
function runMigration()
	-- 2.3
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

	-- 2.17
	migrateNode("requestsheet.check.list","requestsheet.rolls.check.list");
	migrateNode("requestsheet.save.list","requestsheet.rolls.save.list");
	migrateNode("requestsheet.skill.list","requestsheet.rolls.skill.list");
	migrateNode("requestsheet.dice.list","requestsheet.rolls.dice.list");

	migrateExpanderCheckbox("requestsheet.rolls.check.list");
	migrateExpanderCheckbox("requestsheet.rolls.save.list");
	migrateExpanderCheckbox("requestsheet.rolls.skill.list");
	migrateExpanderCheckbox("requestsheet.rolls.dice.list");
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

--- Migrate from the old system of using a single button to set showing the string in combobox and expanders
--- to using two individual checkboxes
--- @param listNode string the node with star selectors to be transformed e.g. requestsheet.rolls.check.list
function migrateExpanderCheckbox(listNode)
	for _,w in pairs(DB.getChildren(listNode)) do
		--a value of two meant that it would show up in teh expanders
		if DB.getValue(w,"show",0)== 2 then
			DB.setValue(w,"show_expander","number",1);
			DB.setValue(w,"show","number",1);
		end
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


