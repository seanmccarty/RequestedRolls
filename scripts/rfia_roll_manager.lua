function skillList()	
	if User.getRulesetName()=="PFRPG" then
		addSkillItem("Acrobatics", 		"Skill", 		"Acrobatics Check",				performSkillRoll,	"Acrobatics");
		addSkillItem("Appraise", 		"Skill", 		"Appraise Check",				performSkillRoll,	"Appraise");
		addSkillItem("Bluff", 			"Skill", 		"Bluff Check",					performSkillRoll,	"Bluff");
		addSkillItem("Climb", 			"Skill", 		"Climb Check",					performSkillRoll,	"Climb");
		addSkillItem("Craft", 			"Skill", 		"Craft Check",					performSkillRoll,	"Craft");
		addSkillItem("Diplomacy", 		"Skill", 		"Diplomacy Check",				performSkillRoll,	"Diplomacy");
		addSkillItem("Disable Device", 	"Skill", 		"Disable Device Check",			performSkillRoll,	"Disable Device");
		addSkillItem("Disguise", 		"Skill", 		"Disguise Check",				performSkillRoll,	"Disguise");
		addSkillItem("Escape Artist",	"Skill", 		"Escape Artist Check",			performSkillRoll,	"Escape Artist");
		addSkillItem("Fly", 			"Skill", 		"Fly Check",					performSkillRoll,	"Fly");
		addSkillItem("Handle Animal", 	"Skill", 		"Handle Animal Check",			performSkillRoll,	"Handle Animal");
		addSkillItem("Heal", 			"Skill", 		"Heal Check",					performSkillRoll,	"Heal");
		addSkillItem("Intimidate", 		"Skill", 		"Intimidate Check",				performSkillRoll,	"Intimidate");
		addSkillItem("Knowledge", 		"Skill", 		"Knowledge Check",				performSkillRoll,	"Knowledge");
		addSkillItem("Linguistics", 	"Skill", 		"Linguistics Check",			performSkillRoll,	"Linguistics");
		addSkillItem("Perception", 		"Skill", 		"Perception Check",				performSkillRoll,	"Perception");
		addSkillItem("Perform", 		"Skill", 		"Perform Check",				performSkillRoll,	"Perform");
		addSkillItem("Profession", 		"Skill", 		"Profession Check",				performSkillRoll,	"Profession");
		addSkillItem("Ride", 			"Skill", 		"Ride Check",					performSkillRoll,	"Ride");
		addSkillItem("Sense Motive", 	"Skill", 		"Sense Motive Check",			performSkillRoll,	"Sense Motive");
		addSkillItem("Sleight of Hand", "Skill", 		"Sleight of Hand Check",		performSkillRoll,	"Sleight of Hand");
		addSkillItem("Spellcraft", 		"Skill", 		"Spellcraft Check",				performSkillRoll,	"Spellcraft");
		addSkillItem("Stealth", 		"Skill", 		"Stealth Check",				performSkillRoll,	"Stealth");
		addSkillItem("Survival", 		"Skill", 		"Survival Check",				performSkillRoll,	"Survival");
		addSkillItem("Swim", 			"Skill", 		"Swim Check",					performSkillRoll,	"Swim");
		addSkillItem("Use Magic Device","Skill", 		"Use Magic Device Check",		performSkillRoll,	"Use Magic Device");
	end
	
	if User.getRulesetName()=="5E" then
		addExtraItem("Death", 			"Death", 		"Death Saving Throw",			performDeathSaveRoll);
	end
end




 ------------- Functionality -----------


function performInitRoll(request)
	local rRoll = ActionInit.getRoll(request:getActor(), nil);
	rRoll.bSecret = request:isHidden();
	rRoll.bTower = request:isHidden();	
	ActionsManager.performAction(nil, request:getActor(), rRoll);
end

function performCheckRoll( request )
	local rRoll;
	if User.getRulesetName()=="5E" then
		rRoll = ActionCheck.getRoll(request:getActor(), string.lower(request:getRollName()));
	else
		rRoll = ActionAbility.getRoll(request:getActor(),string.lower(request:getRollName()));
	end
	rRoll.bSecret = request:isHidden();
	rRoll.bTower = request:isHidden();
	rRoll.nTarget = request:getDC();
	ActionsManager.performAction(nil, request:getActor(), rRoll);
end

