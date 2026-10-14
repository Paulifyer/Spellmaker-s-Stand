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
slot_angles   = [90, 330, 210];      // placed glyph positions: top, lower right, lower left
craft_cx = 1142; craft_cy = 495;     // centre of the hexagram

// Unique enemies for this level, taken from the waves
enemies_in_level = [];
with (obj_wave_manager) {
    for (var w = 0; w < array_length(wave_array); w++) {
        var _arr = wave_array[w].enemy_array;
        for (var i = 0; i < array_length(_arr); i++) {
            if (!array_contains(other.enemies_in_level, _arr[i]))
                array_push(other.enemies_in_level, _arr[i]);
        }
    }
}

global.menu_lock = true;