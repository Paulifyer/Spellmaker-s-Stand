/// @description Debug level select GUI
var _mx = device_mouse_x_to_gui(0);
var _my = device_mouse_y_to_gui(0);
draw_set_font(fnt_game_end_small);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_white);
draw_text(960, 120, "DEBUG LEVEL SELECT");
draw_text(960, 175, "Click a level or press 1-8. Esc returns to menu.");

for (var n = 1; n <= 8; n++) {
	var _col = (n - 1) mod 2;
	var _row = floor((n - 1) / 2);
	var _left = 370 + _col * 620;
	var _top = 230 + _row * 170;
	var _hover = _mx >= _left && _mx <= _left + 560
		&& _my >= _top && _my <= _top + 130;
	var _config = global.level_config[$ room_get_name(level_rooms[n - 1])];
	draw_set_color(_hover ? #376652 : #233A31);
	draw_rectangle(_left, _top, _left + 560, _top + 130, false);
	draw_set_color(c_white);
	draw_text(_left + 280, _top + 42, "LEVEL " + string(n)
		+ "  -  " + string(_config.level_wave_config.wave_count) + " waves");
	draw_set_color(level_warnings[n - 1] == "" ? #A9D8AF : #F0C779);
	draw_text(_left + 280, _top + 91, level_warnings[n - 1] == ""
		? "All planned glyphs available" : level_warnings[n - 1]);
}

draw_set_color(_mx >= 820 && _mx <= 1100 && _my >= 950 && _my <= 1020
	? #376652 : #233A31);
draw_rectangle(820, 950, 1100, 1020, false);
draw_set_color(c_white);
draw_text(960, 985, "BACK");

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
