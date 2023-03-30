-- copied from 5E
function hasAbility(nodeChar, s)
	return (RRManagerCore.getAbilityRecord(nodeChar, s) ~= nil);
end
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