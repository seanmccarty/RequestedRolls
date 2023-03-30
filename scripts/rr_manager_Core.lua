-- copied from 5E
function hasFeature(nodeChar, s)
	return (RRManagerCore.getFeatureRecord(nodeChar, s) ~= nil);
end
function getFeatureRecord(nodeChar, s)
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