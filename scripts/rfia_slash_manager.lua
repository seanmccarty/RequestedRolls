function onInit()

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
	if Session.IsHost  then	
		RFIARequestManager.openRollRequestListForDm();
	else
		RFIARequestManager.openRollRequestListForUser(User.getUsername());
	end
end

function processRRConsole(sCommand, sParams)
	if Session.IsHost  then		
		RFIA.openCreateRequestWindow();
	end	
end

--Changes debug if on/off parameter is not passed
--lists current extensions to the log
function processRRdebug(sCommand, sParams)
	sParams = StringManager.trim(sParams);
	if sParams == "off" then
		RFIA.bDebug = false;
	else
		if sParams == "on" then
			RFIA.bDebug = true;
		else
			RFIA.bDebug = not RFIA.bDebug;
		end
	end
	ChatManager.SystemMessage("RR debug mode is ".. tostring(RFIA.bDebug));
	if RFIA.bDebug then
		RFIAExtensionManager.listExtensions();
	end
end