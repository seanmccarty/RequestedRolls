-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local vRoll = nil;
local vSource = nil;
local vTargets = nil;

function onClose()
	if vTargets then
		CombatManager.removeCustomDeleteCombatantHandler(onCTEntryDeleted);
	end
end

function onCTEntryDeleted(nodeEntry)
	if not vTargets then
		return;
	end
	local sDeletedPath = nodeEntry.getPath();
	
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

function setData(rRoll, rSource, aTargets)
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

	if rSource then
		source.setValue(ActorManager.getDisplayName(rSource));
		vSource = rSource;
	else
		source_label.setVisible(false);
		source.setVisible(false);
	end
	
	if aTargets and #aTargets > 0 then
		vTargets = aTargets;
	end
	if vTargets then
		CombatManager.setCustomDeleteCombatantHandler(onCTEntryDeleted);
	end
	updateTargetDisplay();
end

function updateTargetDisplay()
	if vTargets and #vTargets > 0 then
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
	
	if not Session.IsHost then
		if vRoll.sDesc ~= "" then
			vRoll.sDesc = vRoll.sDesc .. " ";
		end
		vRoll.sDesc = vRoll.sDesc .. "[" .. Interface.getString("message_manualroll") .. "]";
	end
	
	DiceManager.handleManualRoll(vRoll.aDice);
	--ActionsManager.handleResolution(vRoll, vSource, vTargets);
	RRManagerStaged.fORA(vSource, vTargets, vRoll);
	close();
end

function processCancel()
	close();
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();

	if sDragType == "dice" then
		for _, vDie in ipairs(draginfo.getDiceData()) do
			local w = list.createWindow();
			local count = list.getWindowCount();
			w.sort.setValue(count);
			if type(vDie) == "table" then
				w.label.setValue(vDie.type);
				table.insert(vRoll.aDice,{value=0,type=vDie.type,result=0});
			else
				w.label.setValue(vDie);
			end
			RRManagerStaged.reRoll(w.label.getValue(), w.value.getValue());
			local sDice = DiceManager.convertDiceToString(vRoll.aDice, vRoll.nMod);
			vRoll.aDice.expr = sDice;
		end
		return true;
	end
end
