-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bParsed = false;
local aComponents = {};

-- The nDragMod and sDragLabel fields keep track of the entry under the cursor
local sDragLabel = nil;
local nDragMod = nil;
local bDragging = false;

function parseComponents()
	aComponents = {};
	
	-- Get the comma-separated strings
	local aClauses, aClauseStats = StringManager.split(getValue(), ",;\r", true);
	-- Check each comma-separated string for a potential skill roll or auto-complete opportunity
	for i = 1, #aClauses do
		-- sea = "([%w%s\(\)]*[%w\(\)]+):%s*([%+%-�]?)(%d*)";
		sea = "([%w%s\(\)]*[%w\(\)]+):%s*([%+%-�]?)(%w*)";
		--Debug.chat(string.find(aClauses[i], sea))
		local nStarts, nEnds, sLabel, sSign, sMod = string.find(aClauses[i], sea);
		if nStarts then
			-- Calculate modifier based on mod value and sign value, if any
			local nAllowRoll = 0;
			local nMod = 0;
			if sMod ~= "" then
				nAllowRoll = 1;
				if sSign == "-" or sSign == "�" then
					sMod = "-"..sMod;
				end
			end

			-- Insert the possible skill into the skill list
			table.insert(aComponents, {nStart = aClauseStats[i].startpos, nLabelEnd = aClauseStats[i].startpos + nEnds, nEnd = aClauseStats[i].endpos, sLabel = sLabel, nMod = sMod, nAllowRoll = nAllowRoll });
		end
	end
	bParsed = true;
end

-- Reset selection when the cursor leaves the control
function onHover(bOnControl)
	if bDragging or bOnControl then
		return;
	end

	sDragLabel = nil;
	nDragMod = nil;
	setSelectionPosition(0);
end

-- Hilight skill hovered on
function onHoverUpdate(x, y)
	if bDragging then
		return;
	end

	if not bParsed then
		parseComponents();
	end
	local nMouseIndex = getIndexAt(x, y);

	for i = 1, #aComponents, 1 do
		if aComponents[i].nAllowRoll == 1 then
			if aComponents[i].nStart <= nMouseIndex and aComponents[i].nEnd > nMouseIndex then
				setCursorPosition(aComponents[i].nStart);
				setSelectionPosition(aComponents[i].nEnd);

				sDragLabel = aComponents[i].sLabel;
				nDragMod = aComponents[i].nMod;
				setHoverCursor("hand");
				return;
			end
		end
	end
	
	sDragLabel = nil;
	nDragMod = nil;
	setHoverCursor("arrow");
end

function action(draginfo)
	if sDragLabel then
		local aDice, nMod = DiceManager.convertStringToDice(nDragMod, true)
		window.addDice(aDice, sDragLabel);
		window.expireUsedEffect(sDragLabel)
		local fullText = getValue();
		local startIndex = getCursorPosition();
		local endIndex = getSelectionPosition();
		local resultText = "";
		if startIndex>1 then
			resultText = string.sub(fullText,1,startIndex)
		end
		resultText = resultText .. string.sub(fullText,endIndex)
		setValue(resultText)
	end
end

function onDoubleClick(x, y)
	action();
	return true;
end

function onDragStart(button, x, y, draginfo)
	action(draginfo);

	bDragging = true;
	setCursorPosition(0);
	
	return true;
end

function onDragEnd(draginfo)
	bDragging = false;
end

-- Suppress default processing to support dragging
function onClickDown(button, x, y)
	return true;
end

-- On mouse click, set focus, set cursor position and clear selection
function onClickRelease(button, x, y)
	setFocus();
	
	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end
