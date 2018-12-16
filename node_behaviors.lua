
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
		if not current_portal then
			minetest.remove_node(pos)
			return
		end
		
	end
})


minetest.register_globalstep(function(dtime)
	local meta, infotext, pos1, pos, dir, dir1, hdiff, dest_portal
	for _, skip in pairs(meseportals_network) do
		for __, portal in pairs(skip) do
			if portal then
				pos = portal["pos"]
				--Update node
				if portal["updateme"] and minetest.get_node_or_nil(pos) then
					if portal["destination"] == nil then
						if minetest.get_node(pos).name ~= "meseportals:portalnode_off" then
							minetest.sound_play("meseportal_close", {pos = pos, gain=0.6, max_hear_distance = 40})
						end
						meseportals.swap_portal_node(pos,"meseportals:portalnode_off",portal["dir"])
					else
						meseportals.swap_portal_node(pos,"meseportals:portalnode_on",portal["dir"])
						minetest.sound_play("meseportal_open", {pos = pos, gain=0.6, max_hear_distance = 40})
					end
					portal["updateme"] = false
					meseportals.save_data(portal["owner"])
					meta = minetest.get_meta(pos)
					if portal["type"]=="private" and meseportals.allowPrivatePortals then 
						infotext="Private Portal"
					else
						infotext=(portal["description"])
						if meseportals.allowPrivatePortals then 
							infotext=infotext.." (Public Portal)\n".."Owned by "..portal["owner"]
						end
						dest_portal = meseportals.findPortal(portal["destination"])
						if dest_portal then
							if dest_portal["type"] == "public" or not meseportals.allowPrivatePortals then
								infotext=infotext.."\nDestination: " ..portal["destination_description"] .." ("..portal["destination"].x..","..portal["destination"].y..","..portal["destination"].z..") "
							else
								infotext=infotext.."\nDestination: Private Portal"
							end
						end
					end
					meta:set_string("infotext",infotext)
				end
				
				
				
				--Teleport players
				dest_portal=meseportals.findPortal(portal["destination"])
				if dest_portal then
					pos1 = vector.new(dest_portal["pos"])
					if dest_portal["destination"] then 
						for _,object in pairs(core.get_objects_inside_radius({x = pos.x, y = pos.y, z = pos.z}, 2)) do
							dir = portal.dir
							dir1 = portal.destination_dir
							hdiff = nil
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
									dest_angle = (math.deg(object:get_look_horizontal()) + 180) + ((dir1 - dir) * -90)
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
									minetest.sound_play("meseportal_warp", {to_player=object:get_player_name(), gain=0.6, max_hear_distance=15})
								end
								minetest.sound_play("meseportal_warp", {pos = pos, gain=0.6, max_hear_distance=15})
								minetest.sound_play("meseportal_warp", {pos = pos1, gain=0.6, max_hear_distance=15})
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