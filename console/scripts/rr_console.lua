local SELECTED_PATH = "isSelectedForRFIA";
function onInit()
    DB.createNode("requestsheet").setPublic(true);
end

function getSelectedChars()
    list = {};
    for _,node in pairs(CombatManager.getCombatantNodes()) do
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