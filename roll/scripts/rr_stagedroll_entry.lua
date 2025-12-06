local vRoll = nil;
local vSource = nil;
local vTargets = nil;
local originalTotal=0;
local vApplicableIdentifier = nil;
local sRollID;

function onClose()
	if vTargets then
		CombatManager.removeCustomDeleteCombatantHandler(onCTEntryDeleted);
	end

	ActionsManager.unregisterResultHandler(sRollID);
	if windowlist.getWindowCount()==1 then
		windowlist.window.close();
	end
end

function onCTEntryDeleted(nodeEntry)
	if not vTargets then
		return;
	end
	local sDeletedPath = DB.getPath(nodeEntry);
	
	local bAnyDelete = false;
	local nTarget = 1;
	while vTargets[nTarget] do
		local bDelete = false;
		
		local sCTNode = ActorManager.getCTNodeName(vTargets[nTarget]);
		if sCTNode ~= "" and sCTNode == sDeletedPath then
			bDelete = true;
		end
		
		if bDelete then
			table.remove(vTargets, nTarget);
			bAnyDelete = true;
		else
			nTarget = nTarget + 1;
		end
	end
	
	if bAnyDelete then
		updateTargetDisplay();
	end
end

function setData(rRoll, rSource, aTargets,rApplicableIdentifier)
	if rRoll.aDice and rRoll.aDice.total then
		originalTotal = rRoll.aDice.total;
	end

	vApplicableIdentifier = rApplicableIdentifier;
	reasons.setValue(table.concat(vApplicableIdentifier,"; "));

	rolltype.setValue(StringManager.capitalize(rRoll.sType));
	
	local sDice = DiceManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	rollexpr.setValue(sDice);
	
	if (rRoll.sDesc or "") ~= "" then
		desc.setValue(rRoll.sDesc);
	else
		desc_label.setVisible(false);
		desc.setVisible(false);
	end
	
	for kDie,vDie in ipairs(rRoll.aDice) do
		local w = list.createWindow();
		w.sort.setValue(kDie);
		if type(vDie) == "table" then
			w.label.setValue(vDie.type);
			w.value.setValue(vDie.result);
		else
			w.label.setValue(vDie);
		end
		if kDie == 1 then
			w.value.setFocus();
		end
	end
	list.applySort();
	vRoll = rRoll;

	-- Staged rolls should not be able to be restaged
	vRoll.blockStage = true;

	if rSource then
		source.setValue(ActorManager.getDisplayName(rSource));
		vSource = rSource;
	else
		source_label.setVisible(false);
		source.setVisible(false);
	end
	
	-- remove #aTargets>0 becuase the targets array is no longer numerical index
	if aTargets then
		vTargets = aTargets;
	end
	if vTargets then
		CombatManager.setCustomDeleteCombatantHandler(onCTEntryDeleted);
	end
	updateTargetDisplay();

	local sTemp = tostring(windowlist.getWindowCount());
	local sRandom = tostring(math.random(1000000000));
	sRollID = sTemp .. sRandom;
	ActionsManager.registerResultHandler(sRollID, onRoll);
end

function onRoll(rSource, rTarget, rRoll)
	if rRoll.nStageSort then
		local nSort = tonumber(rRoll.nStageSort);
		for _,w in ipairs(list.getWindows()) do
			if nSort == w.sort.getValue() then
				w.value.setValue(rRoll.aDice[1].value);
				break;
			end
		end
	end

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function updateTargetDisplay()
	-- remove #vTargets>0 becuase the targets array is no longer numerical index
	if vTargets then
		local aTargetStrings = {};
		for _,v in ipairs(vTargets) do
			table.insert(aTargetStrings, ActorManager.getDisplayName(v));
		end
		targets.setValue(table.concat(aTargetStrings, ", "));
	else
		targets_label.setVisible(false);
		targets.setVisible(false);
	end
end

function isLastDie(nSort)
	if nSort == #(vRoll.aDice) then
		return true;
	end
	return false;
end



