function meseportals.swap_portal_node(pos,name,dir)
	local node = core.get_node(pos)
	local meta = core.get_meta(pos)
	meta:set_string("dont_destroy","true")
	local meta0 = meta:to_table()
	node.name = name
	node.param2=dir
	core.set_node(pos,{name=name, param2=dir})
	meta:from_table(meta0)
	meta:set_string("dont_destroy","false")
end

minetest.register_node("meseportals:portal_collider",{
	drawtype = "airlike",
	groups = {not_in_creative_inventory=1},
	sunlight_propagates = true,
	can_dig = false,
	selection_box = {
	type = "fixed",
	fixed={0.0,0.0,0.0,0.0,0.0,0.0}},
})


function placeportalCollider(pos, pos1)
	if minetest.get_node(pos).name == "air" or minetest.registered_nodes[minetest.get_node(pos).name].buildable_to then
		core.set_node(pos,{name="meseportals:portal_collider"})
		local meta = minetest.get_meta(pos)
		meta:set_string("portal", minetest.pos_to_string(pos1))
		return true
	else
		return false
	end
end

local function placeportal(player,pos)
	if minetest.check_player_privs(player, {msp_unlimited=true}) or meseportals.maxPlayerPortals > #meseportals_network[player:get_player_name()] then
		local dir = minetest.dir_to_facedir(player:get_look_dir())
		local pos1 = vector.new(pos)
		local hadRoom = true
		if dir == 1
		or dir == 3 then
			pos1.z=pos1.z+2
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y+1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y+1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y+1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.z=pos1.z-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.z=pos1.z-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.z=pos1.z-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.z=pos1.z-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			placeportalCollider(pos1, pos)
			pos1.z=pos1.z+1
			placeportalCollider(pos1, pos)
			pos1.z=pos1.z+1
			placeportalCollider(pos1, pos)
			pos1.z=pos1.z+1
			placeportalCollider(pos1, pos)
			pos1.z=pos1.z+1
			placeportalCollider(pos1, pos)
		else
			pos1.x=pos1.x+2
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y+1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y+1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y+1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.x=pos1.x-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.x=pos1.x-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.x=pos1.x-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.x=pos1.x-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			hadRoom = hadRoom and placeportalCollider(pos1, pos)
			pos1.y=pos1.y-1
			placeportalCollider(pos1, pos)
			pos1.x=pos1.x+1
			placeportalCollider(pos1, pos)
			pos1.x=pos1.x+1
			placeportalCollider(pos1, pos)
			pos1.x=pos1.x+1
			placeportalCollider(pos1, pos)
			pos1.x=pos1.x+1
			placeportalCollider(pos1, pos)
		end
		if hadRoom then
			meseportals.swap_portal_node(pos,"meseportals:portalnode_off",dir)
			local player_name = player:get_player_name()
			meseportals.registerPortal(player_name, pos, dir)
			return true
		else
			minetest.remove_node(pos)
			minetest.chat_send_player(player:get_player_name(), "Not enough room!")
		end
	else
		minetest.chat_send_player(player:get_player_name(), "You have reached the maximum allowed number of portals!")
		core.remove_node(pos)
	end
end

function meseportals.activatePortal(pos)
	local portal = meseportals.findPortal(pos)
	if meseportals.findPortal(pos) then
		portal["updateme"] = true
		meseportals.save_data(portal["owner"])
	end
end

function meseportals.deactivatePortal(pos)
	local portal = meseportals.findPortal(pos)
	if portal then
		portal["destination"] = nil
		portal["destination_description"] = nil
		portal["destination_dir"] = nil
		portal["updateme"] = true
		meseportals.save_data(portal["owner"])
	end
end



local function removeportal(pos)
	if (meseportals.findPortal(pos) ~= nil) then
		local meta = core.get_meta(pos)
		if meta:get_string("dont_destroy") == "true" then
			-- when swapping it
			return
		end
		if meseportals.findPortal(pos)["destination"] then
			meseportals.deactivatePortal(meseportals.findPortal(pos)["destination"])
		end
		meseportals.unregisterPortal(pos)
		minetest.add_item(pos, {name="meseportals:portalnode_off", count=1, wear=0, metadata=""})
	end
end

local function portalCanDig(pos, player)
	local isAdmin = minetest.check_player_privs(player, {msp_admin=true})
	if meseportals.allowPrivatePortals and meseportals.findPortal(pos) ~= nil and not isAdmin then --Anyone can clean up a busted portal
		if player:get_player_name() ~= meseportals.findPortal(pos)["owner"] then
			minetest.chat_send_player(player:get_player_name(), "This portal belongs to " ..meseportals.findPortal(pos)["owner"] .."!")
		end
		return player:get_player_name() == meseportals.findPortal(pos)["owner"]
	else
		return true
	end
end

