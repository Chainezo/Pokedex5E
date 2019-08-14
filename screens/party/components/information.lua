local _pokemon = require "pokedex.pokemon"
local pokedex = require "pokedex.pokedex"
local storage = require "pokedex.storage"
local items = require "pokedex.items"
local party_utils = require "screens.party.utils"
local gooey = require "gooey.gooey"
local utils = require "utils.utils"
local gui_utils = require "utils.gui"
local gui_colors = require "utils.gui_colors"
local monarch = require "monarch.monarch"

local M = {}
local active = {}
local touching = false
local _action = vmath.vector3(0)

local number_map = {[0.125]="1/8", [0.25]="1/4", [0.5]="1/2"}

local item_button
local active_pokemon

local function setup_held_item(nodes, pokemon)
	local item = _pokemon.get_held_item(pokemon)
	local info_root = nodes["pokemon/more_info"]
	local info_root_pos = gui.get_position(info_root)
	local move_bg = nodes["pokemon/tab_bg_1"]
	local ability_bg = nodes["pokemon/tab_stencil_2"]
	local info_bg = nodes["pokemon/tab_bg_3"]
	local move_size = gui.get_size(move_bg)
	local ability_size = gui.get_size(ability_bg)
	local info_size = gui.get_size(info_bg)
	if item then
		local distance = 54
		gui.set_text(nodes["pokemon/txt_held_item"], "HOLDING: " .. item:upper())
		gui.set_enabled(nodes["pokemon/held_item"], true)
		move_size.y = 590 - distance
		ability_size.y = 600 - distance
		info_size.y = 590- distance
		info_root_pos.y = -420 - distance
		item_button = party_utils.set_id(nodes["pokemon/held_item"])
	else
		item_button = nil
		move_size.y = 590
		ability_size.y = 600
		info_size.y = 590
		info_root_pos.y = -420
		gui.set_enabled(nodes["pokemon/held_item"], false)
	end
	gui.set_size(move_bg, move_size)
	gui.set_size(ability_bg, ability_size)
	gui.set_size(info_bg, info_size)
	gui_utils.scale_fit_node_with_stretch(move_bg)
	gui_utils.scale_fit_node_with_stretch(ability_bg)
	gui_utils.scale_fit_node_with_stretch(info_bg)
	gui.set_position(info_root, info_root_pos)
end

local function setup_main_information(nodes, pokemon)
	local speed, stype = _pokemon.get_speed_of_type(pokemon)
	local nickname = _pokemon.get_nickname(pokemon)
	local species = _pokemon.get_current_species(pokemon)
	nickname = nickname or species:upper()

	if _pokemon.is_shiny(pokemon) then
		gui.play_particlefx(nodes["pokemon/shiny_bg"])
		gui.play_particlefx(nodes["pokemon/shiny_fg"])
		gui.play_particlefx(nodes["pokemon/shiny_star_bg"])
	else
		
	end
	local pokemon_sprite, texture = _pokemon.get_sprite(pokemon)
	gui.set_texture(nodes["pokemon/pokemon_sprite"], texture)
	if pokemon_sprite then
		gui.play_flipbook(nodes["pokemon/pokemon_sprite"], pokemon_sprite)
	end

	gui.set_text(nodes["pokemon/index"], string.format("#%03d %s", _pokemon.get_index_number(pokemon), species))
	gui.set_text(nodes["pokemon/species"], nickname)
	gui.set_text(nodes["pokemon/level"], "Lv. " ..  _pokemon.get_current_level(pokemon))
	gui.set_text(nodes["pokemon/ac"], "AC: " .. _pokemon.get_AC(pokemon))
	local vul = nodes["pokemon/vulnerabilities"]
	local imm = nodes["pokemon/immunities"]
	local res = nodes["pokemon/resistances"]
	gui.set_text(vul, party_utils.join_table("Vulnerabilities: ", _pokemon.get_vulnerabilities(pokemon), ", "))
	gui.set_text(res, party_utils.join_table("Resistances: ", _pokemon.get_resistances(pokemon), ", "))
	gui.set_text(imm, party_utils.join_table("Immunities: ", _pokemon.get_immunities(pokemon), ", "))

	gui_utils.scale_text_to_fit_size(nodes["pokemon/species"])
end


