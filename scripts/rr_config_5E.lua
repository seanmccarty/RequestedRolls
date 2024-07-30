---5E specific concentration roll
function onInit()
	RRRollManager.registerRollGetter("concentration", getConcentrationRoll);
end

---Copied from ActionSave.performConcentrationRoll
---@param rActor table the actor
---@return table rRoll the roll
function getConcentrationRoll(rActor)
	local rRoll = { };
	rRoll.sType = "concentration";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getSave(rActor, "constitution");
	rRoll.nMod = nMod;

	rRoll.sDesc = "[CONCENTRATION]";
	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	return rRoll;
end