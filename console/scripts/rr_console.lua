function onInit()
    if Session.IsHost then DB.createNode("requestsheet").setPublic(true); end
end

---comment Checks through all combatatants for the number field that the selector button is tied to
---@return table selectedCharacters a list of selected characters
function getSelectedChars()
    list = {};
    for _,entry in pairs(CombatManager.getCombatantNodes()) do
        if DB.getValue(entry,"RRselected")==1 then
            table.insert(list, entry);
        end
    end
    return list;
end