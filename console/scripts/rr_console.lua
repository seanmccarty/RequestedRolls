function onInit()
    if Session.IsHost then DB.createNode("requestsheet").setPublic(true); end
end

function getSelectedChars()
    list = {};
    for _,entry in pairs(rr_list_npc.getWindows()) do
        if isEntrySelected(entry) then
            table.insert(list, entry.getDatabaseNode());
        end
    end
    for _,entry in pairs(rr_list_pc.getWindows()) do
        if isEntrySelected(entry) then
            table.insert(list, entry.getDatabaseNode());
        end
    end
    return list;
end

function isEntrySelected(node)
    isSelected = node.selection.getValue();
    if isSelected == 1 then
        return true;
    end
    return false;
end