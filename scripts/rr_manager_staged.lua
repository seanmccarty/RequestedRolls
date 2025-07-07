fOriginalResolveAction = nil;
local bStageArrayBuilt = false;

local stageArray = {};

function onInit()
	fOriginalResolveAction = ActionsManager.resolveAction;
	ActionsManager.resolveAction = resolveAction;
	DB.addHandler("requestsheet.staged","onChildUpdate",buildArray);
	if Session.IsHost then
		--All players need to be able to build stageArray from the database
		DB.createNode("requestsheet.staged");
		DB.setPublic("requestsheet.staged",true);
		DB.addHandler("requestsheet.staged","onChildAdded",addDefaultRolls);
	end
	buildArray();
end

-- Example what the array looks like
-- local stageArray = {
-- 	check = {{category="Feat", name="lucky"},{category="Feature",name="portent"}, {category="Trait",name="elven accuracy"},{category="Effect",name="Bardic Inspiration"}},
-- 	save = {{category="Feat", name="lucky"}},
-- 	skill = {}
-- };

---Build the array of rolls that should be staged. The format matches that of the example above.
function buildArray()
	stageArray = {};
	local nodes = DB.getChildren("requestsheet.staged");
	--mainNode is the feature, feat, etc... of what you are going to work on
	--name: the name of the feature
	--type: whether it is a feature, feat, etc...
	for index, mainNode in pairs(nodes) do
		local mainName = DB.getValue(mainNode, "name", "");
		local mainType = DB.getValue(mainNode, "type", "");
		local rollTypeNodes = DB.getChildren(mainNode,"rollTypes")
		--rollTypeNodes is the roll types such as attack, save, etc. that this roll may apply to
		--if the node "selected" is true, it adds the feature type to the stageArray
		for index, rollTypeNode in pairs(rollTypeNodes) do
			if DB.getValue(rollTypeNode, "selected",0) == 1 then
				local rollType = DB.getValue(rollTypeNode, "type", "error"):lower();
				--if this is the first of the this roll type (check, etc...) we need to initialize the entry first
				if not stageArray[rollType] then
					stageArray[rollType] = {};
				end
				table.insert(stageArray[rollType],{category=mainType,name=mainName});
			end
		end
	end
	if RR.bDebug then Debug.chat("stageArray",stageArray); end
end

---Replaces ActionsManager.resolveAction to allow staging
---@param rSource any
---@param rTarget any
---@param rRoll any
function resolveAction(rSource, rTarget, rRoll)
	if not bStageArrayBuilt then
		buildArray();
	end
	if RR.bDebug then Debug.chat("resolve",rSource, rTarget, rRoll); end
	local rApplicableIdentifier = shouldStage(rSource, rTarget, rRoll);
	if OptionsManager.isOption("RR_option_label_allowRollStaging","on") and #rApplicableIdentifier>0 then
		addStagedRoll(rSource, rTarget, rRoll, rApplicableIdentifier);
	else
		fOriginalResolveAction(rSource, rTarget, rRoll);
	end
end

---Checks if the roll should be sent to the stage dialog and returns the relevant features, etc...
---@param rSource any
---@param rTarget any
---@param rRoll any
---@return table results a table of the features, feats, etc... that this roll may apply to
function shouldStage(rSource, rTarget, rRoll)
	if rRoll and (tonumber(rRoll.nTarget) or 0) > 0 then
		--rRoll.nTarget = nil;
		--rRoll.sDesc = rRoll.sDesc .. "\n[Staged]"
	end
	local results = {};
	if rRoll and rRoll.sType and stageArray[rRoll.sType:lower()] then
		if RR.bDebug then Debug.chat("1",stageArray[rRoll.sType]); end
		for index, value in ipairs(stageArray[rRoll.sType:lower()]) do
			if value["category"] == "Feat" then
				if CharManager.hasFeat(ActorManager.getCreatureNode(rSource),value["name"]) then
					table.insert(results,value["name"]);
				end
			elseif value["category"] == "Feature" then
				if CharManager.hasFeature(ActorManager.getCreatureNode(rSource),value["name"]) then
					table.insert(results,value["name"]);
				end
			elseif value["category"] == "Trait" then
				if CharManager.hasTrait(ActorManager.getCreatureNode(rSource),value["name"]) then
					table.insert(results,value["name"]);
				end
			elseif value["category"] == "Effect" then
				--effects are special, using by type  allows is to find entries like Lucky:d20 where d20 is not 
				--  part of the search string. There cannot be spaces in the search string.
				local aEffectsByType = EffectManager.getEffectsByType(rSource, value["name"]);
				if #aEffectsByType>0 then
					table.insert(results,aEffectsByType[1].original);
				else
					if EffectManager.hasEffect(rSource,value["name"]) then
						table.insert(results,value["name"]);
					end
				end
			elseif value["category"] == "Ability" then
				if RRCoreRPG.hasAbility(ActorManager.getCreatureNode(rSource),value["name"]) then
					table.insert(results,value["name"]);
				end
			end
		end
	end
	return results;
end

---DB handler for when a new roll identifier is added (e.g. Portent, etc...)
---Currently 5E has a number of its own rolls that get added
---@param nodeParent any
---@param nodeChildAdded any
function addDefaultRolls(nodeParent, nodeChildAdded)
	local node = DB.createChild(nodeChildAdded,"rollTypes");
	local node5 = DB.createChild(node);
	DB.setValue(node5, "type","string","Attack");
	if Interface.getRuleset() == "5E" then
		local node2 = DB.createChild(node);
		DB.setValue(node2, "type","string","Check");
		local node3 = DB.createChild(node);
		DB.setValue(node3, "type","string","Save");
		local node4 = DB.createChild(node);
		DB.setValue(node4, "type","string","Skill");
	end
	local node7 = DB.createChild(node);
	DB.setValue(node7, "type","string","Damage");
	local node6 = DB.createChild(node);
	DB.setValue(node6, "type","string","Dice");
end

---Adds the roll to stage roll dialog and then posts a message saying what the roll number was
---@param rSource any
---@param vTargets any
---@param rRoll any
---@param rApplicableIdentifier any
function addStagedRoll(rSource, vTargets, rRoll,rApplicableIdentifier)
	--local wMain = Interface.openWindow("stagedrolls", "");
	--local wRoll = wMain.list.createWindow();
	--wRoll.setData(rRoll, rSource, vTargets,rApplicableIdentifier);

	local wMain = Interface.openWindow("manualrolls", "");
	local wRoll = wMain.list.createWindowWithClass("stagedroll_entry");
	wRoll.setData(rRoll, rSource, vTargets,rApplicableIdentifier);
	if RR.bDebug then Debug.chat("staged",rRoll); end

	local rRollTemp = UtilityManager.copyDeep(rRoll);
	rRollTemp.sDesc = "[STAGING]\n" .. rRollTemp.sDesc
	if Interface.getRuleset()=="5E" then
		ActionsManager2.decodeAdvantage(rRollTemp);
	end
	local rMessage = ActionsManager.createActionMessage(rSource, rRollTemp);
	Comm.deliverChatMessage(rMessage);
end