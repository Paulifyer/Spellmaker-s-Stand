

draw_self();

draw_set_font(fnt_Arcane_More_Bold);
var _spr = sprite_index;

var _w = sprite_get_width(_spr) * base_xscale;
var _h = sprite_get_height(_spr) * base_yscale;

var _center_x = x + (_w / 2);
var _center_y = y + (_h / 2);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_transformed_outlined(_center_x, _center_y, string(text), 1, 1, 0, text_outline_color, text_color);
draw_set_halign(fa_top);
draw_set_valign(fa_left);


