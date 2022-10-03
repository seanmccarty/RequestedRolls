fORA = nil;

local stageArray = {
	check = {{category="feat", name="lucky"},{category="feature",name="portent"}, {category="trait",name="elven accuracy"},{category="effect",name="Bardic Inspiration"}},
	save = {{category="feat", name="lucky"}},
	skill = {}
};

function onInit()
	fORA = ActionsManager.resolveAction;
	ActionsManager.resolveAction = resolveAction;
end

function resolveAction(rSource, rTarget, rRoll)
	Debug.chat("resolve",rSource, rTarget, rRoll);

	if shouldStage(rSource, rTarget, rRoll) then
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

	if rRoll and rRoll.sType and stageArray[rRoll.sType] then
		Debug.chat("1",stageArray[rRoll.sType]);
		for index, value in ipairs(stageArray[rRoll.sType]) do
			Debug.chat("2",value)
			if value["category"] == "feat" then
				if CharManager.hasFeat(ActorManager.getCreatureNode(rSource),value["name"]) then
					Debug.chat(3,"stage roll feat")
					return true;
				end
			elseif value["category"] == "feature" then
				if CharManager.hasFeature(ActorManager.getCreatureNode(rSource),value["name"]) then
					Debug.chat(3,"stage roll feature")
					return true;
				end
			elseif value["category"] == "trait" then
				if CharManager.hasTrait(ActorManager.getCreatureNode(rSource),value["name"]) then
					Debug.chat(3,"stage roll trait")
					return true;
				end
			elseif value["category"] == "effect" then
				if EffectManager.hasEffect(rSource,value["name"]) then
					Debug.chat(3,"stage roll effect")
					return true;
				end
			end
		end
	end
	return false;
end

function addStagedRoll(rSource, rTarget, rRoll)
	addRoll(rRoll, rSource, rTarget);
	Debug.chat("staged",rRoll);

	local rRollTemp = rRoll;
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

function reRoll(sDie, oldValue)
	local rRoll = {};
	if DiceManager.isDiceString(sDie) then
		rRoll.sType = "dice"
		local aDice, nMod = DiceManager.convertStringToDice(sDie, true)
		rRoll.aDice = aDice;
		rRoll.nMod = nMod;
	else
		rRoll.sType = "sDice";
		rRoll.aDice = {};
		rRoll.aDice.expr = sDie;
		rRoll.nMod = 0;

	end
	rRoll.sDesc = "[DICE] Rolling to replace a " .. oldValue;
	ActionsManager.performAction(nil, nil, rRoll);
end