local msp_selection_box = {
	type = "fixed",
	fixed={{-2.5,-1.5,-0.2,2.5,3.5,0.2},},
}

local msp_groups = {dig_immediate=3,oddly_breakable_by_hand=1,not_in_creative_inventory=1}
local msp_groups1 = {dig_immediate=3,oddly_breakable_by_hand=1}





minetest.register_node("meseportals:portalnode_on",{
	tiles = {
		--{name = "gray.png"},
		--{
		--name = "puddle_animated.png",
		--animation = {
		--	type = "vertical_frames",
		--	aspect_w = 16,
		--	aspect_h = 16,
		--	length = 2.0,
		--	},
		--},
		{name = "meseportal_0004.png",--Portal
		animation = {
			type = "vertical_frames",
			length = 1.0,
			},
		},
		{name = "meseportal_0003.png", --Buttons
		animation = {
			type = "vertical_frames",
			},
		},
		{name = "meseportal_0003.png", --Cables
		animation = {
			type = "vertical_frames",
			},
		},
		{name = "meseportal_0003.png", --Coil
		animation = {
			type = "vertical_frames",
			},
		},
		{name = "meseportal_0001.png"}, --Frame
	},
	drawtype = "mesh",
	mesh = "meseportal.obj",
	visual_scale = 5.0,
	groups = msp_groups,
	drop = {name="meseportals:portalnode_off", count=1, wear=0, metadata=""},
	paramtype2 = "facedir",
	paramtype = "light",
	light_source = 5,
	selection_box = msp_selection_box,
	walkable = false,
	can_dig = portalCanDig,
	on_destruct = removeportal,
	on_rightclick=meseportals.portalFormspecHandler,
})


minetest.register_node("meseportals:portalnode_off",{
	description = "Mese Portal",
	inventory_image = "meseportal.png",
	wield_image = "meseportal.png",
	tiles = {
		{name = "meseportal_null.png"},
		{name = "meseportal_0002.png"},
		{name = "meseportal_0002.png"},
		{name = "meseportal_0002.png"},
		{name = "meseportal_0001.png"},
	},
	groups = msp_groups1,
	paramtype2 = "facedir",
	paramtype = "light",
	drawtype = "mesh",
	drop = {name="meseportals:portalnode_off", count=1, wear=0, metadata=""},
	mesh = "meseportal.obj",
	visual_scale = 5.0,
	selection_box = msp_selection_box,
	walkable = false,
	can_dig = portalCanDig,
	on_destruct = removeportal,
	on_place = function(itemstack, placer, pointed_thing)
		if not minetest.is_protected(pos, placer:get_player_name()) then
			local pos = pointed_thing.above
			local meta = minetest.get_meta(pos)
			minetest.rotate_node(itemstack, placer, pointed_thing) --This handles creative inventory correctly. Aside from that, it's basically useless.
			local node = minetest.get_node(pos)
			node.param2 = minetest.dir_to_facedir(placer:get_look_dir())
			meta:set_string("dont_destroy","true")
				minetest.set_node(pos, node)
			meta:set_string("dont_destroy","false")
			placeportal(placer,pos)
			return itemstack
		end
	end,
	on_rightclick=meseportals.portalFormspecHandler,
	
})


local usePortalController = function(pos, clicker)
	if meseportals.findPortal(pos) then
		meseportals.portalFormspecHandler(pos, nil, clicker, nil)
	else
		minetest.chat_send_player(clicker:get_player_name(), "The linked portal was moved or destroyed. Link this controller to a new portal.")
	end
end

