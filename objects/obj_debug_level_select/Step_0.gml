/// @description Pick a level with a click or number key
if (keyboard_check_pressed(vk_escape)) {
	window_set_cursor(cr_none);
	room_goto(rm_menu);
	exit;
}

var _chosen = 0;
for (var i = 1; i <= 8; i++) {
	if (keyboard_check_pressed(ord(string(i)))) _chosen = i;
}

if (mouse_check_button_pressed(mb_left)) {
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);
	if (_mx >= 820 && _mx <= 1100 && _my >= 950 && _my <= 1020) {
		window_set_cursor(cr_none);
		room_goto(rm_menu);
		exit;
	}
	for (var n = 1; n <= 8; n++) {
		var _col = (n - 1) mod 2;
		var _row = floor((n - 1) / 2);
		var _left = 370 + _col * 620;
		var _top = 230 + _row * 170;
		if (_mx >= _left && _mx <= _left + 560
		&& _my >= _top && _my <= _top + 130) _chosen = n;
	}
}

if (_chosen > 0) {
	var _target = level_rooms[_chosen - 1];
	var _name = room_get_name(_target);
	if (!variable_struct_exists(global.level_config, _name)) {
		show_debug_message("Debug level select: no configuration for " + _name);
		exit;
	}
	global.current_level = _chosen - 1;
	global.debug_level_select_active = true;
	window_set_cursor(cr_none);
	room_goto(_target);
}
