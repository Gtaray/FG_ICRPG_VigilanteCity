-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Set the displays to what should be shown
	setActiveVisible();
	setTargetingVisible();
	setEffectsVisible();
	setChunksVisible();

	-- Acquire token reference, if any
	linkToken();
	
	-- Update the displays
	onLinkChanged();
	onFactionChanged();
	onHealthChanged();
	onStunChanged();
	
	-- Register the deletion menu item for the host
	registerMenuItem(Interface.getString("list_menu_deleteitem"), "delete", 6);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete", 6, 7);
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
		name.setFont("sheetlabel");
		nonid_name.setFont("sheetlabel");
		
		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
	else
		name.setFont("sheettext");
		nonid_name.setFont("sheettext");
		
		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function onHealthChanged()
	local nodeEntry = getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeEntry);
	local _,sStatus,sColor = HealthManager.getHealthInfo(rActor, "hp");

	wounds.setColor(sColor);

	local sClass,_ = link.getValue();
	if sClass ~= "charsheet" then
		idelete.setVisibility((sStatus == ActorHealthManager.STATUS_DYING) or (sStatus == ActorHealthManager.STATUS_DEAD));
	end
end

function onStunChanged()
	local nodeEntry = getDatabaseNode();
	local rActor = ActorManager.resolveActor(nodeEntry);
	local _,sStatus,sColor = HealthManager.getHealthInfo(rActor, "stun");

	status.setValue(sStatus);
	stundmg.setColor(sColor);

	local sClass,_ = link.getValue();
	if sClass ~= "charsheet" then
		idelete.setVisibility((sStatus == "Stunned"));
	end
end

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		TokenManager.linkToken(getDatabaseNode(), imageinstance);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	local node = getDatabaseNode();
	if not node then
		close();
		return;
	end
	
	-- Remember node name
	local sNode = node.getNodeName();
	
	-- Clear any effects and wounds first, so that rolls aren't triggered when initiative advanced
	effects.reset(false);
	
	-- Move to the next actor, if this CT entry is active
	if DB.getValue(node, "active", 0) == 1 then
		CombatManager.nextActor();
	end

	-- Delete the database node and close the window
	local cList = windowlist;
	node.delete();

	-- Update list information (global subsection toggles)
	cList.onVisibilityToggle();
	cList.onEntrySectionToggle();
end

function onLinkChanged()
	-- If a PC, then set up the links to the char sheet
	local sClass, sRecord = link.getValue();
	if sClass == "charsheet" then
		linkPCFields();
		name.setLine(false);
	end
	onIDChanged();
end

function onIDChanged()
	local nodeRecord = getDatabaseNode();
	local sClass = DB.getValue(nodeRecord, "link", "", "");
	if sClass == "npc" then
		local bID = LibraryData.getIDState("npc", nodeRecord, true);
		name.setVisible(bID);
		nonid_name.setVisible(not bID);
		isidentified.setVisible(true);
	else
		name.setVisible(true);
		nonid_name.setVisible(false);
		isidentified.setVisible(false);
	end
end

function onFactionChanged()
	-- Update the entry frame
	updateDisplay();

	-- If not a friend, then show visibility toggle
	if friendfoe.getStringValue() == "friend" then
		tokenvis.setVisible(false);
	else
		tokenvis.setVisible(true);
	end
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true);
		--hp.setLink(nodeChar.createChild("health.hp", "number"), true);
		-- defence.setLink(nodeChar.createChild("defence", "number"), true);
		wounds.setLink(nodeChar.createChild("health.wounds", "number"), false);
		stundmg.setLink(nodeChar.createChild("health.stundmg", "number"), false);
	end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setTargetingVisible()
	local v = false;
	if activatetargeting.getValue() == 1 then
		v = true;
	end

	targetingicon.setVisible(v);
	sub_targeting.setVisible(v);
	frame_targeting.setVisible(v);
	target_summary.onTargetsChanged();
end

function setActiveVisible()
	local v = false;
	-- if activateactive.getValue() == 1 then
	-- 	v = true;
	-- end

	local sClass, sRecord = link.getValue();
	local bNPC = (sClass ~= "charsheet");
	if bNPC and activateactive.getValue() == 1 then
		v = true;
	end

	actionsicon.setVisible(v);
	sub_actions.setVisible(v);
	frame_actions.setVisible(v);
end

function setChunksVisible()
	local v = false;

	local sClass, sRecord = link.getValue();
	local bNPC = (sClass ~= "charsheet");
	if bNPC and activatechunks.getValue() == 1 then
		v = true;
	end

	chunksicon.setVisible(v);
	sub_chunks.setVisible(v);
	frame_chunks.setVisible(v);
end

function setEffectsVisible()
	local v = false;
	if activateeffects.getValue() == 1 then
		v = true;
	end
	
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	effects_iadd.setVisible(v);
	for _,w in pairs(effects.getWindows()) do
		w.idelete.setValue(0);
	end

	frame_effects.setVisible(v);

	effect_summary.onEffectsChanged();
end
