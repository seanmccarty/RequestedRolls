function action(draginfo)

	local aParty = {};
	for _,v in pairs(RRConsole.getSelectedChars()) do
		local rActor = ActorManager.resolveActor(v);
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local sAbilityStat = DB.getValue("requestsheet.checkselected", ""):lower();
	
	ModifierStack.lock();
	for _,v in pairs(aParty) do
		performCheckRoll(v, sAbilityStat);
	end
	ModifierStack.unlock(true);

	return true;
end

function onButtonPress()
    if (table.getn(RRConsole.getSelectedChars())>0) then
        return action();
    end
end	

--originally from actionCheck.performpartysheetroll
function performCheckRoll(rActor, sCheck)
	local rRoll = ActionCheck.getRoll(rActor, sCheck);
	Debug.chat("perofrmchek", rRoll);
	local nTargetDC = DB.getValue("requestsheet.checkdc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	rRoll.nTarget = nTargetDC;
	if DB.getValue("requestsheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
		rRoll.bTower = true;
	end

	ActionsManager.performAction(draginfo, rActor, rRoll);
	--notifyApplyCheck(rActor, rRoll)
end

--from manager_action_attack
OOB_MSGTYPE_APPLYCHK = "applychk";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYCHK, handleApplyCheck);
end

function handleApplyCheck(msgOOB)
	local rActor = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rRoll = {};
	rRoll.sSource = msgOOB.sSource;
	rRoll.aDice, rRoll.nMod = StringManager.convertStringToDice(msgOOB.sDice);
	rRoll.sType = msgOOB.sType;
	rRoll.sDesc = msgOOB.sDesc;
	
	--local nTotal = tonumber(msgOOB.nTotal) or 0;
	--applyAttack(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sAttackType, msgOOB.sDesc, nTotal, msgOOB.sResults);
	Debug.chat("postsendroll", rRoll);

	ActionsManager.performAction(nil, rActor, rRoll);
	--delta1
end

--s'vRoll' | { s'sSource' = s'combattracker.list.id-00003', s'nMod' = #3, s'sDesc' = s'[SAVE] Wisdom', s'sType' = s'save', s'sSaveDesc' = s'[SAVE VS] Frightful presence [WIS DC 16]', s'aDice' = { #1 = s'd20' }, s'nTarget' = s'16' }
--s'vRoll' | { s'aDice' = { #1 = s'd8' }, s'bCritical' = bFALSE, s'sDesc' = s'[DAMAGE] Sacred flame - cantrip (at will) [TYPE: radiant (1d8)()(1)()]', s'clauses' = { #1 = { s'dice' = { #1 = s'd8' }, s'modifier' = #0, s'dmgtype' = s'radiant', s'statmult' = #1, s'stat' = s'', s'nTotal' = #0 } }, s'nMod' = #0, s'sType' = s'damage', s'nOrigClauses' = #1 }
--s'vSource' | { s'sType' = s'charsheet', s'sCreatureNode' = s'charsheet.id-00002', s'sCTNode' = s'combattracker.list.id-00002', s'sName' = s'Bard Test' }
function notifyApplyCheck(rActor, rRoll)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYCHK;
	
	if bSecret then
	--	msgOOB.nSecret = 1;
	else
	--	msgOOB.nSecret = 0;
	end
	--msgOOB.sAttackType = sAttackType;
	--msgOOB.nTotal = nTotal;
	
	--msgOOB.sResults = sResults;

	msgOOB.sSourceNode = ActorManager.resolveActor(rActor);
	msgOOB.sSource = rRoll.sSource;
	msgOOB.sType = rRoll.sType;
	msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod, true);
	Debug.chat("presendroll", rRoll);

	Comm.deliverOOBMessage(msgOOB);
end