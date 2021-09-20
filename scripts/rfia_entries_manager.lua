--[[
Here we manage "entries" for rfia. Entries are actually CT node entries, but we also add a few of our own fields as well listed below. 

0.11 deprecation - we no longer have a "roll state not asked for" which is where there would normally be no dot on the token picture.
				   Instead either all entries have no rolls left (green dot) or they have rolls to do (red dot). 
]]



local ROLL_STATUS_PATH = "rollStatusForRFIA";
local SELECTED_PATH = "isSelectedForRFIA";
local NPC_SKILLS_PATH ="skills";
local RFIA_NPC_SKILLS_PATH ="skillListForRFIA";
local RFIA_NPC_SKILLS_NAME_PATH = "name";
local RFIA_NPC_SKILLS_MOD_PATH =  "mod";

function getRfiaNpcSkillsPath()
	return RFIA_NPC_SKILLS_PATH;
end

function onInit()
	if Session.IsHost then
		initListWithCT();
	end
end

function initListWithCT()
	for _,node in pairs(getCTEntries()) do
		initCT(node);
	end
end

function initCT(node)
	setUnselected(node);
	setRollStateDone(node);
	initialiseEntrySkills(node);
end

function initialiseEntrySkills(node)
	if not isPcFromNode(node) then
		initialiseNpcEntrySkills(node);
	end	
end

function getOrCreateRootSkillsNode(node)
	return node.createChild(RFIA_NPC_SKILLS_PATH);
end

function initialiseNpcEntrySkills(node)


	--Clear out the skills
	local skillList = getOrCreateRootSkillsNode(node);
	skillList.delete();
	skillList = getOrCreateRootSkillsNode(node);
	
	-- Get the skills if there are any
	skillsString = DB.getValue(node, NPC_SKILLS_PATH);
	if skillsString == nil then
		return;
	end
	
	local aComponents = {};
	
	--Adapated from npc_roll.lua
	local aClauses, aClauseStats = StringManager.split(skillsString, ",;\r", true);
	
	for i = 1, #aClauses do
		local nStarts, nEnds, sMod = string.find(aClauses[i], "([d%dF%+%-]+)%s*$");
		if nStarts then
			local sLabel = "";
			if nStarts > 1 then
				sLabel = StringManager.trim(aClauses[i]:sub(1, nStarts - 1));
			end
			local aDice, nMod = StringManager.convertStringToDice(sMod);
			
			-- We just want the label and the mod and to add this to the CT DB node. 
				-- not sure if we need prof yet...
				-- <prof type="number">1</prof> 
				
			if sLabel ~="" then 
				listEntry = skillList.createChild();
				DB.setValue(listEntry, RFIA_NPC_SKILLS_NAME_PATH, "string", sLabel);
				DB.setValue(listEntry, RFIA_NPC_SKILLS_MOD_PATH, "number", nMod);					
			end
			
			-- For debugging purposes
			-- table.insert(aComponents, {nStart = aClauseStats[i].startpos, nLabelEnd = aClauseStats[i].startpos + nEnds, nEnd = aClauseStats[i].endpos, sLabel = sLabel, aDice = aDice, nMod = nMod });
			-- Debug.console("initialiseNpcEntrySkills aComponents ", aComponents);
		end
	end
end



function getCTEntries()
	return CombatManager.getCombatantNodes();
end


function getSelectedEntries()
	list = {};
	for _,node in pairs(getCTEntries()) do
		-- Debug.console("getSelectedEntries node isSelected", DB.getValue(node, SELECTED_PATH,0));
		if isEntrySelected(node) then
			table.insert(list, node);
		end
	end
	return list;
end

function isEntrySelected(node)
		isSelected = DB.getValue(node, SELECTED_PATH,0);
		if isSelected == 1 then
			return true;
		end
		return false;
end

function isAnyoneSelected()
	for _,node in pairs(getCTEntries()) do
		if isEntrySelected(node) then
			return true;
		end
	end
	return false;