function performSaveRoll( request )
	local rRoll = ActionSave.getRoll(request:getActor(), string.lower(request:getRollName()));
	
	rRoll.bRFIARequestRoll = true;
	if request:getDC() ~= nil then
		rRoll.nTarget = request:getDC();
	end
	
	if request:isHidden() then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(nil, request:getActor(), rRoll);
end


function performSkillRoll( request )

	if request:isPc() then
		performSkillRollForPc(request);
	else
		performSkillRollForNpc(request);
	end

end

function performSkillRollForPc(request)
	
	local charSkillList = request:getIdentity()..".skilllist";
	local rollName = request:getRollName();	
	local itemSkillName;
	for k,node in pairs(DB.getChildren(charSkillList)) do
		if User.getRulesetName()=="5E" then
			itemSkillName = DB.getValue(node,"name","");
		else
			itemSkillName = DB.getValue(node,"label","");
		end
		if itemSkillName == rollName then
			local rRoll
			if User.getRulesetName()=="5E" then
				rRoll = ActionSkill.getRoll(request:getActor(), node);
			else
				local nSkillMod = DB.getValue(node, "total", 0);
				local sSkillStat = DB.getValue(node, "statname", "");
				rRoll = ActionSkill.getRoll(request:getActor(), itemSkillName, nSkillMod, sSkillStat);
			end
			rRoll.bSecret = request:isHidden();
			rRoll.bTower = request:isHidden();
			rRoll.nTarget = request:getDC();
			ActionsManager.performAction(nil, request:getActor(), rRoll);
			return;
		end
	end	
	
	ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] ( Unable to find PC skill '" ..  rollName  .. "' " .. "on PC, please check character sheet)");
end

function performSkillRollForNpc(request)
	
	local ctNode = RFIAEntriesManager.getEntryById(request:getCtIdentity());
	local rollName = request:getRollName();	
	local rActor = ActorManager.resolveActor(ctNode);
	
	local npcSkillList = ctNode.getChild(RFIAEntriesManager.getRfiaNpcSkillsPath());
	if npcSkillList ~= nil then		
		
		for k,node in pairs(npcSkillList.getChildren()) do
			local itemSkillName = DB.getValue(node,"name","");
			if string.lower(itemSkillName) ==  string.lower(rollName) then
				local nMod = DB.getValue(node,"mod", "number", 0);
				if User.getRulesetName()=="5E" then
					ActionSkill.performNPCRoll(nil, rActor, itemSkillName, nMod);
				else
					ActionSkill.performRoll(nil, rActor, itemSkillName, nMod);
				end
				return;
			end
		end	
	end
	--If we didnt find it in the npcProfSkills list then we will use their ability score 
	if DataCommon.skilldata[rollName] then
		local stat = DataCommon.skilldata[rollName].stat;
		if User.getRulesetName()=="5E" then
			local npcAbilitiesList = ctNode.getChild("abilities");
			for k,node in pairs(npcAbilitiesList.getChildren()) do
				local abilityName = node.getName();
				if abilityName ==  stat then
					local nMod = DB.getValue(node,"bonus", "number", 0);
					ActionSkill.performNPCRoll(nil, rActor, rollName, nMod);
					return;
				end
			end
		else
			local nMod = ActorManager35E.getAbilityBonus(rActor, stat);
			ActionSkill.performRoll(nil, rActor, rollName, nMod);
		end
		return;
	end
		
	-- Have not found the skill at all. 
	ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] ( Unable to find NPC skill '" ..  rollName  .. "' " .. "on NPC or from default list)");
end

function performDeathSaveRoll( request )
	local rRoll = { };
	rRoll.bRFIARequestRoll = true;
	rRoll.sType = "death";
	rRoll.aDice = { "d20" };
	rRoll.nMod = 0;	
	rRoll.sDesc = "[DEATH]";
	rRoll.bSecret = request:isHidden();
	rRoll.bTower = request:isHidden();
	
	ActionsManager.performAction(nil, request:getActor(), rRoll);
end

function performRawRoll( request )
	local rRoll = {};
	rRoll.sType = "dice";	
	
	if request:getRollName() == "d100" and not UtilityManager.isClientFGU() then
		rRoll.aDice = { "d10", "d100" };
	else
		rRoll.aDice = { request:getRollName() };
	end
	
	rRoll.nMod = 0;
	rRoll.nTarget = request:getDC();
	rRoll.sDesc = "[RAW DICE] "..request:getRollName();
	rRoll.bSecret = request:isHidden();
	rRoll.bTower = request:isHidden();
		
	ActionsManager.performAction(nil, request:getActor(), rRoll);
end
