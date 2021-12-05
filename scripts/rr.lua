local buttonUpImage = "RFIA_DefaultButtonUp";
local buttonDownImage = "RFIA_DefaultButtonDown";
local dbRootName = "requestsheet";
local createRequestWindowName = "RequestRolls";

bDebug = false;

function onInit()
	if Session.IsHost then DB.createNode(dbRootName); end
	updateButtons();
    registerOptions();
	registerSlashHandlers();
    
    registerExtensions();

end

function registerOptions()

	OptionsManager.registerOption2("RR_option_label_showDC", false, "RR_option_header", "RR_option_label_showDC", "option_entry_cycler", 
			{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" });
			
	OptionsManager.registerOption2("RR_option_label_pcRolls", true, "RR_option_header", "RR_option_label_pcRolls", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
			
	OptionsManager.registerOption2("RR_option_label_npcRolls", false, "RR_option_header", "RR_option_label_npcRolls", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
	
	
	--the button to show/hide the shortcut is only shown for the GM
	if Session.IsHost then
		OptionsManager.registerOption2("RR_option_label_sidebar", true, "RR_option_header", "RR_option_label_sidebar", "option_entry_cycler", 
			{ labels = "RR_option_val_hide", values = "hide", baselabel = "RR_option_val_show", baseval = "show", default = "show" });	
		
		--Now that options have been registered we can 	add the shortcut
		if 	OptionsManager.isOption("RR_option_label_sidebar", "show") then
			table.insert(Desktop.aCoreDesktopStack["host"],{icon=buttonUpImage, icon_down=buttonDownImage, tooltipres="RFIA_window_title", class=createRequestWindowName, path=dbRootName});
		end
	end
end

function updateButtons()
	-- if the ruleset is not 5E or it is one of the two other themes listed, change to the core sidebar buttons
	if User.getRulesetName()~="5E" or isThemeEnabled("Colored Sidebar") or isThemeEnabled("Core Sidebar for 5e") then
		buttonUpImage = "RFIA_CoreSidebarButtonUp";
		buttonDownImage = "RFIA_CoreSidebarButtonDown";	
	elseif isThemeEnabled("5E Theme - Wizards") then
		buttonUpImage = "RFIA_5EThemeSidebarButtonUp";
		buttonDownImage = "RFIA_5EThemeSidebarButtonDown";			
    end
        

end

-- Extensions
function registerExtensions()
	if RR.bDebug then debugExtensions(); end
	bCharacterSheetTweaksEnabled = isThemeEnabled("Mad Nomad's Character Sheet Tweaks");
end


function listExtensions()
    for _, extension in ipairs(Extension.getExtensions()) do
    	Debug.console("listExtension", Extension.getExtensionInfo(extension).name);
    end
end

function isThemeEnabled(themeName)
    for _, extension in ipairs(Extension.getExtensions()) do
    	if Extension.getExtensionInfo(extension).name == themeName then
			return true;
		end
    end
	return false;
end

-- options
function isManualSaveRollPcOn()
	return OptionsManager.isOption("RR_option_label_pcRolls", "on");
end

function isManualSaveRollNpcOn()
	return OptionsManager.isOption("RR_option_label_npcRolls", "on");
end

function isShowDCOn()
	return OptionsManager.isOption("RR_option_label_npcRolls", "on");
end

-- slash manager
function registerSlashHandlers()
	Comm.registerSlashHandler("RR", processRRCommandList);
	Comm.registerSlashHandler("RRrolls", processRRRolls);
	if Session.IsHost  then
		Comm.registerSlashHandler("RRconsole", processRRConsole);
	end
	Comm.registerSlashHandler("RRdebug",processRRdebug);
end

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

function processRRRolls(sCommand, sParams)
	Interface.openWindow("manualrolls", "");
end

function processRRConsole(sCommand, sParams)
	if Session.IsHost  then		
		Interface.openWindow(createRequestWindowName, dbRootName);
	end	
end

--Changes debug if on/off parameter is not passed
--lists current extensions to the log
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