function processOK()
	for _,w in ipairs(list.getWindows()) do
		local nSort = w.sort.getValue();
		local nValue = w.value.getValue();
		
		if vRoll.aDice[nSort] then
			if type(vRoll.aDice[nSort]) ~= "table" then
				local rDieTable = {};
				rDieTable.type = vRoll.aDice[nSort];
				vRoll.aDice[nSort] = rDieTable;
			end
			if vRoll.aDice[nSort].type:sub(1,1) == "-" then
				vRoll.aDice[nSort].result = -nValue;
			else
				vRoll.aDice[nSort].result = nValue;
			end
			vRoll.aDice[nSort].value = vRoll.aDice[nSort].result;
		end
	end
	
	local newSum=0;
	for index, die in ipairs(vRoll.aDice) do
		if die.result then
			newSum = newSum + die.result;
		end
	end
	if originalTotal ~= newSum then
		if vRoll.sDesc ~= "" then
			vRoll.sDesc = vRoll.sDesc .. " ";
		end
		vRoll.sDesc = string.format("%s [%s %s]", vRoll.sDesc, Interface.getString("RR_msg_rollModified"), originalTotal);
	end
	


	DiceManager.handleManualRoll(vRoll.aDice);
	--ActionsManager.handleResolution(vRoll, vSource, vTargets);
	RRManagerStaged.fOriginalResolveAction(vSource, vTargets, vRoll);
	close();
end

function processCancel()
	close();
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();

	if sDragType == "dice" then
		addDice(draginfo.getDiceData())
		return true;
	end
end

function addDice(diceData, sReason)
	for _, vDie in ipairs(diceData) do
		local w = list.createWindow();
		local count = list.getWindowCount();
		w.sort.setValue(count);
		local result = 0;
		if type(vDie) == "table" then
			w.label.setValue(vDie.type);
		else
			w.label.setValue(vDie);
		end
		local sDieType = w.label.getValue();
		--local nDieType = string.match(sDieType, "%d+")
		--result = math.random(nDieType);
		table.insert(vRoll.aDice,{value=0,type=sDieType,result=0});

		reRoll(w.label.getValue(), w.value.getValue(), nil, sReason,w.sort.getValue());

		--w.value.setValue(result);
		--vRoll.aDice.expr should only include the dice, not the plus or minus becuase those get handled in action message

	end
	local sDice = DiceManager.convertDiceToString(vRoll.aDice, 0);
	vRoll.aDice.expr = sDice;
end

function reRoll(sDie, oldValue, fauxRollValue, sReason, nSort)
	local rReRoll = {};

	if vRoll.bSecret then
		rReRoll.bSecret = vRoll.bSecret;
	end 
	
	if vRoll.bTower then
		rReRoll.bTower = vRoll.bTower;
	end
	if not oldValue or oldValue == 0  then
		rReRoll.sDesc = "[DICE] Rolling an additional die";
	else
		rReRoll.sDesc = "[DICE] Rolling to replace a " .. oldValue;
	end

	if sReason then
		rReRoll.sDesc = rReRoll.sDesc .. " using " .. sReason;
	end
	if DiceManager.isDiceString(sDie) then
		rReRoll.sType = sRollID;

		rReRoll.nStageSort = nSort;
		if fauxRollValue and fauxRollValue > 0 then
			local num = tostring(fauxRollValue);
			rReRoll.aDice =  {};
			table.insert(rReRoll.aDice, {value=num,type=sDie,result=num});
			
			RRManagerStaged.fOriginalResolveAction(nil, nil, rReRoll);
		else
			local aDice, nMod = DiceManager.convertStringToDice(sDie, true)
			rReRoll.aDice = aDice;
			rReRoll.nMod = nMod;
			ActionsManager.performAction(nil, nil, rReRoll);
		end
	else
		rReRoll.sType = "sDice";
		rReRoll.aDice = {};
		rReRoll.aDice.expr = sDie;
		rReRoll.nMod = 0;
		ActionsManager.performAction(nil, nil, rReRoll);
	end
end

function expireUsedEffect(sEffect)
	EffectManager.notifyRemove(ActorManager.getCTNodeName(vSource),sEffect);
end
