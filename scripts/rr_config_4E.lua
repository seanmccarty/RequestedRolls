local oE35skill;

---When ruleset is 4E, overrides the standard RR getSaveRoll and creates the getRoll function in ActionInit
function onInit()
	RRRollManager.registerRollGetter("save",getSaveRoll);
	oE35skill = RRRollManager.E35skill
	RRRollManager.E35skill = E35skill;
	if not ActionInit.getRoll then
		ActionInit.getRoll = addInitRoll;
	end
	-- This is for things like death saving throws since 4E does not use sSaveDesc
	RRActionManager.registerRollType("autosave")
end

---ActionInit for 4E does not define getRoll, this makes the code available
---@param rActor table the actor to roll
---@param bSecretRoll bool if the roll should be secret
---@return table rRoll the roll to be done
function addInitRoll(rActor, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = DiceRollManager.getActorDice({ "d20" }, rActor);;
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[INIT]";
	
	rRoll.bSecret = bSecretRoll;

	-- Determine the modifier and ability to use for this roll
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		if ActorManager.isPC(rActor) then
			rRoll.nMod = DB.getValue(nodeActor, "initiative.total", 0);
		else
			rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
	
	return rRoll;
end

---4E uses saves differently than the other rulesets, you just have one save ability and no DC
---@param rActor table the actor to roll
---@return table rRoll the roll to be done
function getSaveRoll(rActor)
	local rRoll = ActionSave.getRoll(rActor, nil);
    return rRoll;
end

---This lookup is used specifically for 4E, based on 3.5E because it handles NPC perception differently
---If the actor is a NPC, it has a different perception lookup
---@param rActor any the actor to roll
---@param sSkill any the skill to be rolled
---@return table rRoll
function E35skill(rActor, sSkill)
	local rRoll = oE35skill(rActor, sSkill);
	if not ActorManager.isPC(rActor)  and sSkill == "Perception" then
		local nodeActor = ActorManager.getCreatureNode(rActor);
		rRoll = ActionSkill.getRoll(rActor, sSkill, DB.getValue(nodeActor,"perceptionval"));
	end
	return rRoll;
end