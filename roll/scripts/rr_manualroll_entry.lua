local vRoll = nil;
local vSource = nil;
local vTargets = nil;

---Pass through function to get the local variables into this script. You cannot access local vars in a different layer
function setData(rRoll, rSource, aTargets)
    vRoll = rRoll;
    vSource = rSource;
    vTargets = aTargets;
    super.setData(rRoll, rSource, aTargets);
end

---Adds a check to the manual roll window that closes it if you are rolling the last roll in your queue.
---It closes on count=1 because this is called before the list item is actually deleted.
function onClose()
    if windowlist.getWindowCount()==1 then
        windowlist.window.close();
    end
    super.onClose();
end

---Override function if roll is for tower, otherwise it passes it through
function processRoll()
    if RR.bDebug then Debug.chat("vRoll",vRoll); end
    if vRoll.bTower == true then
        RRTowerManager.sendTower(vRoll, vSource, vTargets);
        close();
    else
        super.processRoll();
    end
end

---The tower roll function for this is basically a copy of the super.processOK but the final call is to sendTower
---instead of handleResolution
function processOK()
    if vRoll.bTower == true then
        for _,w in ipairs(list.getWindows()) do
            local nSort = w.sort.getValue();
            local nValue = w.value.getValue();
            
            if vRoll.aDice[nSort] then
                if type(vRoll.aDice[nSort]) ~= "table" then
                    local rDieTable = {};
                    rDieTable.type = vRoll.aDice[nSort];
                    vRoll.aDice[nSort] = rDieTable;
                end
                if vRoll.aDice[nSort].type:sub(1,1) == "-" then
                    vRoll.aDice[nSort].result = -nValue;
                else
                    vRoll.aDice[nSort].result = nValue;
                end
                vRoll.aDice[nSort].value = nil;
            end
        end
        
        if not Session.IsHost then
            if vRoll.sDesc ~= "" then
                vRoll.sDesc = vRoll.sDesc .. " ";
            end
            vRoll.sDesc = vRoll.sDesc .. "[" .. Interface.getString("message_manualroll") .. "]";
        end
        
        RRTowerManager.sendTower(vRoll, vSource, vTargets);
        close();
    else
	    super.processOK();
    end
end
