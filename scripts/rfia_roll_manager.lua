--[[
Handles the rolls list and the rolls.

-- 0.11 we dont need the onRollDone method anymore as this functionality is handled by listeners. Keeping it in code for now in case of reverting back
]]

local ROLLS = "rolls"
local all_rolls = {};
local idCount = 0;
local abilitiesCount = 0;
local savesCount = 0;
local savesOverrideCount = 0;
local skillsCount = 0;
local extrasCount = 0;
local diceCount = 0;

local OOB_MSGTYPE_RFI_ROLL_DONE = "rfi_rolldone";
local OOB_MSGTYPE_RFI_HIDE_ROLL = "rfi_hide_roll";

local ABILITIES = "abilities";
local ABILITY_CATEGORY = "Ability";

local SAVES = "saves";
local SAVE_CATEGORY = "Save";

local SAVEOVERRIDES = "saveoverrides";
local SAVEOVERRIDE_CATEGORY = "SaveOverride";

local SKILLS = "skills";
local SKILL_CATEGORY = "Skill";

local EXTRAS = "extras";
local EXTRA_CATEGORY = "Extra";

local DICE = "dice";
local DIE_CATEGORY = "Die";

function onInit()
	
	-- OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RFI_ROLL_DONE, onRollDone);
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RFI_HIDE_ROLL, performHiddenRoll);
	end
	
	createRootNodes();
	populateDB();
end


 ------------- Database Setup -----------

function createRootNodes()
	if Session.IsHost then
		rollList = getOrCreateRootNode();
		rollList.delete();
		getOrCreateRootNode();
		createChildren();
	end
end

function getOrCreateRootNode()
	return DB.createChild("RFIA_Root", ROLLS);
end

function createChildren()
	local rollsNode = getRollsNode();
	DB.createChild(rollsNode, ABILITIES);
	DB.createChild(rollsNode, SAVES);
	DB.createChild(rollsNode, SAVEOVERRIDES);
	DB.createChild(rollsNode, SKILLS);
	DB.createChild(rollsNode, EXTRAS);
	DB.createChild(rollsNode, DICE);
end

function getRollsNode()
	return DB.getChild("RFIA_Root", ROLLS);
end

function getRollsChildren()
	return DB.getChildren("RFIA_Root." .. ROLLS);
end

function getAbilitiesNode()
	return DB.getChild("RFIA_Root." .. ROLLS, ABILITIES);
end

function getSavesNode()
	return DB.getChild("RFIA_Root." .. ROLLS, SAVES);
end

function getSaveoverridesNode()
	return DB.getChild("RFIA_Root." .. ROLLS , SAVEOVERRIDES);
end

function getSkillsNode()
	return DB.getChild("RFIA_Root." .. ROLLS, SKILLS);
end

function getExtrasNode()
	return DB.getChild("RFIA_Root." .. ROLLS, EXTRAS);
end

function getDiceNode()
	return DB.getChild("RFIA_Root." .. ROLLS, DICE);
end


function getRollsChildren()
	return DB.getChildren("RFIA_Root." .. ROLLS);
end




function addAbilityItem(name, rolltype, rolldescription, rollfunction, realname)
	addItem(name, ABILITY_CATEGORY, getAbilitiesNode(), abilitiesCount, rolltype, rolldescription, rollfunction, realname);
end

function addSaveItem(name, rolltype, rolldescription, rollfunction, realname)
	addItem(name, SAVE_CATEGORY, getSavesNode(), savesCount, rolltype, rolldescription, rollfunction, realname);
end

function addSaveOverrideItem(name, rolltype, rolldescription, rollfunction, realname)
	addItem(name, SAVEOVERRIDE_CATEGORY, getSaveoverridesNode(), savesOverrideCount, rolltype, rolldescription, rollfunction, realname);
end

function addSkillItem(name, rolltype, rolldescription, rollfunction, realname)
	addItem(name, SKILL_CATEGORY, getSkillsNode(), skillsCount, rolltype, rolldescription, rollfunction, realname);
