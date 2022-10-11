fORA = nil;

-- local stageArray = {
-- 	check = {{category="Feat", name="lucky"},{category="Feature",name="portent"}, {category="Trait",name="elven accuracy"},{category="Effect",name="Bardic Inspiration"}},
-- 	save = {{category="Feat", name="lucky"}},
-- 	skill = {}
-- };

local stageArray = {};
function buildArray()
	stageArray = {};
	local nodes = DB.getChildren("requestsheet.staged");
	for index, mainNode in pairs(nodes) do
		local mainName = DB.getValue(mainNode, "name", "");
		local mainType = DB.getValue(mainNode, "type", "");
		local rollTypeNodes = DB.getChildren(mainNode,"rollTypes")
		for index, rollTypeNode in pairs(rollTypeNodes) do
			if DB.getValue(rollTypeNode, "selected",0) == 1 then
				local rollType = DB.getValue(rollTypeNode, "type", "error"):lower();
				if not stageArray[rollType] then
					stageArray[rollType] = {};
				end
				table.insert(stageArray[rollType],{category=mainType,name=mainName});
			end
		end
	end
	if RR.bDebug then Debug.chat("stageArray",stageArray); end
end

function onInit()
	fORA = ActionsManager.resolveAction;
	ActionsManager.resolveAction = resolveAction;
	if Session.IsHost then
		DB.addHandler("requestsheet.staged","onChildUpdate",buildArray);
		DB.addHandler("requestsheet.staged","onChildAdded",addDefaultRolls)
	end
	buildArray();
end

function resolveAction(rSource, rTarget, rRoll)
	if RR.bDebug then Debug.chat("resolve",rSource, rTarget, rRoll); end
	if OptionsManager.isOption("RR_option_label_allowRollStaging","on") and shouldStage(rSource, rTarget, rRoll) then
		addStagedRoll(rSource, rTarget, rRoll);
	else
		fORA(rSource, rTarget, rRoll);
	end
	--fORA(rSource, rTarget, rRoll);


	-- local fResult = aResultHandlers[rRoll.sType];

	-- if fResult then
	-- 	fResult(rSource, rTarget, rRoll);
	-- else
	-- 	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	-- 	Comm.deliverChatMessage(rMessage);
	-- end

	--Debug.chat(GameSystem.actions);
end

function shouldStage(rSource, rTarget, rRoll)
	if rRoll and (tonumber(rRoll.nTarget) or 0) > 0 then
		--rRoll.nTarget = nil;
		--rRoll.sDesc = rRoll.sDesc .. "\n[Staged]"
	end

	if rRoll and rRoll.sType and stageArray[rRoll.sType:lower()] then
		if RR.bDebug then Debug.chat("1",stageArray[rRoll.sType]); end
		for index, value in ipairs(stageArray[rRoll.sType:lower()]) do
			if value["category"] == "Feat" then
				if CharManager.hasFeat(ActorManager.getCreatureNode(rSource),value["name"]) then
					return true;
				end
			elseif value["category"] == "Feature" then
				if CharManager.hasFeature(ActorManager.getCreatureNode(rSource),value["name"]) then
					return true;
				end
			elseif value["category"] == "Trait" then
				if CharManager.hasTrait(ActorManager.getCreatureNode(rSource),value["name"]) then
					return true;
				end
			elseif value["category"] == "Effect" then
				if EffectManager.hasEffect(rSource,value["name"]) then
					return true;
				end
			end
		end
	end
	return false;
end

function addDefaultRolls(nodeParent, nodeChildAdded)
	if Interface.getRuleset() == "5E" then
		local node = DB.createChild(nodeChildAdded,"rollTypes");
		local node5 = DB.createChild(node);
		DB.setValue(node5, "type","string","Attack");
		local node2 = DB.createChild(node);
		DB.setValue(node2, "type","string","Check");
		local node3 = DB.createChild(node);
		DB.setValue(node3, "type","string","Save");
		local node4 = DB.createChild(node);
		DB.setValue(node4, "type","string","Skill");
	end
end

function addStagedRoll(rSource, rTarget, rRoll)
	addRoll(rRoll, rSource, rTarget);
	if RR.bDebug then Debug.chat("staged",rRoll); end

	local rRollTemp = UtilityManager.copyDeep(rRoll);
	rRollTemp.sDesc = "[STAGING]\n" .. rRollTemp.sDesc
	if Interface.getRuleset()=="5E" then
		ActionsManager2.decodeAdvantage(rRollTemp);
	end
	local rMessage = ActionsManager.createActionMessage(rSource, rRollTemp);
	Comm.deliverChatMessage(rMessage);


end

function addRoll(rRoll, rSource, vTargets)
	local wMain = Interface.openWindow("stagedrolls", "");
	local wRoll = wMain.list.createWindow();
	wRoll.setData(rRoll, rSource, vTargets);
end

