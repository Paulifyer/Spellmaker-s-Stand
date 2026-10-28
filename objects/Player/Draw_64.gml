
if (global.menu_lock) exit;

// Draws the hovered target tile
var _t = world_to_grid(mouse_x, mouse_y);
if (_t != undefined) {
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
var _pct = clamp(mana_display / max_mana, 0, 1);

// Background of the Bar
draw_set_colour(c_black);
draw_set_alpha(0.6);
draw_rectangle(_x, _y, _x + _w, _y + _h, false);
draw_set_alpha(1);

// Fills the Mana Bar
if (mana_exhausted && (current_time div 500) mod 2 == 0) {
	draw_set_colour(c_red);
} else {
	draw_set_colour(c_aqua);
}
draw_set_alpha(mana_exhausted ? 0.5 : 1);
draw_rectangle(_x, _y + _h * (1 - _pct), _x + _w, _y + _h, false);
draw_set_alpha(1);

// Mana Bar Border
draw_set_colour(c_white);
draw_rectangle(_x, _y, _x + _w, _y + _h, true);

// Mana Value
draw_set_halign(fa_center);
draw_text(_x + _w / 2, _y + _h + 6, string(floor(mana)));
draw_set_halign(fa_left);

// Caster Draw GUI


for (var i = 0; i < SPELL_SLOTS; i++) {
    var _x2 = 300 + i * 130, _y2 = display_get_gui_height() - 260;
    var _l = global.spellbook[i];
    var _active = i == channel_slot || (i == cast_flash_slot && cast_flash_ticks > 0);
    draw_set_color(_active ? c_aqua : c_white);
    draw_rectangle(_x2, _y2, _x2 + 120, _y2 + 120, true);
    draw_set_color(c_white);
    if (_l != undefined && _l.form != undefined) {
		var _spell_name = (_l.name == "" || _l.name == undefined) ? _l.form : _l.name;
		draw_set_font(fnt_Arcane);
        draw_text_ext(_x2 + 4, _y2 + 22, string(i + 1) + " " + _spell_name, 18, 112);
        draw_text_ext(_x2 + 4, _y2 + 40, "cost: " + string(spell_cost(_l)), 18, 112);
        // swap for glyph icons later
    }
	if (spell_cooldowns[i] > 0 && spell_cooldown_max[i] > 0) {
		var _progress = 1 - spell_cooldowns[i] / spell_cooldown_max[i];
		draw_set_color(c_gray);
		draw_rectangle(_x2 + 4, _y2 + 62, _x2 + 66, _y2 + 66, false);
		draw_set_color(c_aqua);
		draw_rectangle(_x2 + 4, _y2 + 62, _x2 + 4 + 62 * _progress, _y2 + 66, false);
	}
}

draw_set_font(fnt_Arcane);
draw_text(300, display_get_gui_height() - 95, "Hover a tile + press 1/2/3 to cast");
draw_set_font(-1);