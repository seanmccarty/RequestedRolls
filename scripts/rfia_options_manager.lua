local rfiaManualSaveRollKeyPc = "RFIA_manual_save_rolls_pc";
local rfiaManualSaveRollKeyNpc = "RFIA_manual_save_rolls_npc";
local rfiaHideSidebarButtonKey = "RFIA_hide_sidebar_button";
local rfiaShowDcKey = "RFIA_ShowDC";
local rfiaDebugOn = "";

function onInit()
	registerOptions();
end

function registerOptions()

	OptionsManager.registerOption2(rfiaShowDcKey, false, "RFIA_option_header", "RFIA_show_dc_to_players", "option_entry_cycler", 
			{ labels = "RFIA_show_dc_on", values = "on", baselabel = "RFIA_show_dc_off", baseval = "off", default = "off" });
			
	OptionsManager.registerOption2(rfiaManualSaveRollKeyPc, false, "RFIA_option_header", "RFIA_manual_save_rolls_pc", "option_entry_cycler", 
			{ labels = "RFIA_manual_save_rolls_pc_on", values = "on", baselabel = "RFIA_manual_save_rolls_pc_off", baseval = "off", default = "off" });	
			
	OptionsManager.registerOption2(rfiaManualSaveRollKeyNpc, false, "RFIA_option_header", "RFIA_manual_save_rolls_npc", "option_entry_cycler", 
		{ labels = "RFIA_manual_save_rolls_npc_on", values = "on", baselabel = "RFIA_manual_save_rolls_npc_off", baseval = "off", default = "off" });	
		
	OptionsManager.registerOption2(rfiaHideSidebarButtonKey, true, "RFIA_option_header", "RFIA_hide_sidebar_button", "option_entry_cycler", 
		{ labels = "RFIA_hide_sidebar_button_on", values = "on", baselabel = "RFIA_hide_sidebar_button_off", baseval = "off", default = "off" });		
	
	OptionsManager.registerCallback(rfiaManualSaveRollKeyPc, onManualSaveRollOptionUpdate);
	OptionsManager.registerCallback(rfiaManualSaveRollKeyNpc, onManualSaveRollOptionUpdate);
	OptionsManager.registerCallback(rfiaHideSidebarButtonKey, onHideSideBarButtonOptionUpdate);	
	
	--Now that options have been registered we can 	updateSidebarShortcut();
	if User.isHost() and not isHideSideBarButtonOn() then
		RFIA.createSideBarShortcut();
	end
	
end

function onManualSaveRollOptionUpdate()
	if User.isHost() then
		RFIARequestManager.deleteAndCreateRequestsNode();
	end
end

function isHideSideBarButtonOn()
	return OptionsManager.isOption(rfiaHideSidebarButtonKey, "on");
end

function isManualSaveRollPcOn()
	return OptionsManager.isOption(rfiaManualSaveRollKeyPc, "on");
end

function isManualSaveRollNpcOn()
	return OptionsManager.isOption(rfiaManualSaveRollKeyNpc, "on");
end

function isShdowDcOn()
	return OptionsManager.isOption(rfiaShowDcKey, "on");
end
