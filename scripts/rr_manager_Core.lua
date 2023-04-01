function onInit()
	RRRollManager.getSkillRoll = getSkillRoll;
end

---This was copied from 5E and the function updated. Checks if an ability is present.
---@param nodeChar table
---@param s string
---@return boolean
function hasAbility(nodeChar, s)
	return (RRManagerCore.getAbilityRecord(nodeChar, s) ~= nil);
end

---This was copied from 5E and the relevant DB path updated. Returns the node if an ability is present.
---@param nodeChar table
---@param s string
---@return nil|table
function getAbilityRecord(nodeChar, s)
	if (s or "") == "" then
		return nil;
	end
	
	local sLower = StringManager.trim(s):lower();
	for _,v in ipairs(DB.getChildList(nodeChar, "abilitylist")) do
		local sMatch = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if sMatch == sLower then
			return v;
		end
	end
	return nil;
end

---Splits the selected skill three string. The first two parts are mandatory and the third is an optional specifier of what the default 
---roll should be if it is not explicitly defined on the character.
---@param rActor table
---@return table
function getSkillRoll(rActor)
	local sSkill = DB.getValue("requestsheet.skill.selected", "");
	local sSplit = StringManager.split(sSkill, "~");
	local sFirst = sSplit[1];
	local sSecond = sSplit[2];
	local sDice = sSplit[3];
	local node = RRManagerCore.getSkillRecord(ActorManager.getCreatureNode(rActor),sFirst,sSecond);
	local rRoll = {};
	if node then
		rRoll = { sType = "dice", sDesc = DB.getValue(node, "label", ""), aDice = DB.getValue(node, "dice", ""), nMod = DB.getValue(node, "bonus", 0) };
		return rRoll;
	else
		if sDice then
			local aDice, nMod = DiceManager.convertStringToDice(sDice, true)
			rRoll = { sType = "dice", sDesc = "Using Default Roll for ".. sSkill, aDice = aDice, nMod = nMod };
		else
			rRoll = { sType = "dice", sDesc = "Roll Not Defined for Selected Character", aDice = "", nMod = 0 };
		end
		
		return rRoll;
	end
end

---Checks for a PC skill (NPC not implemented). First it looks for a matching main category and if found checks for the
---specific attribute. Search is case insensitive.
---@param nodeChar table
---@param sMain string
---@param sChild string
---@return table|nil
function getSkillRecord(nodeChar, sMain, sChild)
	if ((sMain or "") == "") or ((sChild or "") == "") then
		return nil;
	end
	
	local sMainLower = StringManager.trim(sMain):lower();
	local sChildLower = StringManager.trim(sChild):lower();
	for _,v in ipairs(DB.getChildList(nodeChar, "maincategorylist")) do
		local sMatch = StringManager.trim(DB.getValue(v, "label", "")):lower();
		if sMatch == sMainLower then
			for _,v2 in ipairs(DB.getChildList(v,"attributelist")) do
				local sMatch2 = StringManager.trim(DB.getValue(v2, "label", "")):lower();
				if sMatch2 == sChildLower then
					return v2;
				end
			end
		end
	end
	return nil;
end