#macro SPELL_SLOTS 3

global.spell_slots = 3;

global.spellbook = array_create(SPELL_SLOTS, undefined); // each entry: {form, element, modifier}

global.enemy_info = ds_map_create();   // or a struct keyed by object_get_name(obj)

function spell_ensure(_i) {
	if (global.spellbook[_i] == undefined) {
		global.spellbook[_i] = { form: undefined, element: undefined, modifier: undefined, name: "" };
	}
	return global.spellbook[_i];
}

function spell_prune(_i) {   // empties the slot if nothing is in it; returns the spell or undefined
    var _s = global.spellbook[_i];
    if (_s != undefined && _s.form == undefined && _s.element == undefined
        && _s.modifier == undefined && _s.name == "") {
        global.spellbook[_i] = undefined;
        return undefined;
    }
    return _s;
}

function gui_circle_button(_x, _y, _r, _icon, _label, _active) {
    var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _hover = point_distance(_mx, _my, _x, _y) <= _r;

    draw_set_color(_active ? c_aqua : (_hover ? c_ltgray : c_white));
    draw_circle(_x, _y, _r, false);
    draw_set_color(c_black);
    draw_circle(_x, _y, _r, true);

    if (_icon != undefined) {
        var _s = (_r * 2) / sprite_get_width(_icon);
        draw_sprite_ext(_icon, 0, _x, _y, _s, _s, 0, c_white, 1);
    } else {
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_text(_x, _y, _label);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
    }
    return { hover: _hover, clicked: _hover && mouse_check_button_pressed(mb_left) };
}

function gui_button(_x, _y, _w, _h, _label, _active) {
    var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _hover = point_in_rectangle(_mx, _my, _x, _y, _x + _w, _y + _h);

    draw_set_color(_active ? c_aqua : (_hover ? c_gray : c_dkgray));
    draw_rectangle(_x, _y, _x + _w, _y + _h, false);
    draw_set_color(c_white);
    draw_rectangle(_x, _y, _x + _w, _y + _h, true);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text(_x + _w / 2, _y + _h / 2, _label);
    draw_set_halign(fa_left); draw_set_valign(fa_top);

    return _hover && mouse_check_button_pressed(mb_left);
}
