local fORA;

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

	if not shouldStage(rSource, rTarget, rRoll) then
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