end

function addExtraItem(name, rolltype, rolldescription, rollfunction, realname)
	addItem(name, EXTRA_CATEGORY, getExtrasNode(), extrasCount, rolltype, rolldescription, rollfunction, realname);
end

function addDieItem(name, rolltype, rolldescription, rollfunction, realname)
	addItem(name, DIE_CATEGORY, getDiceNode(), diceCount, rolltype, rolldescription, rollfunction, realname);
end

function addItem(name, category, parentNode, count, rolltype, rolldescription, rollfunction, realname)
		item = {};
		item.name = name;
		if realname == nil then
			item.realname = name;
		else
			item.realname = realname;
		end
		item.category = category;
		item.type = rolltype;
		item.description = rolldescription;
		item.rollfunction = rollfunction;
		abilitiesCount = abilitiesCount + 1;
		item.id = abilitiesCount;

		if Session.IsHost then
			node = parentNode.createChild();
			roll = RFIWrapper.wrapRoll(node);
			roll:setName(item.name);
			roll:setRealName(item.realname);
			roll:setCategory(item.category);
			roll:setType(item.type);
			roll:setDescription(item.description);
			roll:setSelected(0);
			roll:setId(item.id);
			item.node = node;			
		end
		
		table.insert(all_rolls, item);	
end

--NOTE modified COS to CON
function populateDB()
	addAbilityItem("STR", 			"Ability",	"Strength Check", 				performCheckRoll, "Strength"	);
	addAbilityItem("DEX", 			"Ability",	"Dexterity Check", 				performCheckRoll, "Dexterity" 	);
	addAbilityItem("CON", 			"Ability",	"Constitution Check",			performCheckRoll, "Constitution" );
	addAbilityItem("INT", 			"Ability",	"Intelligence Check",			performCheckRoll, "Intelligence" );
	addAbilityItem("WIS", 			"Ability",	"Wisdom Check",					performCheckRoll, "Wisdom" 		);
	addAbilityItem("CHA", 			"Ability",	"Charisma Check",				performCheckRoll, "Charisma" 	);
    
	if User.getRulesetName()=="5E" then
		addSaveItem("STR", 				"Save", 		"Strength Saving Throw",		performSaveRoll , "Strength" 	);
		addSaveItem("DEX", 				"Save", 		"Dexterity Saving Throw",		performSaveRoll , "Dexterity" 	);
		addSaveItem("CON", 				"Save", 		"Constitution Saving Throw",	performSaveRoll , "Constitution" );
		addSaveItem("INT", 				"Save", 		"Intelligence Saving Throw",	performSaveRoll , "Intelligence" );
		addSaveItem("WIS", 				"Save", 		"Wisdom Saving Throw",			performSaveRoll , "Wisdom" 		);
		addSaveItem("CHA", 				"Save", 		"Charisma Saving Throw",		performSaveRoll , "Charisma" 	);
	elseif User.getRulesetName()=="PFRPG" then
		addSaveItem("FORT", 			"Save", 		"Fortitude Saving Throw",		performSaveRoll , "Fortitude" 	);
		addSaveItem("REF", 				"Save", 		"Reflex Saving Throw",			performSaveRoll , "Reflex" 	);
		addSaveItem("WILL", 			"Save", 		"Will Saving Throw",			performSaveRoll , "Will" );
	end

	addSaveOverrideItem("SAV", 		"SaveOverride", 		"SaveOverride",		performSaveOverrideRoll , "SaveOverride" );
	
	if User.getRulesetName()=="5E" then
		addSkillItem("Acrobatics", 		"Skill", 		"Acrobatics Check",				performSkillRoll);
		addSkillItem("Animal Handling", "Skill", 		"Animal Handling Check",		performSkillRoll);
		addSkillItem("Arcana", 			"Skill", 		"Arcana Check",					performSkillRoll);
		addSkillItem("Athletics", 		"Skill", 		"Athletics Check",				performSkillRoll);
		addSkillItem("Deception", 		"Skill", 		"Deception Check",				performSkillRoll);
		addSkillItem("History", 		"Skill", 		"History Check",				performSkillRoll);
		addSkillItem("Insight", 		"Skill", 		"Insight Check",				performSkillRoll);
		addSkillItem("Intimidation",	"Skill", 		"Intimidation Check",			performSkillRoll);
		addSkillItem("Investigation",	"Skill", 		"Investigation Check",			performSkillRoll);
		addSkillItem("Medicine", 		"Skill", 		"Medicine Check",				performSkillRoll);
		addSkillItem("Nature", 			"Skill", 		"Nature Check",					performSkillRoll);
		addSkillItem("Perception", 		"Skill", 		"Perception Check",				performSkillRoll);
		addSkillItem("Performance", 	"Skill", 		"Performance Check",			performSkillRoll);
		addSkillItem("Persuasion", 		"Skill", 		"Persuasion Check",				performSkillRoll);
		addSkillItem("Religion", 		"Skill", 		"Religion Check",				performSkillRoll);
		addSkillItem("Sleight of Hand",	"Skill", 		"Sleight of Hand Check",		performSkillRoll);
		addSkillItem("Stealth", 		"Skill", 		"Stealth Check",				performSkillRoll);
		addSkillItem("Survival", 		"Skill", 		"Survival Check",				performSkillRoll);
		if RFIAExtensionManager.bCharacterSheetTweaksEnabled then
			addSkillItem("Tools/Items: Artisans Tools", "Skill", "Artisans Tools",			performSkillRoll); 
			addSkillItem("Tools/Items: Gaming Set", "Skill", "Gaming Set", 					performSkillRoll); 
			addSkillItem("Tools/Items: Instrument", "Skill", "Instrument", 					performSkillRoll); 
			addSkillItem("Tools/Items: Thieves Tools", "Skill", "Thieves Tools", 			performSkillRoll);
		end
	elseif User.getRulesetName()=="PFRPG" then
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
	
	addExtraItem("INIT", 			"Initiative", 	"Roll for Initiative",			performInitRoll,	"Initiative");
	if User.getRulesetName()=="5E" then
		addExtraItem("Death", 			"Death", 		"Death Saving Throw",			performDeathSaveRoll);
	end
	
	addDieItem("d4", 				"Dice", 		"Roll a d4",					performRawRoll);
	addDieItem("d6", 				"Dice", 		"Roll a d6",					performRawRoll);
	addDieItem("d8", 				"Dice", 		"Roll a d8",					performRawRoll);
	addDieItem("d10", 				"Dice", 		"Roll a d10",					performRawRoll);
	addDieItem("d12", 				"Dice", 		"Roll a d12",					performRawRoll);
	addDieItem("d20", 				"Dice", 		"Roll a d20",					performRawRoll);
	addDieItem("d100", 				"Dice", 		"Roll a d100",					performRawRoll);
