local vRoll = nil;
local vSource = nil;
local vTargets = nil;

---Pass through function to get the local variables into this script. You cannot access local vars in a different layer.
---It also stores the CTNode in a hidden field and notifies the host that they have a manual roll to make
function setData(rRoll, rSource, aTargets)
    vRoll = rRoll;
    vSource = rSource;
    vTargets = aTargets;
    if rSource then
        CTNodeID.setValue(rSource.sCTNode);
        RR.notifyApplyDirty(vSource.sCTNode,1);
    end

    super.setData(rRoll, rSource, aTargets);
end

---Adds a check to the manual roll window that closes it if you are rolling the last roll in your queue.
---It closes on count=1 because this is called before the list item is actually deleted.
---It also indexes through all open rolls to check if it is the last one for the given CT node.
---If there is only 1, node with the same CTNodeID, it is referring to the one about to close. 
function onClose()
    if vSource then
        local isClean = 0;
        local currChar = CTNodeID.getValue();
        for key, value in pairs(windowlist.getWindows()) do
            if value.CTNodeID.getValue() == currChar then
                isClean = isClean+1;
            end
        end
        if isClean == 1 then
            RR.notifyApplyDirty(vSource.sCTNode,0);
        end
    end
    if windowlist.getWindowCount()==1 then
        windowlist.window.close();
    end
    super.onClose();
end

---Override function if roll is for tower, otherwise it passes it through
function processRoll()
    if RR.bDebug then Debug.chat("vRoll",vRoll); end

    if OptionsManager.isOption("RR_option_label_modAfterDisplay", "on") then 
        applyClientModifiers();
        if Interface.getRuleset()=="5E" then

            local bButtonADV = ModifierManager.getKey("ADV");
            local bButtonDIS = ModifierManager.getKey("DIS");
            local bADV = string.match(vRoll.sDesc, "%[ADV%]");
            local bDIS = string.match(vRoll.sDesc, "%[DIS%]");
            if RR.bDebug then Debug.chat(bADV, bDIS,bButtonADV, bButtonDIS); end

            --if ADV and DIS are both already applied, skip this code
            --if ADV and DIS are both not applied, encode advantage as normal. We have to pass the button values 
            --  becuase we already consumed them to make sure they reset every roll. Only encode advantage on a single die if it is a d20.
            --if the buttons introduce a modifier that would cancel what is already applied, add the appropriate text and remove the extra die that was added
            if not (bADV and bDIS) then
                if not bADV and not bDIS then
                    if #(vRoll.aDice) == 1 and vRoll.aDice[1] == "d20" then
                        ActionsManager2.encodeAdvantage(vRoll,bButtonADV,bButtonDIS);
                    end
                else
                    if (bADV and bButtonDIS) or (bDIS and bButtonADV) then
                        if bADV then
                            vRoll.sDesc = vRoll.sDesc .. " [DIS]";
                        else
                            vRoll.sDesc = vRoll.sDesc .. " [ADV]";
                        end
                        table.remove(vRoll.aDice,2);
                    end
                end
            end
        end
    end

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
    if OptionsManager.isOption("RR_option_label_modAfterDisplay", "on") then 
        applyClientModifiers();
    end

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

---Uses the stack as done in ActionsManager.
---Then calls the presets if this is 5E
function applyClientModifiers()
    local bDescNotEmpty = (vRoll.sDesc ~= "");
    local sStackDesc, nStackMod = ModifierStack.getStack(bDescNotEmpty);
    
    if sStackDesc ~= "" then
        if bDescNotEmpty then
            vRoll.sDesc = vRoll.sDesc .. " [" .. sStackDesc .. "]";
        else
            vRoll.sDesc = sStackDesc;
        end
    end
    vRoll.nMod = vRoll.nMod + nStackMod;

    if Interface.getRuleset()=="5E" then ActionsManager2.encodeDesktopMods(vRoll); end
end