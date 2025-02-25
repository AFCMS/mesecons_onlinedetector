core.log("action", "[mesecons_onlinedetector] loading...")

local S = core.get_translator(core.get_current_modname())
local F = core.formspec_escape

local has_mcl_core = core.get_modpath("mcl_core")

local table = table

local function get_detector_form(default)
	return table.concat({
		"formspec_version[4]",
		"size[8,3]",
		"field[0.25,0.75;7.5,0.75;name;" .. F(S("Online Detector")) .. ";" .. F(default) .. "]",
		"label[0.25,2.25;" .. F(S("Detecting (comma separated):")) .. " " .. F(default) .. "]"
	})
end

local playerlist = {}

core.register_on_joinplayer(function(player)
	playerlist[player:get_player_name()] = true
end)

core.register_on_leaveplayer(function(player)
	playerlist[player:get_player_name()] = nil
end)

---@param pos mt.Vector
---@param target string
local function update_detector_on(pos, target)
	local targets = string.split(target, ",")
	local any_online = false
	for _, t in ipairs(targets) do
		if playerlist[t] then
			any_online = true
			break
		end
	end
	if not any_online then
		core.swap_node(pos, { name = "mesecons_onlinedetector:online_detector_off" })
		mesecon.receptor_off(pos, mesecon.rules.alldirs)
	end
end

---@param pos mt.Vector
---@param target string
local function update_detector_off(pos, target)
	local targets = string.split(target, ",")
	local any_online = false
	for _, t in ipairs(targets) do
		if playerlist[t] then
			any_online = true
			break
		end
	end
	if any_online then
		core.swap_node(pos, { name = "mesecons_onlinedetector:online_detector_on" })
		mesecon.receptor_on(pos, mesecon.rules.alldirs)
	end
end

local nodedef = {
	description = S("Online Detector"),
	_doc_items_longdesc = S("Allows you to know if any player is connected in a given list."),
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		meta:set_string("formspec", get_detector_form(meta:get_string("name")))
	end,
}


local off_def = table.copy(nodedef)

off_def.tiles = { "mesecons_onlinedetector_online_detector_off.png" }

off_def.mesecons = {
	receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.alldirs,
	},
}

function off_def.on_receive_fields(pos, formname, fields, sender)
	if fields.name then
		local meta = core.get_meta(pos)
		meta:set_string("name", fields.name)
		meta:set_string("formspec", get_detector_form(fields.name))
		update_detector_off(pos, fields.name)
	end
end

--WARNING: the mesecon_onlinedetector group should NEVER assigned to another node, or you should expect the game to crash
if has_mcl_core then
	--off_def.groups = {cracky = 2, mesecon_onlinedetector = 1, mesecon_detector_off = 1, mesecon = 2}
	off_def.groups = { handy = 1, mesecon_onlinedetector = 1, mesecon_detector_off = 1, mesecon = 2 }
else
	off_def.groups = { cracky = 2, mesecon_onlinedetector = 1, mesecon_detector_off = 1, mesecon = 2 }
end

core.register_node("mesecons_onlinedetector:online_detector_off", off_def)


local on_def = table.copy(nodedef)

on_def.tiles = { "mesecons_onlinedetector_online_detector_on.png" }

on_def.drop = "mesecons_onlinedetector:online_detector_off"

on_def.mesecons = {
	receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.alldirs,
	},
}

function on_def.on_receive_fields(pos, formname, fields, sender)
	if core.is_protected(pos, sender:get_player_name()) then
		return
	end
	if fields.name then
		local meta = core.get_meta(pos)
		meta:set_string("name", fields.name)
		meta:set_string("formspec", get_detector_form(fields.name))
		update_detector_on(pos, fields.name)
	end
end

if has_mcl_core then
	--on_def.groups = {cracky = 2, mesecon_detector_off = 1, mesecon = 2}
	on_def.groups = { handy = 1, mesecon_detector_on = 1, mesecon = 2, not_in_creative_inventory = 1 }
else
	on_def.groups = { cracky = 2, mesecon_detector_on = 1, mesecon = 2, not_in_creative_inventory = 1 }
end

core.register_node("mesecons_onlinedetector:online_detector_on", on_def)

core.register_abm({
	label = "mesecons_onlinedetector:online_detector_off",
	nodenames = { "mesecons_onlinedetector:online_detector_off" },
	interval = 30,
	chance = 1,
	action = function(pos)
		update_detector_off(pos, core.get_meta(pos):get_string("name"))
	end,
})

core.register_abm({
	label = "mesecons_onlinedetector:online_detector_on",
	nodenames = { "mesecons_onlinedetector:online_detector_on" },
	interval = 30,
	chance = 1,
	action = function(pos)
		update_detector_on(pos, core.get_meta(pos):get_string("name"))
	end,
})

core.register_lbm({
	label = "Update onlinedetector state",
	name = "mesecons_onlinedetector:online_detector",
	nodenames = { "group:mesecon_onlinedetector" },
	run_at_every_load = true,
	action = function(pos, node)
		if node.name == "mesecons_onlinedetector:online_detector_off" then
			update_detector_off(pos, core.get_meta(pos):get_string("name"))
		else
			update_detector_on(pos, core.get_meta(pos):get_string("name"))
		end
	end,
})

if core.get_modpath("default") then
	core.register_craft({
		output = "mesecons_onlinedetector:online_detector_off",
		recipe = {
			{ "default:steel_ingot", "default:steel_ingot",                      "default:steel_ingot" },
			{ "default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot" },
			{ "default:stone",       "default:stone",                            "default:stone" },
		},
	})
elseif has_mcl_core then
	core.register_craft({
		output = "mesecons_onlinedetector:online_detector_off",
		recipe = {
			{ "mcl_core:iron_ingot", "mcl_core:iron_ingot",        "mcl_core:iron_ingot" },
			{ "mcl_core:iron_ingot", "mesecons:wire_00000000_off", "mcl_core:iron_ingot" },
			{ "mcl_core:stone",      "mcl_core:stone",             "mcl_core:stone" },
		},
	})
end

core.log("action", "[mesecons_onlinedetector] loaded succesfully")
