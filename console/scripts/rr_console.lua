function onInit()
    if Session.IsHost then DB.createNode("requestsheet").setPublic(true); end
end

