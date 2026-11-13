/// @description Pick a level with a click or number key
if (keyboard_check_pressed(vk_f8)) debug_unlock_all = !debug_unlock_all;

if (keyboard_check_pressed(vk_escape)) {
	window_set_cursor(cr_none);
	room_goto(rm_menu);
	exit;
}

var _chosen = 0;
for (var i = 1; i <= array_length(level_rooms); i++) {
	if (keyboard_check_pressed(ord(string(i)))) _chosen = i;
}

if (mouse_check_button_pressed(mb_left)) {
	var _mouse = level_select_mouse();
	var _mx = _mouse.x;
	var _my = _mouse.y;
	if (point_in_rectangle(_mx, _my, back_button.x, back_button.y,
		back_button.x + back_button.w, back_button.y + back_button.h)) {
		window_set_cursor(cr_none);
		room_goto(rm_menu);
		exit;
	}
	for (var n = 1; n <= array_length(level_rooms); n++) {
		var _button = level_buttons[n - 1];
		if (point_in_rectangle(_mx, _my, _button.x, _button.y,
			_button.x + _button.w, _button.y + _button.h)) _chosen = n;
	}
}

if (_chosen > 0) {
	if (!debug_unlock_all && !level_progress[_chosen - 1].unlocked) exit;
	var _target = level_rooms[_chosen - 1];
	var _name = room_get_name(_target);
	if (!variable_struct_exists(global.level_config, _name)) {
		show_debug_message("Debug level select: no configuration for " + _name);
		exit;
	}
	global.current_level = _chosen - 1;
	window_set_cursor(cr_none);
	room_goto(_target);
}
