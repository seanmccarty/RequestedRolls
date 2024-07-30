function onInit()
	DB.addHandler("combattracker.actiondata.dc", "onUpdate", copyDC);
	RRRollManager.registerRollGetter("init", getInitRoll);
end

function copyDC()
	if OptionsManager.getOption("RR_option_label_copyDCPanel") == "on" then
		local val = DB.getValue("combattracker.actiondata.dc")
		DB.setValue("requestsheet.check.dc","number", val)
		DB.setValue("requestsheet.save.dc","number", val)
		DB.setValue("requestsheet.skill.dc","number", val)
	end
end

function getInitRoll(rActor, sSkill)
	if rActor.sSkillname and rActor.sSkillname ~= "" then
		rActor.sSkillname = sSkill;
	end
	return ActionInit.getRoll(rActor, false);
end