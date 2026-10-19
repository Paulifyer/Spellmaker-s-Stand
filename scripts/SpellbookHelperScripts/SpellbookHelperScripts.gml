#macro SPELL_SLOTS 3

#macro MAX_EFFECTS 5
#macro MAX_MODS 5


// The spellbook used by the player when casting spells
global.spellbook = array_create(SPELL_SLOTS, undefined);

global.enemy_info = ds_map_create();   // or a struct keyed by object_get_name(obj)

function spell_ensure(_i) {
    if (global.spellbook[_i] == undefined)
        global.spellbook[_i] = { name: "", form: undefined, form_mods: [], effects: [] };
    return global.spellbook[_i];
}

function spell_prune(_i) {   // empty slot if no form and no name; returns the spell or undefined
    var _s = global.spellbook[_i];
    if (_s != undefined && _s.form == undefined && _s.name == "") {
        global.spellbook[_i] = undefined;
        return undefined;
    }
    return _s;
}

function mod_valid_for_form(_mod_id, _form_id) {
    var _m = global.spell_glyphs.modifier[$ _mod_id];
    return _m.allowed_forms == undefined || array_contains(_m.allowed_forms, _form_id);
}

function spell_clear(_s) {
    _s.form = undefined; _s.form_mods = []; _s.effects = [];
}

// Returns "" on success, otherwise a message for the player
function spell_add_glyph(_s, _type, _id, _active) {
    if (!is_glyph_available(_type, _id)) return "Not available";
	if (_type == "form") {
        _s.form = _id;
        // drop anything the new form can't use
        for (var i = array_length(_s.form_mods) - 1; i >= 0; i--)
            if (!mod_valid_for_form(_s.form_mods[i], _id)) array_delete(_s.form_mods, i, 1);
        for (var e = 0; e < array_length(_s.effects); e++)
            for (var i = array_length(_s.effects[e].mods) - 1; i >= 0; i--)
                if (!mod_valid_for_form(_s.effects[e].mods[i], _id)) array_delete(_s.effects[e].mods, i, 1);
        return "";
    }

    if (_s.form == undefined) return "Pick a form first";

    if (_type == "effect") {
        if (array_length(_s.effects) >= MAX_EFFECTS) return "Too many effects";
        for (var e = 0; e < array_length(_s.effects); e++)
            if (_s.effects[e].effect== _id) return "Effect already added";
        array_push(_s.effects, { effect: _id, mods: [] });
        return "";
    }

    // modifier
    if (!mod_valid_for_form(_id, _s.form)) return "Can't attach to this form";
    var _m = global.spell_glyphs.modifier[$ _id];
    var _list;
    if (_m.scope == "spell") {
        _list = _s.form_mods;
    } else {
        if (array_length(_s.effects) == 0) return "Add an effect first";
        var _ei = (_active >= 0) ? _active : array_length(_s.effects) - 1;
        _list = _s.effects[_ei].mods;
    }
    if (array_length(_list) >= MAX_MODS) return "Group is full";
    if (array_contains(_list, _id) && !_m.is_stacks) return "Already attached";
    array_push(_list, _id);
    return "";
}

function spell_cost(_s) {
    if (_s == undefined || _s.form == undefined) return 0;
    var _g = global.spell_glyphs;
    var _c = _g.form[$ _s.form].cost;
    for (var i = 0; i < array_length(_s.form_mods); i++) _c += _g.modifier[$ _s.form_mods[i]].cost;
    for (var e = 0; e < array_length(_s.effects); e++) {
        _c += _g.effect[$ _s.effects[e].effect].cost;
		var _amp_count = 0;
        for (var i = 0; i < array_length(_s.effects[e].mods); i++) {
			var _m = _g.modifier[$ _s.effects[e].mods[i]];
            _c += _m.cost;
			if (is_instanceof(_m, Mod_Amplify)) { // Handles Multiple Amplifies on one effect
				_c += (_amp_count * 5);
				_amp_count++;
			}
		}
    }
    return _c;
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

function gui_circle_button(_x, _y, _r, _icon, _label, _active, _enabled = true) {
    var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
    var _hover = point_distance(_mx, _my, _x, _y) <= _r;
    var _a = _enabled ? 1 : 0.35;

    draw_set_alpha(_a);
    draw_set_color(_active ? c_aqua : (_hover && _enabled ? c_ltgray : c_white));
    draw_circle(_x, _y, _r, false);
    draw_set_color(c_black);
    draw_circle(_x, _y, _r, true);

    if (_icon != undefined) {
        var _s = (_r * 2) / sprite_get_width(_icon);
        draw_sprite_ext(_icon, 0, _x, _y, _s, _s, 0, c_white, _a);
    } else {
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_text(_x, _y, _label);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
    }
    draw_set_alpha(1);

    return {
        hover:    _hover,
        clicked:  _enabled && _hover && mouse_check_button_pressed(mb_left),
        rclicked: _enabled && _hover && mouse_check_button_pressed(mb_right)
    };
}

// Draws one glyph with its modifier satellites. Returns what was hovered/clicked.
function draw_glyph_group(_x, _y, _r, _glyph, _mod_ids, _base, _spread, _selected) {
    var _out = { main: undefined, mod_r: -1, hover: "" };
    var _n = array_length(_mod_ids);
    var _px = [], _py = [];

    // connectors first, so circles sit on top
    draw_set_color(c_black);
    for (var k = 0; k < _n; k++) {
        var _a = _base + (k - (MAX_MODS - 1) / 2) * _spread;
        array_push(_px, _x + lengthdir_x(_r + 38, _a));
        array_push(_py, _y + lengthdir_y(_r + 38, _a));
        draw_line_width(_x, _y, _px[k], _py[k], 3);
    }

    if (_selected) {
        draw_set_color(c_aqua);
        draw_circle(_x, _y, _r + 7, true);
        draw_circle(_x, _y, _r + 8, true);
        draw_set_color(c_black);
    }

    for (var k = 0; k < _n; k++) {
        var _m = global.spell_glyphs.modifier[$ _mod_ids[k]];
        var _b = gui_circle_button(_px[k], _py[k], 24, _m.icon, _m.name, false);
        if (_b.hover)    _out.hover = _m.name + "\n" + _m.desc + "\n(right-click to remove)";
        if (_b.rclicked) _out.mod_r = k;
    }

    _out.main = gui_circle_button(_x, _y, _r, _glyph.icon, _glyph.name, false);
    if (_out.main.hover) _out.hover = _glyph.name + "\n" + _glyph.desc
                                    + "\n(click: select group, right-click: remove)";
    return _out;
}