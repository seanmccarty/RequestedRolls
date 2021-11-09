--- This script contains function to create wrappers for Rolls/Requests/PCs.
--- It exists just for a reason. Avoid to spread DB.setValue, DB.getValue and strings around the code.
--- It's a less optimized approach but it's more maintainable in the long run


function wrapRoll(rollNode)
	roll = {}
	roll.node = rollNode;
	roll.isValid = function(roll)
		return 
			roll.node ~= nil and 
			roll:getName() ~= nil and 
			roll:getName() ~= "" and
			roll:getType() ~= nil and
			roll:getType() ~= "";
	end
	
	if rollNode == nil then return roll; end
	
	roll.getValue 	= function(roll, nodename, defaultvalue) return DB.getValue(roll.node, nodename, defaultvalue) end;
	roll.getName 	= function(roll) return roll:getValue("name", ""); end
	roll.getRealName = function(roll) return roll:getValue("realname", ""); end
	roll.getType 	= function(roll) return roll:getValue("type", ""); end
	roll.getId 		= function(roll) return roll:getValue("id", 0); end
	roll.getCategory= function(roll) return roll:getValue("category", ""); end;
	roll.isSelected = function(roll) return roll:getValue("isSelected", "") end;

	
	roll.setName = function(roll, name) DB.setValue(roll.node, "name", "string", name); end
	roll.setRealName = function(roll, name) DB.setValue(roll.node, "realname", "string", name); end
	roll.setCategory = function(roll, category) DB.setValue(roll.node, "category", "string", category); end
	roll.setType = function(roll, rolltype) DB.setValue(roll.node, "type", "string", rolltype); end
	roll.setDescription = function(roll, description) DB.setValue(roll.node, "description", "string", description); end
	roll.setSelected = function(roll, selected) DB.setValue(roll.node, "isSelected", "number", selected); end
	roll.setId = function(roll, id) DB.setValue(roll.node, "id", "number", id); end
	
	roll.resetSelection = function(roll) roll:setSelected(0); end
			
	roll.register = function(roll, listener)
		DB.addHandler(roll.node.getPath() .. ".name","onUpdate", listener.updateName);
		DB.addHandler(roll.node.getPath() .. ".isSelected","onUpdate", listener.updateSelected);
	end
	
	roll.unregister = function(roll, listener)
		DB.removeHandler(roll.node.getPath() .. ".name","onUpdate", listener.updateName);
		DB.removeHandler(roll.node.getPath() .. ".isSelected","onUpdate", listener.updateSelected);
	end
		
	return roll;
end

