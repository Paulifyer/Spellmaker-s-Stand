if (!spell_slot_unlocked(sel)) { sel = 0; naming = false; active_group = -1; }
if (naming) {
    var _s = spell_ensure(sel);
    _s.name = string_copy(keyboard_string, 1, 16);
    if (keyboard_check_pressed(vk_enter)) { naming = false; spell_prune(sel); }
}

if (notice_timer > 0 && --notice_timer <= 0) notice = "";
