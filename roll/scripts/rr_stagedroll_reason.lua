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
		local search = "([%w%s%(%)]*[%w%(%)]+):%s*([%+%-�]?)(%w*)";
		-- Debug.chat(string.find(aClauses[i], search));
		local nStarts, nEnds, sLabel, sSign, sMod = string.find(aClauses[i], search);
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
		-- if it is not the first entry, keep the first entry through the character before the string (hence minus 1)
		if startIndex>1 then
			resultText = string.sub(fullText,1,startIndex-1)
		end
		resultText = resultText .. string.sub(fullText,endIndex)
		setValue(resultText)
		bParsed = false;
	end
end

function onDoubleClick(x, y)
	action();
	return true;
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

---This sets the drag data when the reason string is dragged so that dice are shown
---@param draginfo table the draginfo object from the requisite drag action
function setDragData(draginfo)
	draginfo.setType(RRDropManager.RRSTAGEDREASON);
	draginfo.setIcon("action_roll");
	draginfo.window = self;
	
	local aDice, nMod = DiceManager.convertStringToDice(nDragMod, true)
	local tRoll = {};
	tRoll.aDice = aDice;
	ActionsManager.encodeRollForDrag(draginfo, 1, tRoll);
end

--Add the window to the drag data and set the drag status so that selection does not change when the cursor moves.
function onDragStart(button, x, y, draginfo)
	setDragData(draginfo)
	bDragging = true;
	return true;
end

--Clear the selection when the drag ends, if it is done early, we would not know what was selectd
function onDragEnd(dragdata)
	setCursorPosition(0);
	bDragging = false;
end