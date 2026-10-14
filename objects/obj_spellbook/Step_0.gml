if (naming) {
    var _s = spell_ensure(sel);
    _s.name = string_copy(keyboard_string, 1, 16);
    if (keyboard_check_pressed(vk_enter)) { naming = false; spell_prune(sel); }
}