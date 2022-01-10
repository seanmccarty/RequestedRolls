-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem(Interface.getString("list_menu_createitem"), "insert", 5);
	
	-- Construct default skills
	if self.datasource[1] == ".skilllist" then
		constructDefaultSkills();
	end
	if self.datasource[1] == ".checklist" then
		constructDefaultChecks();
	end
	if self.datasource[1] == ".savelist" then
		constructDefaultSaves();
	end
end

function onAbilityChanged()
	for _,w in ipairs(getWindows()) do
		if w.isCustom() then
			w.idelete.setVisibility(bEditMode);
		else
			w.idelete.setVisibility(false);
		end
	end
end

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.parentcontrol.window.options_iedit.getValue() == 1);
	for _,w in ipairs(getWindows()) do
		if w.isCustom() then
			w.idelete.setVisibility(bEditMode);
		else
			w.idelete.setVisibility(false);
		end
	end
end

function addEntry(bFocus)
	local w = createWindow();
	w.setCustom(true);
	if bFocus and w then
		w.name.setFocus();
	end
	return w;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

-- checks 
function constructDefaultChecks()
	buildList(DataCommon.ability_ltos,DataCommon.psabilitydata);
end

-- default saves, ability data is for non-5E rulesets
function constructDefaultSaves()
	if DataCommon.save_ltos then 
		aSave = DataCommon.save_ltos;
	else
		aSave = DataCommon.ability_ltos;
	end

	if DataCommon.pssavedata then 
		aPsSave = DataCommon.pssavedata;
	else
		aPsSave = DataCommon.psabilitydata;
	end

	buildList(aSave, aPsSave);
end

-- Create default skill selection
function constructDefaultSkills()
		-- Collect existing entries
		local entrymap = {};

		for _,w in pairs(getWindows()) do
			local sLabel = w.name.getValue(); 
		
			if DataCommon.skilldata[sLabel] then
				if not entrymap[sLabel] then
					entrymap[sLabel] = { w };
				else
					table.insert(entrymap[sLabel], w);
				end
			else
				w.setCustom(true);
			end
		end

		-- Set properties and create missing entries for all known skills. skill data table is built differently so we use different logic.
		for k, t in pairs(DataCommon.skilldata) do
			local matches = entrymap[k];
			if not matches then
				local w = createWindow();
				if w then
					w.name.setValue(k);
					w.show.setValue(2);
					matches = { w };
				end
			end
			
			-- Update properties, need to loop through so only the first instance is made readonly
			local bCustom = false;
			for _, match in pairs(matches) do
				match.setCustom(bCustom);
				bCustom = true;
			end
		end
end

---Builds the default check or save list based on the provided tables, sets standard rolls to not deletable
---@param ltosTable table the ltos table from DataCommon for the relevant list
---@param psTable table the party sheet table from DataCommon for the relevant list
function buildList(ltosTable, psTable)
	-- Collect existing entries
	local entrymap = {};
	-- look for all entries with the same name as a standard roll
	for _,w in pairs(getWindows()) do
		local sLabel = w.name.getValue(); 
	
		if ltosTable[sLabel:lower()] then
			if not entrymap[sLabel] then
				entrymap[sLabel] = { w };
			else
				table.insert(entrymap[sLabel], w);
			end
		else
			w.setCustom(true);
		end
	end
	-- Set properties and create missing entries for all known checks/saves
	for k, t in pairs(psTable) do
		local matches = entrymap[t];
		if not matches then
			local w = createWindow();
			if w then
				w.name.setValue(t);
				w.show.setValue(2);
				matches = { w };
			end
		end
		
		-- Update properties, need to loop through so only the first instance is made readonly
		local bCustom = false;
		for _, match in pairs(matches) do
			match.setCustom(bCustom);
			bCustom = true;
		end
	end
end