function M.refresh(pokemon_id)
	local pokemon = storage.get_copy(pokemon_id)
	gui.set_text(active["pokemon/traits/txt_catch"], _pokemon.get_catch_rate(pokemon))
	local st_attributes = _pokemon.get_saving_throw_modifier(pokemon)
	for i, stat in pairs({"STR", "DEX", "CON", "INT", "WIS", "CHA"}) do
		local save_node = "pokemon/traits/txt_" .. stat:lower() .. "_save"
		gui.set_text(active[save_node], party_utils.add_operation(st_attributes[stat]))
	end	
end


local function setup_info_tab(nodes, pokemon)
	local abilities_string1 = ""
	local saving_throw_string1 = ""
	local abilities_string2 = ""
	local saving_throw_string2 = ""

	local st_attributes = _pokemon.get_saving_throw_modifier(pokemon)
	local total_attributes = _pokemon.get_attributes(pokemon)
	for i, stat in pairs({"STR", "DEX", "CON", "INT", "WIS", "CHA"}) do
		local mod_node = "pokemon/traits/txt_" .. stat:lower() .. "_mod"
		local score_node = "pokemon/traits/txt_" .. stat:lower() .. "_score"
		local save_node = "pokemon/traits/txt_" .. stat:lower() .. "_save"

		gui.set_text(nodes[mod_node], party_utils.to_mod(total_attributes[stat]))
		gui.set_text(nodes[save_node], party_utils.add_operation(st_attributes[stat]))
		gui.set_text(nodes[score_node], total_attributes[stat])
	end	

	local skill_string = ""
	for _, skill in pairs(_pokemon.get_skills(pokemon)) do
		skill_string = skill_string .. "• " .. skill .. "\n"
	end
	gui.set_text(nodes["pokemon/traits/txt_skills"], skill_string)

	local sr = pokedex.get_pokemon_SR(_pokemon.get_current_species(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_sr"], number_map[sr] or sr)

	gui.set_text(nodes["pokemon/traits/txt_nature"], _pokemon.get_nature(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_stab"], _pokemon.get_STAB_bonus(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_prof"], _pokemon.get_proficency_bonus(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_type"], table.concat(_pokemon.get_type(pokemon), "/"))
	gui.set_text(nodes["pokemon/traits/txt_exp"], _pokemon.get_pokemon_exp_worth(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_catch"], _pokemon.get_catch_rate(pokemon))
	gui.set_text(nodes["pokemon/traits/txt_hitdice"], "d" .. _pokemon.get_hit_dice(pokemon))
	
	for name, amount in pairs(_pokemon.get_all_speed(pokemon)) do
		gui.set_text(nodes["pokemon/traits/txt_" .. name:lower()], amount==0 and "-" or amount .. "ft")
	end

	gui.set_text(nodes["pokemon/traits/txt_darkvision"], "-")
	gui.set_text(nodes["pokemon/traits/txt_tremorsense"], "-")
	gui.set_text(nodes["pokemon/traits/txt_truesight"], "-")
	gui.set_text(nodes["pokemon/traits/txt_blindsight"], "-")
	local senses = _pokemon.get_senses(pokemon)
	if next(senses) ~= nil then
		for _, str in pairs(senses) do
			local split = utils.split(str)
			gui.set_text(nodes["pokemon/traits/txt_" .. split[1]:lower()], split[2])
		end
	end
end

function M.on_input(action_id, action)
	if not active then
		return
	end
	if action.pressed then
		_action.x = action.x
		_action.y = action.y
		touching = true
	elseif action.released then
		touching = false
	end
	
	if active["pokemon/tab_bg_3"] and gui.pick_node(active["pokemon/tab_bg_3"], action.x, action.y) and touching then
		local max_scroll = math.abs(gui.get_position(active["pokemon/traits/scroll_stop"]).y) - gui.get_size(active["pokemon/tab_bg_3"]).y
		local p = gui.get_position(active["pokemon/traits/root"])
		p.y = math.max(math.min(p.y - (_action.y-action.y)*0.5, max_scroll), 0)
		gui.set_position(active["pokemon/traits/root"], p)
	end
	if item_button then
		gooey.button(item_button, action_id, action, function()
			local item = _pokemon.get_held_item(active_pokemon)
			monarch.show("info", nil, {text=items.get_description(item)})
		end)
	end
	_action.x = action.x
	_action.y = action.y
end

function M.create(nodes, pokemon)
	active = nodes
	active_pokemon = pokemon
	setup_held_item(nodes, pokemon)
	setup_main_information(nodes, pokemon)
	setup_info_tab(nodes, pokemon)
	
end


return M