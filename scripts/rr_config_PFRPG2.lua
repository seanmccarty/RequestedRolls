function onInit()
	DB.addHandler("combattracker.actiondata.dc", "onUpdate", copyDC);
	RRRollManager.registerRollGetter("init", getInitRoll);

	if Session.IsHost then
		OptionsManager.registerOptionData({sKey = "RR_option_label_copyDCPanel", bLocal = true, sGroupRes = "RR_option_header", sLabelRes = "RR_option_label_copyDCPanel"});
	end
end

function copyDC()
	if OptionsManager.getOption("RR_option_label_copyDCPanel") == "on" then
		local val = DB.getValue("combattracker.actiondata.dc")
		DB.setValue("requestsheet.rolls.check.dc","number", val)
		DB.setValue("requestsheet.rolls.save.dc","number", val)
		DB.setValue("requestsheet.rolls.skill.dc","number", val)
	end
end

function getInitRoll(rActor, sSkill)
	if rActor.sSkillname and rActor.sSkillname ~= "" then
		rActor.sSkillname = sSkill;
	end
	return ActionInit.getRoll(rActor, false);
end