minetest.register_node("meseportals:linked_portal_controller", {
	description = "Linked Portal Controller",
	inventory_image = "meseportal_controller_inventory.png",
	wield_image = "meseportal_controller_inventory.png",
	tiles = {{name = "meseportal_controller.png"}},
	drawtype = "mesh",
	paramtype = "light",
	paramtype2 = "facedir",
	mesh = "meseportal_controller.obj",
	groups = msp_groups,
	stack_max = 1,
	walkable = true,
	light_source = 5,
	selection_box = {
		type = "fixed",
		fixed={{-0.425,-0.325,0.5,0.45,0.325,0.425},},
	},
	collision_box = {
		type = "fixed",
		fixed={{-0.425,-0.325,0.5,0.45,0.325,0.425},},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local rightClicked = minetest.get_node(pointed_thing.under).name
		if rightClicked == "meseportals:portalnode_on" or rightClicked == "meseportals:portalnode_off" then
			local portal = meseportals.findPortal(pointed_thing.under)
			if portal then
				if portal["type"] == "public" or placer:get_player_name() == portal["owner"] or minetest.check_player_privs(placer, {msp_admin=true}) or not meseportals.allowPrivatePortals then
					minetest.chat_send_player(placer:get_player_name(), "Controller linked to "..portal["description"])
					itemstack:get_meta():set_string("portal", minetest.pos_to_string(pointed_thing.under))
					itemstack:get_meta():set_string("description", "Linked Portal Controller ["..portal["description"].."]")
					return itemstack
				else
					minetest.chat_send_player(placer:get_player_name(), portal["owner"] .." has set this portal to private.")
				end
			else
				minetest.chat_send_player(placer:get_player_name(), "This portal is broken.")
			end
		else
			minetest.rotate_node(itemstack, placer, pointed_thing)
			core.set_node(pointed_thing.above, {name=minetest.get_node(pointed_thing.above).name, param2=minetest.dir_to_facedir(placer:get_look_dir())})
			local meta = minetest.get_meta(pointed_thing.above)
			meta:set_string("portal", itemstack:get_meta():get_string("portal"))
			return itemstack
		end
	end,
	on_dig = function(pos, node, player)
		minetest.add_item(pos, {name="meseportals:unlinked_portal_controller", count=1, wear=0, metadata=""})
		minetest.remove_node(pos)
	end,
	on_use = function(itemstack, user)
		local pos1 = minetest.string_to_pos(itemstack:get_meta():get_string("portal"))
		usePortalController(pos1, user)
	end,
	on_rightclick = function(pos, node, clicker)
		local pos1 = minetest.string_to_pos(minetest.get_meta(pos):get_string("portal"))
		usePortalController(pos1, clicker)
	end
})

minetest.register_node("meseportals:unlinked_portal_controller", {
	description = "Unlinked Portal Controller",
	inventory_image = "meseportal_controller_inventory_unlinked.png",
	wield_image = "meseportal_controller_inventory_unlinked.png",
	tiles = {{name = "meseportal_controller_unlinked.png"}},
	drawtype = "mesh",
	paramtype = "light",
	paramtype2 = "facedir",
	mesh = "meseportal_controller.obj",
	groups = msp_groups1,
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed={{-0.425,-0.325,0.5,0.45,0.325,0.425},},
	},
	collision_box = {
		type = "fixed",
		fixed={{-0.425,-0.325,0.5,0.45,0.325,0.425},},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local rightClicked = minetest.get_node(pointed_thing.under).name
		if rightClicked == "meseportals:portalnode_on" or rightClicked == "meseportals:portalnode_off" then
			local portal = meseportals.findPortal(pointed_thing.under)
			if portal then
				if portal["type"] == "public" or placer:get_player_name() == portal["owner"] or minetest.check_player_privs(placer, {msp_admin=true}) then
					minetest.chat_send_player(placer:get_player_name(), "Controller linked to "..portal["description"])
					local newItem = itemstack:take_item()
					local inv = placer:get_inventory()
					newItem:set_name("meseportals:linked_portal_controller")
					newItem:get_meta():set_string("portal", minetest.pos_to_string(pointed_thing.under))
					newItem:get_meta():set_string("description", "Linked Portal Controller ["..portal["description"].."]")
					
					if inv:add_item("main", newItem):get_count() > 0 then --Not enough inventory space, drop on the ground
						minetest.add_item(placer:get_pos(), newItem)
					end
					return itemstack
				else
					minetest.chat_send_player(placer:get_player_name(), portal["owner"] .." has set this portal to private.")
				end
			else
				minetest.chat_send_player(placer:get_player_name(), "This portal is broken.")
			end
		else
			minetest.rotate_node(itemstack, placer, pointed_thing)
			core.set_node(pointed_thing.above, {name=minetest.get_node(pointed_thing.above).name, param2=minetest.dir_to_facedir(placer:get_look_dir())})
			local meta = minetest.get_meta(pointed_thing.above)
			meta:set_string("portal", itemstack:get_meta():get_string("portal"))
			return itemstack
		end
	end,
	on_dig = function(pos, node, player)
		local meta = minetest.get_meta(pos)
		local item = {name="meseportals:unlinked_portal_controller", count=1, wear=0, metadata=""}
		minetest.add_item(pos, item)
		minetest.remove_node(pos)
	end,
	on_use = function(_, user)
		minetest.chat_send_player(user:get_player_name(), "This controller is not linked. Link this controller to a portal by right-clicking the portal.")
	end,
	on_rightclick = function(_, __, user)
		minetest.chat_send_player(user:get_player_name(), "This controller is not linked. Link this controller to a portal by right-clicking the portal.")
	end,
})

minetest.register_craftitem("meseportals:portal_segment", {
	description = "Encased Mesenetic Field Coil",
	inventory_image = "meseportal_portal_part.png",
	wield_image = "meseportal_portal_part.png",
})

minetest.register_craftitem("meseportals:tesseract_crystal", {
	description = "Tesseract Crystal",
	inventory_image = "meseportal_tesseract.png",
	wield_image = "meseportal_tesseract.png",
})