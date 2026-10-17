/// @description Game Won Menu


/*
	This is here because if it is in the Draw GUI
	the buttons will draw below it.
*/

// Draw the Sprite
draw_self();

global.menu_lock = true;

// Draw the win image 
//draw_sprite_ext(spr_win_image, 0, x, y - 13, image_xscale, image_yscale, image_angle, image_blend, image_alpha);

//Draw the unlocked glyph!
if (global.current_level == 0) {
	var _s = (55 * 2) / sprite_get_width(spr_glyph_fire);
	draw_set_font(fnt_Arcane);
	var _sx_offs = string_width("Unlocked new Glyphs!:") / 2;
	draw_text(x - _sx_offs, y - 200, "Unlocked new Glyphs!:");
	draw_sprite_ext(spr_glyph_fire, 0, x + 70, y - 100, _s, _s, image_angle, image_blend, image_alpha);
	draw_sprite_ext(spr_glyph_pierce, 0, x - 70, y - 100, _s, _s, image_angle, image_blend, image_alpha);
}

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