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
	var _col = (_unlocked ? c_white : c_gray);
	var _spr = _hover ? spr_level_button_hover : spr_level_button;
	var _xscale = _button.w / sprite_get_width(_spr);
	var _yscale = _button.h / sprite_get_height(_spr);
	show_debug_message($"xs: {_xscale}, ys: {_yscale}");
	draw_sprite_ext(_spr, 0, _left, _top, _xscale, _yscale, 0, _col, 1);
	var _center_x = _left + _button.w / 2;
	var _detail_y = _top + _button.h * 0.7;
	draw_set_colour(c_white);
	draw_text(_center_x, _top + _button.h * 0.34, "LEVEL " + string(n));
	if (!_unlocked) {
		draw_text(_center_x, _detail_y, "Clear Level " + string(n - 1) + " to unlock");
	} else if (_progress.stars > 0) {
		var _star_size = _button.h * 0.4;
		var _star_scale = _star_size / sprite_get_height(spr_star_earned);
		var _earned_sprite = _progress.flawless ? spr_star_flawless : spr_star_earned;
		for (var i = 0; i < 3; i++) {
			var _star_sprite = i < _progress.stars ? _earned_sprite : spr_star_empty;
			draw_sprite_ext(_star_sprite, 0, _center_x + (i - 1) * _star_size * 1.2,
				_detail_y, _star_scale, _star_scale, 0, c_white, 1);
		}
	} else {
	    draw_set_font(fnt_Arcane_Bold_Bold);
	    draw_text(_center_x, _detail_y, "NEW!");
	    draw_set_font(fnt_Arcane);
	}
	// else {
	// 	var _config = global.level_config[$ room_get_name(level_rooms[n - 1])];
	// 	draw_text(_center_x, _detail_y, string(_config.level_wave_config.wave_count) + " waves");
	// }
}

//draw_set_color(point_in_rectangle(_mx, _my, back_button.x, back_button.y,
//	back_button.x + back_button.w, back_button.y + back_button.h)
//	? #376652 : #233A31);
//draw_roundrect_ext(back_button.x, back_button.y,
//	back_button.x + back_button.w, back_button.y + back_button.h, 16, 16, false);
//draw_set_color(c_white);
//draw_text(back_button.x + back_button.w / 2, back_button.y + back_button.h / 2, "BACK");

draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);

matrix_set(matrix_world, _saved_world);
