/// @description Spellbook

sel = 0; // Spellbook spell selector
display_set_gui_size(1920, 1080);   // so the wireframe's pixel coordinates line up

sel = 0;
naming = false;
close_requested = false;
hover_text = "";
enemy_view = 0;

column_keys   = ["form", "element", "modifier"];
column_titles = ["Form", "Effect", "Modifier"];
glyph_row_y   = [265, 490, 835];     // palette rows, under each heading
group_angles   = [90, 210, 330];     // where effect groups sit around the hexagram
active_group = -1;					 // -1 = form group, 0.. = effect index
notice = ""; notice_timer = 0;
craft_cx = 1142; craft_cy = 495;     // centre of the hexagram

// Unique enemies for this level, taken directly from its configured roster.
enemies_in_level = [];
with (obj_wave_manager) {
    var _roster = level_wave_config.enemy_roster;
    for (var i = 0; i < array_length(_roster); i++) {
        array_push(other.enemies_in_level, _roster[i].enemy_object);
    }
}

global.menu_lock = true;
