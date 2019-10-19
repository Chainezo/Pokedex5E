local gooey = require "screens.generate_pokemon.gooey.gooey"
local gooey_buttons = require "utils.gooey_buttons"

local M = {}

local active = {active=false}

local function button_click(name, button_id, scroll_id)
	if active.active then return true end
	local scroll_bg_id = gui.get_node(active[name].scroll_bg_id)
	local button_id = gui.get_node(active[name].button_id)
	local scroll_id = gui.get_node(active[name].scroll_id)
	local b = gui.get_size(button_id)
	local s = gui.get_size(scroll_bg_id)
	s.x = b.x 
	gui.set_size(scroll_bg_id, s)
	local n = gui.get_node("scroll_selection")
	local s2 = gui.get_size(n)
	s2.x = s.x
	gui.set_size(n, s2)
	
	gui.set_position(gui.get_node("offset"), vmath.vector3(s.x*0.5, 0, 0))
	gui.set_enabled(scroll_bg_id, true)
	local p = gui.get_screen_position(button_id)
	p.y = p.y - b.y * 0.5
	local size = gui.get_size(button_id)
	gui.set_screen_position(scroll_bg_id, p)
	
	active[name].active = true
	active.active = true
	active.name = name
end


local function update_items(item, name)
	local item_id = active[name].item_id
	gui.set_text(item.nodes[item_id], item.data:upper())
end

local function update_list(list, name)
	gooey.vertical_scrollbar("handle", "bar").scroll_to(0, list.scroll.y)
	for i,item in ipairs(list.items) do
		if item.data then
			update_items(item, name)
		end
	end
end

local function on_item_selected(list, name)
	local scroll_id = active[list.id].scroll_id
	local scroll_bg_id = active[list.id].scroll_bg_id
	local button_txt_id = active[list.id].button_txt_id
	for i, entry in pairs(list.items) do
		if entry.data and entry.index == list.selected_item then
			gui.set_text(gui.get_node(button_txt_id), entry.data:upper())
			gui.set_enabled(gui.get_node(scroll_bg_id), false)
			active[list.id].active = false
			active[list.id].selected_item = entry.data
			active.active = false
			if active[list.id].func then active[list.id].func() end
		end
	end
end

local function setup_state(name, button_id, button_txt_id, scroll_id, scroll_bg_id, item_id, action_id, action, func)
	local scroll = gui.get_node(scroll_id)
	local button = gui.get_node(button_id)
	
	if not active[name] then
		active[name] = {active = false, button_id = button_id, button_txt_id = button_txt_id, scroll_id = scroll_id, item_id = item_id, func=func, scroll_bg_id = scroll_bg_id}
	end
	if gui.pick_node(scroll, action.x, action.y) then
		if action.pressed and active[name].active then
			active[name].scroll_clicked = true
		end

	else
		if action.pressed then
			active[name].scroll_clicked = false
		end
	end

	if gui.pick_node(button, action.x, action.y) then
		active[name].button_over = true
		if action.released then
			if active[name].button_pressed then
				active[name].button_clicked = true
			end
		end
		if action.pressed then
			active[name].button_pressed = true
		end
	else
		active[name].button_over = false
		active[name].button_clicked = false
	end
end

local function on_scrolled(scrollbar, name, scroll_id, item_id, data)
	gooey.dynamic_list(name, scroll_id, item_id, data).scroll_to(0, scrollbar.scroll.y)
end

function M.final()
	active = {active=false}
end
	

function M.on_input(name, button_id, button_txt_id, scroll_id, scroll_bg_id, item_id, data, action_id, action, func)
	
	setup_state(name, button_id, button_txt_id, scroll_id, scroll_bg_id, item_id, action_id, action, func)
	if active[name].active and not active[name].scroll_clicked and action_id==hash("touch") and action.released and not active[name].button_over then
		active[name].active = false
		active.active = false
		gui.set_enabled(gui.get_node(scroll_bg_id), false)
	end
	
	local b = gooey.button(button_id, action_id, action, function() 
		if active.name ~= name then
			gooey.vertical_scrollbar("handle", "bar").scroll_to(0, 0)
			gooey.dynamic_list(name, scroll_id, item_id, data).scroll_to(0, 0)
		end
		button_click(name, scroll_id) end)
	if not active[name].active then
		return false
	end
	if active[name] then
		local list = gooey.dynamic_list(name, scroll_id, item_id, data, action_id, action, function(list) on_item_selected(list) end, function(list) update_list(list, name) end)
		if list.max_y and list.max_y > 0 then
			gooey.vertical_scrollbar("handle", "bar", action_id, action, function(scrollbar) on_scrolled(scrollbar, name, scroll_id, item_id, data) end)
		end
	end
	return active[name].active
end

return M