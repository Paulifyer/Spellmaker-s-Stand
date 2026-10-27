/// @description Game Won Menu


/*
	This is here because if it is in the Draw GUI
	the buttons will draw below it.
*/

// Draw the Sprite
draw_self();

global.menu_lock = true;

// Handle glyph unlocks
var _unlock_icons = handle_next_level_glyphs(room_next(room), false);

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

// Set the font
draw_set_font(fnt_game_end_big);

// Use our custom function to draw the text and the outline 
draw_text_transformed_outlined(x, y - map_value(image_xscale, 0, 1, 0, 400), "well done!", image_xscale, image_yscale, image_angle, #baaa7d, #33261E);
