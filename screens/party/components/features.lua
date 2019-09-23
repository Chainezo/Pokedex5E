local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local _feats = require "pokedex.feats"
local gooey = require "gooey.gooey"
local party_utils = require "screens.party.utils"
local scrollhandler = require "screens.party.components.scrollhandler"

local M = {}

local active_ability_lists = {[1]={}, [2]={}}
local active_page
local start_position
local function setup_entry(nodes, name, desc, p, i)
	local root_node
	local name_node
	local desc_node
	local background_node
	
	root_node = gui.clone(nodes["pokemon/ability/background"])
	name_node = gui.clone(nodes["pokemon/ability/name"])
	desc_node = gui.clone(nodes["pokemon/ability/description"])
	background_node = gui.clone(nodes["pokemon/ability/background"])
	gui.set_parent(name_node, root_node, false)
	gui.set_parent(desc_node, root_node, false)
	gui.set_inherit_alpha(name_node, false)
	gui.set_inherit_alpha(desc_node, false)
	gui.set_enabled(root_node, true)

	gui.set_position(root_node, p)
	gui.set_text(name_node, name:upper())
	gui.set_text(desc_node, desc)
	local desc_height, name_height = gui.get_text_metrics_from_node(desc_node).height, gui.get_text_metrics_from_node(name_node).height
	local size = gui.get_size(background_node)
	size.y = desc_height + name_height
	gui.set_size(background_node, size)
	local n = gui.get_position(name_node, p)
	local d = gui.get_position(desc_node, p)
	n.y = size.y * 0.55
	d.y = n.y - name_height * 1.2

	size.y = size.y + 5
	gui.set_size(root_node, size)

	p.y = p.y - desc_height - name_height - 16
	return root_node
end

local function setup_features(nodes, pokemon)
	local function _setup(list, name, desc, index, p)
		local root_node = setup_entry(nodes, name, desc, p, index)
		local id = party_utils.set_id(root_node)
		table.insert(list.data, id)
		
	end

	local p = vmath.vector3() --start_position
	local index = 0
	local list = {}
	list.data = {}
	list.id = _pokemon.get_id(pokemon)

	local abilities = _pokemon.get_abilities(pokemon)
	local feats = _pokemon.get_feats(pokemon)
	if next(abilities) then
		for i, name in pairs(abilities) do
			index = index + 1
			local desc = pokedex.get_ability_description(name)
			_setup(list, name, desc, index, p)
		end
		table.insert(active_ability_lists[active_page], list)
	end
	if next(feats) then
		for i, name in pairs(feats) do
			index = index + 1
			local desc = _feats.get_feat_description(name)
			_setup(list, name, desc, index, p)
		end
		table.insert(active_ability_lists[active_page], list)
	end
	scrollhandler.set_max(index, p.y)
end

function M.clear(index)
	for a, list in pairs(active_ability_lists[index]) do
		for b, data in pairs(list.data) do
			gui.delete_node(gui.get_node(data))
		end
	end
	active_ability_lists[index] = {}
end

function M.create(nodes, pokemon, index)
	active_ability_lists[index] = {}
	active_page = index
	gui.set_enabled(nodes["pokemon/ability/background"], false)
	start_position = gui.get_position(nodes["pokemon/ability/background"])
	setup_features(nodes, pokemon)
end


return M