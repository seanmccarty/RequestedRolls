-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--[[ 
s'vRoll' | { s'sSource' = s'combattracker.list.id-00003', s'nMod' = #3, s'sDesc' = s'[SAVE] Wisdom', s'sType' = s'save', s'sSaveDesc' = s'[SAVE VS] Frightful presence [WIS DC 16]', s'aDice' = { #1 = s'd20' }, s'nTarget' = s'16' }

s'vRoll' | { s'aDice' = { #1 = s'd8' }, s'bCritical' = bFALSE, s'sDesc' = s'[DAMAGE] Sacred flame - cantrip (at will) [TYPE: radiant (1d8)()(1)()]', s'clauses' = { #1 = { s'dice' = { #1 = s'd8' }, s'modifier' = #0, s'dmgtype' = s'radiant', s'statmult' = #1, s'stat' = s'', s'nTotal' = #0 } }, s'nMod' = #0, s'sType' = s'damage', s'nOrigClauses' = #1 }

s'vSource' | { s'sType' = s'charsheet', s'sCreatureNode' = s'charsheet.id-00002', s'sCTNode' = s'combattracker.list.id-00002', s'sName' = s'Bard Test' }

s'vTargets' | { #1 = { s'sType' = s'charsheet', s'sCreatureNode' = s'charsheet.id-00002', s'sCTNode' = s'combattracker.list.id-00002', s'sName' = s'Bard Test' }, #2 = { s'sType' = s'charsheet', s'sCreatureNode' = s'charsheet.id-00001', s'sCTNode' = s'combattracker.list.id-00001', s'sName' = s'test' } }

 ]]
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
	
	local sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	rollexpr.setValue(sDice);
	
	if (rRoll.sDesc or "") ~= "" then
		desc.setValue(rRoll.sDesc);
	else
		desc_label.setVisible(false);
		desc.setVisible(false);
	end
	
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
	elseif aTargets then
		vTargets = { aTargets };
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

function processRoll()
	local rThrow = ActionsManager.buildThrow(vSource, vTargets, vRoll, true);
	Comm.throwDice(rThrow);
	close();
end

function processCancel()
	close();
end

