local rfiaManualSaveRollKeyPc = "RR_option_label_pcRolls";
local rfiaManualSaveRollKeyNpc = "RR_option_label_npcRolls";
local rfiaHideSidebarButtonKey = "RR_option_label_sidebar";
local rfiaShowDcKey = "RR_option_label_showDC";

function onInit()
	registerOptions();
end

function registerOptions()

	OptionsManager.registerOption2(rfiaShowDcKey, false, "RR_option_header", "RR_option_label_showDC", "option_entry_cycler", 
			{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" });
			
	OptionsManager.registerOption2(rfiaManualSaveRollKeyPc, true, "RR_option_header", "RR_option_label_pcRolls", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
			
	OptionsManager.registerOption2(rfiaManualSaveRollKeyNpc, false, "RR_option_header", "RR_option_label_npcRolls", "option_entry_cycler", 
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });	
		
	OptionsManager.registerCallback(rfiaManualSaveRollKeyPc, onManualSaveRollOptionUpdate);
	OptionsManager.registerCallback(rfiaManualSaveRollKeyNpc, onManualSaveRollOptionUpdate);
	
	--the button to show/hide the shortcut is only shown for the GM
	if Session.IsHost then
		OptionsManager.registerOption2(rfiaHideSidebarButtonKey, true, "RR_option_header", "RR_option_label_sidebar", "option_entry_cycler", 
			{ labels = "RR_option_val_hide", values = "hide", baselabel = "RR_option_val_show", baseval = "show", default = "show" });	
		
		--Now that options have been registered we can 	add the shortcut
		if 	OptionsManager.isOption(rfiaHideSidebarButtonKey, "show") then
			RFIA.createSideBarShortcut();
		end
	end
end

function onManualSaveRollOptionUpdate()
	if Session.IsHost then
		RFIARequestManager.deleteAndCreateRequestsNode();
	end
end

function isManualSaveRollPcOn()
	return OptionsManager.isOption(rfiaManualSaveRollKeyPc, "on");
end

function isManualSaveRollNpcOn()
	return OptionsManager.isOption(rfiaManualSaveRollKeyNpc, "on");
end

function isShowDCOn()
	return OptionsManager.isOption(rfiaShowDcKey, "on");
end
