
// Draws the selected tile
var _t = world_to_grid(mouse_x, mouse_y);
if (_t != undefined && array_length(input_glyphs) > 0) {
	var _x1 = GRID_X0 + _t.col * TILE_W;
	var _y1 = global.lane_top[_t.lane] ;//+ ((_t.row mod ROWS_PER_LANE) * TILE_H);
	draw_set_alpha(0.3);
	draw_rectangle(_x1, _y1, _x1 + TILE_W, _y1 + LANE_H, false);
	draw_set_alpha(1);
}

// Draws the player's mana bar
mana_display = lerp(mana_display, mana, 0.15);

var _x = 20, _y = 120;
var _w = 24, _h = 300;
var _pct = clamp(mana_display / MAX_MANA, 0, 1);

// Background of the Bar
draw_set_colour(c_black);
draw_set_alpha(0.6);
draw_rectangle(_x, _y, _x + _w, _y + _h, false);
draw_set_alpha(1);

// Fills the Mana Bar
draw_set_colour(c_aqua);
draw_rectangle(_x, _y + _h * (1 - _pct), _x + _w, _y + _h, false);

// Mana Bar Border
draw_set_colour(c_white);
draw_rectangle(_x, _y, _x + _w, _y + _h, true);

// Mana Value
draw_set_halign(fa_center);
draw_text(_x + _w / 2, _y + _h + 6, string(floor(mana)));
draw_set_halign(fa_left);

// Caster Draw GUI
for (var i = 0; i < SPELL_SLOTS; i++) {
    var _x2 = 300 + i * 80, _y2 = display_get_gui_height() - 180;
    var _l = global.spellbook[i];
    draw_set_color(i == spell_selected ? c_aqua : c_white);
    draw_rectangle(_x2, _y2, _x2 + 70, _y2 + 70, true);
    draw_set_color(c_white);
    if (_l != undefined && _l.form != undefined) {
		draw_set_font(-1);
        draw_text(_x2 + 4, _y2 + 4, string(i + 1) + " " + _l.form);
        draw_text(_x2 + 4, _y2 + 40, string(spell_cost(_l)));
        // swap for glyph icons later
    }
}