end




 ------------- Functionality -----------

function selectRoll(roll)
	resetSelectedRoll();
	
	if roll == nil then
		return;
	end
	
	roll:setSelected(1);
end

function resetSelectedRoll()
    for _,node in pairs(getRollsChildren()) do
		for _,childNode in pairs (node.getChildren()) do 
			roll = RFIWrapper.wrapRoll(childNode);
			roll:resetSelection();
		end
	end
end

function getSelectedRoll()
    for _,node in pairs(getRollsChildren()) do
		for _,childNode in pairs (node.getChildren()) do 
			roll = RFIWrapper.wrapRoll(childNode);
			local isSelected = roll:isSelected();
			if isSelected == 1 then
				return roll;
			end
		end
	end
	
	return RFIWrapper.wrapRoll();
end

function getRollInfoById(rollid)
	if type(rollid) == "string" then
		rollid = tonumber(rollid);
	end

	for i=1,table.getn(all_rolls) do
		itemRoll = all_rolls[i];
		if itemRoll.id == rollid then
			return itemRoll;
		end
	end
	
	return {};
end

function getSaveOverrideRoll()
		for i=1,table.getn(all_rolls) do
		itemRoll = all_rolls[i];
		if itemRoll.name == "SAV" then
			return itemRoll;
		end
	end