end

function setAllSelectedPC()
	for _,node in pairs(getCTEntries()) do
		if isPcFromNode(node) then
		 setSelected(node);
		end
	end
end

function setAllUnselectedPC()
	for _,node in pairs(getCTEntries()) do
		if isPcFromNode(node) then
		 setUnselected(node);
		end
	end
end

function setAllSelectedNPC()
	for _,node in pairs(getCTEntries()) do
		if not isPcFromNode(node) then
		 setSelected(node);
		end
	end
end

function setAllUnselectedNPC()
	for _,node in pairs(getCTEntries()) do
		if not isPcFromNode(node) then
		 setUnselected(node);
		end
	end
end

function setSelectedState(node, value)
		DB.setValue(node, SELECTED_PATH, "number", value);
end

function setUnselected(node)
	setSelectedState(node, 0);
end

function setSelected(node)
	setSelectedState(node, 1);
end

--Deprecated 0.11
-- function setAllRollStateNotAskedFor()
	-- for _,node in pairs(getCTEntries()) do		
		 -- setRollStateNotAskedFor(node);
	-- end
-- end

function setRollState(node, value)
	DB.setValue(node, ROLL_STATUS_PATH, "number", value);
end

function getRollState(node)
	return DB.getValue(node, ROLL_STATUS_PATH);
end

--Deprecated 0.11
-- function setRollStateNotAskedFor(node)
	-- setRollState(node, 0);
-- end

function setRollStateRequested(node)
	setRollState(node, 1);
end

function setRollStateDone(node)
	setRollState(node, 2);
end


function updateRollState(listCount, ctEntryId)

	
	entry = getEntryById(ctEntryId);
	if listCount > 0 then
		setRollStateRequested(entry);
	else
		setRollStateDone(entry);
	end

end

function getOwner(node)
	local class, recordname = getClassAndRecord(node);
	-- Debug.console("getOwner node", node);
	-- Debug.console("getOwner class", class);
	-- Debug.console("getOwner isPC(class)", isPC(class));
	if (isPC(class)) then
			local identity = convertRecordNameToIdentity(recordname);
			return RFIAOwnershipManager.getUsernamePair(identity);
	else
		-- Debug.console("RFIAOwnershipManager.getDMUsername()", RFIAOwnershipManager.getDMUsername());
		return RFIAOwnershipManager.getDMUsername();
	end
end

function isOwnedByDM(node) 
		local class, recordname = getClassAndRecord(node);
		if isPC(class) then
			local identity = convertRecordNameToIdentity(recordname);
			return RFIAOwnershipManager.isOwnedByDM(identity);
		else
			return true;
		end
end

function isPcFromNode(node)
	local class, recordname = getClassAndRecord(node);
	return isPC(class);
end

function isPC(class)
	if class == "charsheet" then 
		return true;
	else 
		return false;
	end
end

--If you know this is a pc, will return its charsheet id
function getPCCharsheetId(node)
	local class, recordname = getClassAndRecord(node);
	if isPC(class) then
		return convertRecordNameToIdentity(recordname);
	else
		return nil;
	end	
end

--Note id is the ID only, it does not include the full CT node path
function getEntryById(id)
	local entryPath = CombatManager.CT_LIST .. "." .. id;
	return DB.findNode(entryPath);
end

function getEntryByPath(path)
	return DB.findNode(path);
end

function getEntryId(node)
	local class, recordname = getClassAndRecord(node);
	if isPC(class) then 
		return recordname;
	else 
		return node.getName();
	end
end


--This returns the CT node identity which is needed for request management. 
function getCTEntryId(node)
	return node.getName();
end



function getClassAndRecord(node)
	local class, recordname = DB.getValue(node, "link","string","");
	return class, recordname;
end


function convertRecordNameToIdentity(recordname)
	return string.gsub(recordname, "charsheet.", "");
end

function getToken(node)
	return DB.getValue(node, "token", "token", "");
end
