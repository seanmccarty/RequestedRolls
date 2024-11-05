local _ctrlRoll = nil;
local _nButtonH = 20;

local _ctrlTitle = nil;
local _sTitle = "";

local _ctrlCombo = nil;
local _nComboWidth = 0.0;

local _showDC = false;
local _unsorted = false;
local _ctrlDCLabel = nil;
local _ctrlDCField = nil;

local _rightMostControl = nil;

function onInit()
	_sTitle = Interface.getString(titleTextres[1]);
	if comboWidth and comboWidth[1] then
		_nComboWidth = tonumber(comboWidth[1]);
	end
	if showDC then
		_showDC = true;
	end
	if unsorted then
		_unsorted = true;
	end

	local sName = getName() or "";
	local sButton = sName .. "_roll";
	_ctrlRoll = window.createControl("RR_button_roll", sButton);
	_ctrlRoll.setRollType(sName);
	_ctrlRoll.setAnchor("left", sName, "left", "absolute", 10);
	_ctrlRoll.setAnchor("top", sName, "center", "absolute", -(math.floor(_nButtonH/2)) + 0);

	_ctrlTitle = window.createControl("label",sName.."_title");
	_ctrlTitle.setValue(_sTitle);
	_ctrlTitle.setAnchor("left", sButton, "right", "relative", 4);
	_ctrlTitle.setAnchor("top", sName, "center", "absolute", -(math.floor(_nButtonH/2)) + 0);
	_rightMostControl = _ctrlTitle;

	if _nComboWidth>0 then
		if _unsorted then
			_ctrlCombo = window.createControl("RR_combobox_unsorted","rolls."..sName..".selected");
		else
			_ctrlCombo = window.createControl("RR_combobox","rolls."..sName..".selected");
		end
		_ctrlCombo.setRollType(sName);
		_ctrlCombo.setAnchor("left", sButton, "right", "relative", 5);
		_ctrlCombo.setAnchor("top", sName, "center", "absolute", -(math.floor(_nButtonH/2)) + 0);
		_ctrlCombo.setAnchoredWidth(_nComboWidth)
		_rightMostControl = _ctrlCombo;
	end

	if _showDC then
		_ctrlDCLabel = window.createControl("RR_DCLabel","rolls."..sName.."_DCLabel");
		_ctrlDCLabel.setAnchor("left", sButton, "right", "relative", 5);
		_ctrlDCLabel.setAnchor("top", sName, "center", "absolute", -(math.floor(_nButtonH/2)) + 0);

		_ctrlDCField = window.createControl("RR_DCField",sName..".dc");
		_ctrlDCField.setAnchor("left", sButton, "right", "relative", 5);
		_ctrlDCField.setAnchor("top", sName, "center", "absolute", -(math.floor(_nButtonH/2)) + 0);
		_rightMostControl = _ctrlDCField;
	end
end

function onFirstLayout()
	local x,_ = _rightMostControl.getPosition();
	local x2,_ = _rightMostControl.getSize();
	local xBox,_ = self.getPosition();
	self.setAnchoredWidth(x+x2+13-xBox)
end