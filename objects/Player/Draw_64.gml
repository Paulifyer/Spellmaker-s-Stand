

for (var i = 0; i < 3; i++) {
	var _x = 100 + i * 200;
	var _rec_color = (is_spell_on_cd) ? c_gray : c_fuchsia;
	draw_set_colour(_rec_color);
	draw_rectangle(_x, 864, _x + 60, 924, true);
	if (i < array_length(input_glyphs)) draw_text(_x + 8, 894, input_glyphs[i]); //text for each glyph selected
	draw_set_colour(c_white);
}

// Draws the selected tile
var _t = world_to_grid(mouse_x, mouse_y);
if (_t != undefined && array_length(input_glyphs) > 0) {
	var _x1 = GRID_X0 + _t.col * TILE_W;
	var _y1 = global.lane_top[_t.lane] ;//+ ((_t.row mod ROWS_PER_LANE) * TILE_H);
	draw_set_alpha(0.3);
	draw_rectangle(_x1, _y1, _x1 + TILE_W, _y1 + LANE_H, false);
	draw_set_alpha(1);
}