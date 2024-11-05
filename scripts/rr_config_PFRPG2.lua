function onInit()
	DB.addHandler("combattracker.actiondata.dc", "onUpdate", copyDC);
	RRRollManager.registerRollGetter("init", getInitRoll);

	OptionsManager.registerOption2("RR_option_label_copyDCPanel", true, "RR_option_header", "RR_option_label_copyDCPanel", "option_entry_cycler", 
	{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
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