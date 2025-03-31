local OOB_MSGTYPE_APPLYPIZZA = "applyPizza";

PizzaCrustTypes = {"cauliflower","granite","stuffed", "deep-dish", "thin", "boot leather"};
Toppings1 = {"ear cheese","pineapple","urinal cakes","displacer plums","ironleaf buds" };
Toppings2 = {"magic beans","corpse flower","ham","lava oil","radishes"};

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYPIZZA,handlePizza)
end

function applyPizza(sText)
	-- show to GM
	Comm.addChatMessage({icon = "pizza_chat", text = "Adaptive Pizza Request Interactive Logic v1\nYou sent a request for a "..sText});

	-- for showing to clients
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYPIZZA;
	msgOOB.text = "Adaptive Pizza Request Interactive Logic v1\nThe GM has requested a precisely ";
	msgOOB.text = msgOOB.text..tostring(3+math.random(200)/10).."-inch pizza ";
	msgOOB.text = msgOOB.text.."with a ".. PizzaCrustTypes[ math.random( #PizzaCrustTypes ) ].. " crust ";
	msgOOB.text = msgOOB.text.."topped with "..Toppings1[ math.random( #Toppings1 ) ].." and ".. Toppings2[ math.random( #Toppings2 )] ..". Please contact the nearest open-faced sandwich shop for delivery."
	Comm.deliverOOBMessage(msgOOB);
end

function handlePizza(msgOOB)
	if not Session.IsHost then
		Comm.addChatMessage({icon = "pizza_chat", text = msgOOB.text})
	end
end