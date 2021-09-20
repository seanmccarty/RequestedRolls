function onInit()

	Comm.registerSlashHandler("rfia", onSlashCommandRFIAHelp);
	Comm.registerSlashHandler("rfiarolls", onSlashCommandRFIARollsOpen);
	if Session.IsHost  then
		Comm.registerSlashHandler("rfiarequest ", onSlashCommandRFIARequestOpen);
	end
end

function onSlashCommandRFIAHelp(sCommand, sParams)
	ChatManager.SystemMessage(Interface.getString("message_slashcommands"));
	ChatManager.SystemMessage("----------------");
	ChatManager.SystemMessage("/rfia");
	ChatManager.SystemMessage("\t list of available rfia commands");		
	if Session.IsHost  then	
		ChatManager.SystemMessage("/rfiarequest");
		ChatManager.SystemMessage("\t DM only - open the create request window");
	end	
	ChatManager.SystemMessage("/rfiarolls");
	ChatManager.SystemMessage("\t open the rolls window");

end

function onSlashCommandRFIARollsOpen(sCommand, sParams)
	if Session.IsHost  then	
		RFIARequestManager.openRollRequestListForDm();
	else
		RFIARequestManager.openRollRequestListForUser(User.getUsername());
	end
end

function onSlashCommandRFIARequestOpen(sCommand, sParams)
	if Session.IsHost  then		
		RFIA.openCreateRequestWindow();
	end	
end
