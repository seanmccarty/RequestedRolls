local vRoll = nil;
local vSource = nil;
local vTargets = nil;

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_DICETOWER, handleRRDiceTower);
end

-- override functions
function setData(rRoll, rSource, aTargets)
    vRoll = rRoll;
    vSource = rSource;
    vTargets = aTargets;
    super.setData(rRoll, rSource, aTargets);
end

function processRoll()
    if RR.bDebug then Debug.chat("vRoll",vRoll); end
    if vRoll.bTower == true then
        sendTower(vRoll, vSource, vTargets);
        close();
    else
        super.processRoll();
    end
	
end

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
        
        sendTower(vRoll, vSource, vTargets);
        close();
    else
	    super.processOK();
    end
end

-- New functions

OOB_MSGTYPE_DICETOWER = "RRdicetower";
function sendTower(rRoll, rSource, aTargets)
    local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_DICETOWER;
    msgOOB.sType = rRoll.sType;
    msgOOB.sDesc = rRoll.sDesc;
	msgOOB.sender = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sUser = User.getUsername();
    
	msgOOB.sDice = StringManager.convertDiceToString(rRoll.aDice, rRoll.nMod);
	msgOOB.aDice = nil;
	msgOOB.nMod = nil;
    msgOOB.nTarget = rRoll.nTarget;
    -- if one of the dice has a result, we are going to send the results as a string
    if rRoll.aDice[1].result then 
        msgOOB.sResults = resultsToString(rRoll.aDice);
    end

    Comm.deliverOOBMessage(msgOOB, "");
    if not Session.IsHost then
        local msg = {font = "chatfont", icon = "dicetower_icon", text = ""};
        if rSource then
            msg.sender = ActorManager.getDisplayName(rSource);
        end
        if msgOOB.sDesc ~= "" then
            msg.text = msgOOB.sDesc .. " ";
        end
        msg.text = msg.text .. "[" .. msgOOB.sDice .. "]";
        
        Comm.addChatMessage(msg);
    end
end

function handleRRDiceTower(msgOOB)
	local rActor = nil;
	if msgOOB.sender and msgOOB.sender ~= "" then
		rActor = ActorManager.resolveActor(msgOOB.sender);
	end
	local rRoll = DiceTowerManager.decodeRollFromOOB(msgOOB);

    -- player actually did a manual roll so there are results associated
    if msgOOB.sResults then
        local res = stringToResults(msgOOB.sResults);
        -- for each dice in aDice, we initialize it to a blank array and then add the type and result items
        for i,sDice in ipairs(rRoll.aDice) do
            rRoll.aDice[i] = {};
            rRoll.aDice[i].type = sDice;
            rRoll.aDice[i].result = res[i];
        end
    end
	rRoll.sDesc = "[" .. Interface.getString("dicetower_tag") .. "] " .. (rRoll.sDesc or "");
    rRoll.nTarget = tonumber(msgOOB.nTarget) or nil;
    -- if rRoll.aDice[1].result exists this was a manual roll
    if rRoll.aDice[1].result then
        ActionsManager.handleResolution(rRoll, rActor, nil);
    else
        ActionsManager.roll(rActor, nil, rRoll);
    end
end

-- Matching functions that take a roll with dice and convert results to string and vice versa. 
-- The dice stay in the same order while being transferred
-- TODO: add handling for aDice without results
function resultsToString(aDice)
    local res = "";
    for _,w in ipairs(aDice) do
        res = res .. "r" .. w.result;
    end
    return res;
end

function stringToResults(s)
    list = {};
    for v in s:gmatch("%d+") do
        table.insert(list, tonumber(v));
    end
    return list;
end