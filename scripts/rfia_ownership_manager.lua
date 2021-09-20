local DM_USERNAME = "RFIA_DM";
local usernameIdentityMap = {};

function getDMUsername()
	return DM_USERNAME;
end

function onInit()
	if Session.IsHost then
		User.onIdentityActivation = onIdentityActivation;
		User.onLogin = onLogin;
	end
end

function onLogin(username, activated)
	-- Debug.console("onLogin");
	if Session.IsHost then	
		-- Debug.console("onLogin isHost");
		if activated == true then
			RFIARequestManager.createOrGetRequestGroupForPlayer(username);
		end
	end
end


function onIdentityActivation(identity, username, activated)
	if activated == true then
		addUserOwnership(username, identity);
	else
		removeUserOwnership(username, identity);
	end
	-- Debug.console("onIdentityActivation usernameIdentityMap", usernameIdentityMap);
end

function addUserOwnership(username, identity)
	removePair(DM_USERNAME, identity);
	addPair(username, identity);
end

function removeUserOwnership(username, identity)
	removePair(username, identity);
	addPair(DM_USERNAME, identity);
end

function getUsernamePair(identity)
	for _, userIdentityMatch in pairs(usernameIdentityMap) do
		if userIdentityMatch.identity == identity then
			return userIdentityMatch.username;
		end
	end
	return DM_USERNAME;
end

function isOwnedByDM(identity) 
	return isOwnerDm(getUsernamePair(identity));
end

function isOwnerDm(owner)
	return owner == DM_USERNAME;
end



function addPair(username, identity)
	newUserIdentity = {};
	newUserIdentity.username = username;
	newUserIdentity.identity = identity;
	table.insert(usernameIdentityMap, newUserIdentity);
end

function removePair(username, identity)
	for i=1, table.getn(usernameIdentityMap) do
		userIdentityMatch = usernameIdentityMap[i];
		if username == userIdentityMatch.username and identity == userIdentityMatch.identity then
			table.remove(usernameIdentityMap,i);
			return;
		end
	end
end