end

function performHiddenRoll(msgOOB)
	requestNode = DB.getChild(msgOOB.requestDataPath, msgOOB.requestDataName);
	request = RFIWrapper.wrapRequest(requestNode);
	performRoll(request);
end

function addTowerMessage(request)
	local msg = {font = "chatfont", icon = "dicetower_icon", text = ""};
	msg.sender = ActorManager.getDisplayName(request:getActor());
	msg.text = request:getDescription();
	Comm.addChatMessage(msg);
end

function sendHiddenRollRequestToHost(request)
	msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_RFI_HIDE_ROLL;
	msgOOB.requestDataPath = request.node.getParent().getPath();
	msgOOB.requestDataName = request.node.getName();
	Comm.deliverOOBMessage(msgOOB, "");
end

function performRoll(request)
	if request:isHidden() and Session.IsHost == false then
		addTowerMessage(request);
		sendHiddenRollRequestToHost(request);
	else
		local rollId = request:getRollId();
		for i=1,table.getn(all_rolls) do
			itemRoll = all_rolls[i];
			if itemRoll.id == rollId then
				if itemRoll.category ~= "SaveOverride" then
					applyModifiers(request);
				end
				itemRoll.rollfunction(request);
				-- notifyRollDone(request:getCtIdentity());
			end
		end
	end
end

function applyModifiers(request)
	if User.getRulesetName()=="5E" then
		tryToApplyModifier(request, "ADV");
		tryToApplyModifier(request, "DIS");
	end
	tryToApplyModifier(request, "PLUS2");
	tryToApplyModifier(request, "PLUS5");
	tryToApplyModifier(request, "MINUS2");
	tryToApplyModifier(request, "MINUS5");
	
	modValue = tonumber(request:getModifier("ModValue"));
	if modValue ~= 0 then
		ModifierStack.addSlot("", modValue);
	end
end

function tryToApplyModifier(request, name)
	if request:getModifier(name) ~= "" then
		ModifierStack.setModifierKey(name, true);
	end
end

-- function notifyRollDone(username)
	-- local msgOOB = {};
	-- msgOOB.type = OOB_MSGTYPE_RFI_ROLL_DONE;
	-- msgOOB.username = username;
	-- Comm.deliverOOBMessage(msgOOB);
-- end

-- function onRollDone(msgOOB)
	-- if Session.IsHost then
		-- Debug.console("Hello from onRollDone msgOOB", msgOOB);
		-- entryNode = RFIAEntriesManager.getEntryById(msgOOB.username);
		-- RFIAEntriesManager.setRollStateDone(entryNode);
	-- end
-- end

function performInitRoll(request)
	local rRoll = ActionInit.getRoll(request:getActor(), nil);
	rRoll.bSecret = request:isHidden();
	rRoll.bTower = request:isHidden();	
	ActionsManager.performAction(nil, request:getActor(), rRoll);
end

function performCheckRoll( request )
	local rRoll = ActionAbility.getRoll(request:getActor(),string.lower(request:getRollName()));
	if User.getRulesetName()=="5E" then
		rRoll = ActionCheck.getRoll(request:getActor(), string.lower(request:getRollName()));
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

function performSaveOverrideRoll( request)
	ActionsManager.performAction(nil, request:getActor(), request:getRollOverrideData());
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
	local rActor = ActorManager.getActorFromCT(ctNode);
	
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


function getRollNode(name, category)
	for _,roll in pairs(all_rolls) do
		if roll.name:lower() == name:lower() or roll.realname:lower() == name:lower() then
			if category ~= nil then
				if roll.category:lower() == category:lower() then
					return roll.node;
				end
			else
				return roll.node;
			end
		end
	end
	
	return nil;
end