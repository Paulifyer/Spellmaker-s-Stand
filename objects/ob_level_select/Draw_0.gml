draw_self();
if (image_xscale == 0 || image_yscale == 0) exit;
var _saved_world = matrix_get(matrix_world);
var _local = matrix_build(-sprite_get_xoffset(sprite_index), -sprite_get_yoffset(sprite_index), 0, 0, 0, 0, 1, 1, 1);
var _scroll = matrix_build(x, y, 0, 0, 0, image_angle, image_xscale, image_yscale, 1);
matrix_set(matrix_world, matrix_multiply(matrix_multiply(_local, _scroll), _saved_world));
/// @description Draw the animated scroll and its buttons together.
var _mouse = level_select_mouse();
var _mx = _mouse.x;
var _my = _mouse.y;
draw_set_font(fnt_game_end_small);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(c_black);
draw_set_font(fnt_Arcane_Bold_Bold);
draw_text(heading_x, heading_y, debug_unlock_all ? "LEVEL SELECT - DEBUG" : "LEVEL SELECT");
draw_set_font(fnt_Arcane);
draw_text(heading_x, instructions_y, "Click a level or press 1-8. Esc returns to menu.");
draw_text(heading_x, instructions_y + 25,
	debug_unlock_all ? "F8: Debug ON - all levels unlocked" : "");

for (var n = 1; n <= array_length(level_rooms); n++) {
	var _progress = level_progress[n - 1];
	var _unlocked = debug_unlock_all || _progress.unlocked;
	var _button = level_buttons[n - 1];
	var _left = _button.x;
	var _top = _button.y;
	var _hover = _unlocked && point_in_rectangle(_mx, _my, _left, _top,
		_left + _button.w, _top + _button.h);
	var _config = global.level_config[$ room_get_name(level_rooms[n - 1])];
	draw_set_color(!_unlocked ? #49433D : (_hover ? #376652 : #233A31));
	draw_roundrect_ext(_left, _top, _left + _button.w, _top + _button.h, 16, 16, false);
	draw_set_colour(_hover ? c_gray : c_black);
	draw_set_alpha(_hover ? 0.5 : 0.7);
	draw_roundrect_ext(_left + 5, _top + 5, _left + _button.w - 5, _top + _button.h - 5, 16, 16, false);
	draw_set_alpha(1);
	draw_set_color(_unlocked ? c_white : c_ltgray);
	draw_text(_left + _button.w / 2, _top + _button.h * 0.34, "LEVEL " + string(n));
	draw_text(_left + _button.w / 2, _top + _button.h * 0.7,
		!_unlocked ? "Clear Level " + string(n - 1) + " to unlock"
		: (_progress.stars > 0 ? string(_progress.stars) + " / 3 stars"
		: string(_config.level_wave_config.wave_count) + " waves"));
}

draw_set_color(point_in_rectangle(_mx, _my, back_button.x, back_button.y,
	back_button.x + back_button.w, back_button.y + back_button.h)
	? #376652 : #233A31);
draw_roundrect_ext(back_button.x, back_button.y,
	back_button.x + back_button.w, back_button.y + back_button.h, 16, 16, false);
draw_set_color(c_white);
draw_text(back_button.x + back_button.w / 2, back_button.y + back_button.h / 2, "BACK");

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);

matrix_set(matrix_world, _saved_world);
