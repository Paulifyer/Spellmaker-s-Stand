/// @description Main menu debug shortcut hint
if (room != rm_menu || !tune_flag("debug", "level_select_enabled")) exit;
draw_set_font(fnt_game_end_small);
draw_set_halign(fa_right);
draw_set_valign(fa_bottom);
draw_set_color(c_white);
draw_text(1880, 1040, "F8 - Debug Level Select");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
