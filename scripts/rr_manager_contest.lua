function onInit()
	if Session.IsHost then
		DB.createNode("requestsheet.contest");
		DB.setPublic("requestsheet.contest",true);
	end
end