/// @description Game Won Menu


/*
	This is here because if it is in the Draw GUI
	the buttons will draw below it.
*/

// Draw the Sprite
draw_self();

global.menu_lock = true;

// Handle glyph unlocks
var _next_room = global.current_level + 1 < array_length(global.level_array)
	? global.level_array[global.current_level + 1] : -1;
var _unlock_icons = handle_next_level_glyphs(_next_room, false);

// drawing unlocked glyphs
draw_unlocked_glyphs(_unlock_icons);

// Set the Font horizontal alignment
draw_set_halign(fa_center);

// Set the font vertical alignment
draw_set_valign(fa_middle);

// Set the font
draw_set_font(fnt_game_end_small);

// Use our custom function to draw the text and the outline 
draw_text_transformed_outlined(x, y - map_value(image_xscale, 0, 1, 0, 500), "Stage Complete!", image_xscale, image_yscale, image_angle, #baaa7d, #33261E);

// Stars share the popup's sequence scale and alpha.
var _star_size = 128 / 128;
for (var i = 0; i < 3; i++) {
    var _sprite = i < rating.stars
        ? (rating.flawless ? spr_star_flawless : spr_star_earned) : spr_star_empty;
    draw_sprite_ext(_sprite, 0, x + (i - 1) * 152 * image_xscale,
        y - 395 * image_yscale, _star_size * image_xscale,
        _star_size * image_yscale, image_angle, c_white, image_alpha);
}
draw_text_transformed_outlined(x, y - 295 * image_yscale,
    "Wall HP remaining: " + string(rating.hp_remaining),
    image_xscale * 0.65, image_yscale * 0.65, image_angle, #baaa7d, #33261E);
