
minetest.register_abm({
	nodenames = {"meseportals:portal_collider"},
	interval = 1,
	chance = 1,
	action = function(pos) 
		local portalpos = minetest.string_to_pos(minetest.get_meta(pos):get_string("portal"))
		if portalpos then
			local nodeName = minetest.get_node(portalpos).name
			if nodeName ~= "ignore" then --If the portal is on the edge of the loaded world, wait to update
				if nodeName ~= "meseportals:portalnode_on" and nodeName ~= "meseportals:portalnode_off" then
					minetest.remove_node(pos)
				end
			end
		end
	end
})


minetest.register_abm({
	nodenames = {"meseportals:portalnode_on", "meseportals:portalnode_off"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local current_portal = meseportals.findPortal(pos)
		if current_portal then
			if current_portal["updateme"] then
				if current_portal["destination"] == nil then
					if minetest.get_node(pos).name ~= "meseportals:portalnode_off" then
						minetest.sound_play("meseportal_close", {pos = pos, max_hear_distance = 72,})
					end
					meseportals.swap_portal_node(pos,"meseportals:portalnode_off",current_portal["dir"])
				else
					meseportals.swap_portal_node(pos,"meseportals:portalnode_on",current_portal["dir"])
					minetest.sound_play("meseportal_open", {pos = pos, max_hear_distance = 72,})
				end
				current_portal["updateme"] = false
				meseportals.save_data(current_portal["owner"])
			end
			
			local meta = minetest.get_meta(pos)
			if current_portal["type"]=="private" and meseportals.allowPrivatePortals then 
				infotext="Private Portal"
			else
				infotext=(current_portal["description"])
				if meseportals.allowPrivatePortals then 
					infotext=infotext.." (Public Portal)\n".."Owned by "..current_portal["owner"]
				end
				local dest_portal = meseportals.findPortal(current_portal["destination"])
				if dest_portal then
					if dest_portal["type"] == "public" or not meseportals.allowPrivatePortals then
						infotext=infotext.."\nDestination: " ..current_portal["destination_description"] .." ("..current_portal["destination"].x..","..current_portal["destination"].y..","..current_portal["destination"].z..") "
					else
						infotext=infotext.."\nDestination: Private Portal"
					end
				end
			end
			meta:set_string("infotext",infotext)
		end
	end
})


minetest.register_globalstep(function(dtime)
	for _, skip in pairs(meseportals_network) do
		for __, portal in pairs(skip) do
			if portal ~= nil then
				local pos = portal["pos"]
				local dest_portal=meseportals.findPortal(portal["destination"])
				if dest_portal then
					local pos1 = vector.new(dest_portal["pos"])
					if dest_portal["destination"] then 
						for _,object in pairs(core.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 2)) do
							local dir = portal.dir
							local dir1 = portal.destination_dir
							local hdiff = nil
							if dir == 1
							or dir == 3 then
								if math.floor(object:get_pos().x + 0.5) == pos.x then
									hdiff = (object:get_pos().z - pos.z)
								end
							else
								if math.floor(object:get_pos().z + 0.5) == pos.z then
									hdiff = (object:get_pos().x - pos.x)
								end
							end
							if hdiff then
								pos1.y = pos1.y + (object:get_pos().y - pos.y) + 0.2
								local dest_angle = ((dir1 - 2) * -90) 
								
								if object:get_look_horizontal() then
									dest_angle = (math.deg(object:get_look_yaw()) + 90) + ((dir1 - dir) * -90)
								end
								
								if dir == 1 or dir == 2 then
									hdiff = -hdiff
								end
								--hdiff = -1
								if dir1 == 0 then --ALL CORRECT
									pos1.z = pos1.z-1.25
									pos1.x = pos1.x - hdiff
								elseif dir1 == 1 then
									pos1.x = pos1.x-1.25
									pos1.z = pos1.z + hdiff
								elseif dir1 == 2 then
									pos1.z=pos1.z+1.25
									pos1.x = pos1.x + hdiff
								elseif dir1 == 3 then
									pos1.x = pos1.x+1.25
									pos1.z = pos1.z - hdiff
								end
								object:moveto(pos1,false)
								object:set_look_horizontal(math.rad(dest_angle))
								if object:is_player() then
									minetest.sound_play("meseportal_warp", {to_player=object:get_player_name(), gain=1.0, max_hear_distance=15})
								end
								minetest.sound_play("meseportal_warp", {pos = pos, gain=1.0, max_hear_distance=15})
								minetest.sound_play("meseportal_warp", {pos = pos1, gain=1.0, max_hear_distance=15})
							end
						end
					end
				else 
					if portal["destination"] then --Destination portal broke/vanished
						meseportals.deactivatePortal(pos)
					end
				end
				
			end
		end
	end
end)