function wrapRequest(requestNode)
	request = {}
	request.node = requestNode;
	if request.node == nil then return request; end
	
	request.getValue 	= function(request, nodename, defaultvalue) return DB.getValue(request.node, nodename, defaultvalue) end;
	request.setValue 	= function(request, nodename, nodetype, value) 
		if nodetype == "bool" then
			if value == true then
				DB.setValue(request.node, nodename, "number", 1);
			else
				DB.setValue(request.node, nodename, "number", 0);
			end
		else
			DB.setValue(request.node, nodename, nodetype, value);
		end
	end;
	
	request.getRollId = function(request) return request:getValue("rollId", 0); end
	request.getRollName = function(request) return request:getValue("name", ""); end
	request.getRollType = function(request) return request:getValue("type", ""); end
	request.getIdentity = function(request) return request:getValue("identity", ""); end
	request.getCtIdentity = function(request) return request:getValue("ctIdentity", ""); end
	request.isPc = function(request) return request:getValue("isPc", 0) == 1; end
	request.getToken = function(request) return request:getValue("token", ""); end
	request.getDescription = function(request) return request:getValue("description", ""); end
	request.getModifier = function(request, modifierName) return request:getValue(modifierName, ""); end
	request.isHidden = function(request) return request:getValue("HIDDEN", "0") == "1"; end
	request.getDC = function(request) 
		dc = tonumber(request:getValue("DC", "0"));
		if dc <= 0 then
			dc = nil;
		end
		
		return dc;
	end
	request.getRollOverrideData = function(request)
		
		rollOverrideDataNode =  request.node.getChild("rollOverrideData");
		local vTable = {};
		for key, node  in pairs(rollOverrideDataNode.getChildren()) do
			vTable[key] = node.getValue();
		end

		local sDice =  vTable["sDice"];
		aDice, nMod = StringManager.convertStringToDice(sDice);
		vTable["sDice"] = nil;
		
		if aDice ~= nil then
			vTable["aDice"] = aDice;
		end
		
		if nMod ~= nil then
			vTable["nMod"] = nMod;
		end

		return vTable;
	end;
		
		
	request.setIdentity = function(request, identity) request:setValue("identity", "string", identity); end
	request.setCtIdentity = function(request, ctIdentity) request:setValue("ctIdentity", "string", ctIdentity); end
	request.setIsPc = function(request, isPc)
		local value = 0;
		if isPc then 
			value = 1;
		end
		request:setValue("isPc", "number", value); 
	end 
	request.setToken = function(request, token) request:setValue("token", "token", token); end
	request.setRollId = function(request, id) request:setValue("rollId", "number", id); end
	request.setRollName = function(request, rollname) request:setValue("name", "string", rollname); end
	request.setRollType = function(request, rolltype) request:setValue("type", "string", rolltype); end
	request.setDescription = function(request, description) request:setValue("description", "string", description); end
	request.setModifier = function(request, modifierName, modifierValue) request:setValue(modifierName, "string", tostring(modifierValue)); end
	request.setRollOverrideData = function(request, rollOverrideData)
		local rollOverrideDataNode = request.node.getChild("rollOverrideData");
		if rollOverrideDataNode ~= nil then
			DB.delete(rollOverrideDataNode);
		end
		
		childNode = DB.createChild(request.node, "rollOverrideData");
		for name,value in pairs(rollOverrideData) do
			if name ~= "aDice" and name ~= "nMod" then 
				DB.setValue(childNode, name, type(value), value); 
			end
		end
		--Now deal with aDice and nMod 
		local sDice = StringManager.convertDiceToString(rollOverrideData["aDice"], rollOverrideData["nMod"]);
		
		DB.setValue(childNode, "sDice", "string", sDice); 
		
		DB.setValue(childNode, "bRollOverride", "number", 1); 
		
	end		
	
	
	request.getActor = function(request)
		local ctNode = RFIAEntriesManager.getEntryById(request:getCtIdentity());
		return ActorManager.resolveActor(ctNode);
	end
	
	request.destroy = function(request) request.node.delete(); end
	
	request.register = function(request, listener)
		DB.addHandler(request.node.getPath() .. ".description", "onUpdate", listener.updateDescription);
		listener.updateDescription();
		DB.addHandler(request.node.getPath() .. ".identity", "onUpdate", listener.updateIcon);
		listener.updateIcon();
		DB.addHandler(request.node.getPath() .. ".ADV", "onUpdate", listener.updateADV);
		listener.updateADV();
		DB.addHandler(request.node.getPath() .. ".DIS", "onUpdate", listener.updateDIS);
		listener.updateDIS();
		DB.addHandler(request.node.getPath() .. ".HIDDEN","onUpdate", listener.updateHIDDEN);
		listener.updateHIDDEN();
		DB.addHandler(request.node.getPath() .. ".DC","onUpdate", listener.updateDC);
		listener.updateDC();
		DB.addHandler(request.node.getPath() .. ".ModValue","onUpdate", listener.updateModValue);
		DB.addHandler(request.node.getPath() .. ".PLUS2","onUpdate", listener.updateModValue);
		DB.addHandler(request.node.getPath() .. ".PLUS5","onUpdate", listener.updateModValue);
		DB.addHandler(request.node.getPath() .. ".MINUS2","onUpdate", listener.updateModValue);
		DB.addHandler(request.node.getPath() .. ".MINUS5","onUpdate", listener.updateModValue);
		listener.updateModValue();
		DB.addHandler(request.node.getPath() .. ".ModDescription","onUpdate", listener.updateModDescription);
		listener.updateModDescription();
	end
	
	request.unregister = function(request, listener) 
		DB.removeHandler(request.node.getPath() .. ".description","onUpdate", listener.updateDescription);
		DB.removeHandler(request.node.getPath() .. ".identity","onUpdate", listener.updateIcon);
		DB.removeHandler(request.node.getPath() .. ".ADV","onUpdate", listener.updateADV);
		DB.removeHandler(request.node.getPath() .. ".DIS","onUpdate", listener.updateDIS);
		DB.removeHandler(request.node.getPath() .. ".HIDDEN","onUpdate", listener.updateHIDDEN);
		DB.removeHandler(request.node.getPath() .. ".DC","onUpdate", listener.updateDC);
		DB.removeHandler(request.node.getPath() .. ".ModValue","onUpdate", listener.updateModValue);
		DB.removeHandler(request.node.getPath() .. ".PLUS2","onUpdate", listener.updateModValue);
		DB.removeHandler(request.node.getPath() .. ".PLUS5","onUpdate", listener.updateModValue);
		DB.removeHandler(request.node.getPath() .. ".MINUS2","onUpdate", listener.updateModValue);
		DB.removeHandler(request.node.getPath() .. ".MINUS5","onUpdate", listener.updateModValue);		
		DB.removeHandler(request.node.getPath() .. ".ModDescription","onUpdate", listener.updateModDescription);
	end

	return request;
end

