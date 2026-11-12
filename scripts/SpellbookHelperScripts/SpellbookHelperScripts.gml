#macro SPELL_SLOTS 4




// The spellbook used by the player when casting spells
global.spellbook = array_create(SPELL_SLOTS, undefined);

function spell_slot_count() {
    var _config = global.level_config[$ room_get_name(room)];
    // Developer rooms have no campaign configuration and expose every slot.
    return is_struct(_config) ? _config.spell_slots : SPELL_SLOTS;
}

function spell_slot_unlocked(_slot) {
    return _slot >= 0 && _slot < spell_slot_count();
}

function spell_slot_unlock_level(_slot) {
    for (var n = 0; n < array_length(global.level_array); n++) {
        var _config = global.level_config[$ room_get_name(global.level_array[n])];
        if (is_struct(_config) && _slot < _config.spell_slots) return n + 1;
    }
    return undefined;
}

function spell_max_glyphs() {
    return global.level_config[$ room_get_name(room)].max_glyphs;
}

function spell_effect_order_label(_order) {
    static _values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    static _numerals = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];
    var _label = "";

    for (var i = 0; i < array_length(_values) && _order > 0; i++) {
        var _repeats = _order div _values[i];
        if (_repeats > 0) _label += string_repeat(_numerals[i], _repeats);
        _order = _order mod _values[i];
    }
    return _label;
}

function spell_glyph_count(_s) {
    if (_s == undefined || _s.form == undefined) return 0;
    var _count = 1 + array_length(_s.form_mods);
    for (var e = 0; e < array_length(_s.effects); e++) {
        _count += 1 + array_length(_s.effects[e].mods);
    }
    return _count;
}

function spell_ensure(_i) {
    if (!spell_slot_unlocked(_i)) return undefined;
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

function spell_catalog_entry(_type, _id) {
    var _catalog = global.spell_glyphs[$ _type];
    if (!is_struct(_catalog) || !variable_struct_exists(_catalog, _id)) return undefined;
    return _catalog[$ _id];
}

function mod_valid_for_form(_mod_id, _form_id) {
    var _m = spell_catalog_entry("modifier", _mod_id);
    if (!is_struct(_m) || _m.scope == "effect") return false;
    var _excluded = tune_setting("compatibility", "form_modifier_exclusions", _form_id, []);
    if (is_array(_excluded) && array_contains(_excluded, _mod_id)) return false;
    return _m.allowed_forms == undefined || array_contains(_m.allowed_forms, _form_id);
}

// Tuning restricts different types; existing is_stacks rules govern repeats.
function form_modifiers_conflict(_a, _b) {
    if (_a == _b) return false;
    if (!variable_global_exists("tuning")) return false;
    var _config = global.tuning[$ "compatibility"];
    if (!is_struct(_config)) return false;
    var _groups = _config[$ "exclusive_form_modifier_groups"];
    if (!is_array(_groups)) return false;
    for (var g = 0; g < array_length(_groups); g++) {
        var _group = _groups[g];
        if (!is_array(_group)) continue;
        if (array_contains(_group, _a) && array_contains(_group, _b)) return true;
    }
    return false;
}

// Groups span the whole spell; repeats of the same ID still follow stacking/Delay rules.
// A replacement Form is checked against only the attachments it will retain.
function spell_exclusive_glyph_message(_s, _extra = "", _replacement_form = undefined) {
    if (!variable_global_exists("tuning")) return "";
    var _config = global.tuning[$ "compatibility"];
    if (!is_struct(_config)) return "";
    var _groups = _config[$ "exclusive_glyph_groups"];
    if (!is_array(_groups)) return "";
    var _ids = [];
    if (_s != undefined) {
        var _form = (_replacement_form == undefined) ? _s.form : _replacement_form;
        if (_form != undefined) array_push(_ids, _form);
        for (var i = 0; i < array_length(_s.form_mods); i++) {
            var _id = _s.form_mods[i];
            if (_replacement_form == undefined || mod_valid_for_form(_id, _form)) array_push(_ids, _id);
        }
        for (var e = 0; e < array_length(_s.effects); e++) {
            var _fx = _s.effects[e];
            if (_replacement_form != undefined && !effect_valid_for_form(_fx.effect, _form)) continue;
            array_push(_ids, _fx.effect);
            for (var i = 0; i < array_length(_fx.mods); i++) {
                var _id = _fx.mods[i];
                if (_replacement_form == undefined || mod_valid_for_effect(_id, _fx.effect)) array_push(_ids, _id);
            }
        }
    } else if (_replacement_form != undefined) array_push(_ids, _replacement_form);
    if (_extra != "") array_push(_ids, _extra);
    for (var g = 0; g < array_length(_groups); g++) {
        var _group = _groups[g];
        if (!is_array(_group)) continue;
        var _seen = "";
        for (var i = 0; i < array_length(_ids); i++) {
            if (!array_contains(_group, _ids[i])) continue;
            if (_seen != "" && _seen != _ids[i]) return "Can't combine these glyphs";
            _seen = _ids[i];
        }
    }
    return "";
}

// Count only this attachment. The editor includes the pending addition via _extra.
function modifier_limit_message(_list, _id, _key, _extra = 0) {
    var _limit = tune_setting("modifiers", _id, _key, undefined);
    if (_limit == undefined) return "";
    if (!is_real(_limit) || _limit < 0 || floor(_limit) != _limit)
        throw "modifiers." + _id + "." + _key + " must be a non-negative integer";
    var _count = _extra;
    for (var n = 0; n < array_length(_list); n++)
        if (_list[n] == _id) _count++;
    if (_count <= _limit) return "";
    var _target = (_key == "max_per_form") ? "Form" : "Effect";
    return "Max " + string(_limit) + " " + spell_catalog_entry("modifier", _id).name + " glyphs per " + _target;
}

function mod_valid_for_effect(_mod_id, _effect_id) {
	var _m = spell_catalog_entry("modifier", _mod_id);
    if (!is_struct(_m) || _m.scope == "spell") return false;
    return _m.allowed_effects == undefined || array_contains(_m.allowed_effects, _effect_id);
}

function effect_valid_for_form(_effect_id, _form_id) {
	var _e = spell_catalog_entry("effect", _effect_id);
    if (!is_struct(_e) || _effect_id == "none") return false;
    return _e.allowed_forms == undefined || array_contains(_e.allowed_forms, _form_id);
}

// Returns a player-facing reason, shared by the editor, Start, and casting.
function spell_validation_message(_s) {
    if (_s == undefined || _s.form == undefined) return "Pick a Form";
    if (!is_struct(spell_catalog_entry("form", _s.form)) || !is_glyph_available("form", _s.form)) return "Form is unavailable";
    if (spell_glyph_count(_s) > spell_max_glyphs()) return "Too many glyphs for this level";
    if (array_length(_s.effects) == 0) return "Add an Effect";
    var _exclusive = spell_exclusive_glyph_message(_s);
    if (_exclusive != "") return _exclusive;
    if (!spell_sequence_valid(_s)) return "Add Delay between repeated effects";
    for (var i = 0; i < array_length(_s.form_mods); i++) {
        var _id = _s.form_mods[i];
        if (!mod_valid_for_form(_id, _s.form)) return "Modifier is incompatible with this Form";
        for (var j = 0; j < i; j++)
            if (form_modifiers_conflict(_id, _s.form_mods[j])) return "Can't combine these Form modifiers";
        if (!is_glyph_available("modifier", _id)) return "Modifier is locked";
        var _form_limit = modifier_limit_message(_s.form_mods, _id, "max_per_form");
        if (_form_limit != "") return _form_limit;
        if (!spell_catalog_entry("modifier", _id).is_stacks) {
            for (var j = 0; j < i; j++) if (_s.form_mods[j] == _id) return "Modifier cannot stack";
        }
    }
    for (var e = 0; e < array_length(_s.effects); e++) {
        var _fx = _s.effects[e];
        if (!effect_valid_for_form(_fx.effect, _s.form)) return "Effect is incompatible with this Form";
        if (!is_glyph_available("effect", _fx.effect)) return "Effect is locked";
        for (var i = 0; i < array_length(_fx.mods); i++) {
            var _id = _fx.mods[i];
            if (!mod_valid_for_effect(_id, _fx.effect)) return "Modifier is incompatible with this Effect";
            if (!is_glyph_available("modifier", _id)) return "Modifier is locked";
            var _effect_limit = modifier_limit_message(_fx.mods, _id, "max_per_effect");
            if (_effect_limit != "") return _effect_limit;
            if (!spell_catalog_entry("modifier", _id).is_stacks) {
                for (var j = 0; j < i; j++) if (_fx.mods[j] == _id) return "Modifier cannot stack";
            }
        }
    }
    return "";
}

function spell_addition_message(_s, _type, _id, _active) {
    if (!is_struct(spell_catalog_entry(_type, _id)) || !is_glyph_available(_type, _id)) return "Not available";
    if (_type == "form") return spell_exclusive_glyph_message(_s, "", _id);
    if (_s == undefined || _s.form == undefined) return "Pick a Form first";
    if (spell_glyph_count(_s) >= spell_max_glyphs()) return "Glyph limit reached";
    var _exclusive = spell_exclusive_glyph_message(_s, _id);
    if (_exclusive != "") return _exclusive;
    if (_type == "effect") {
        if (!effect_valid_for_form(_id, _s.form)) return "Can't use this Effect with this Form";
        if (!spell_can_append_effect(_s, _id)) return "Add Delay between repeated effects";
        return "";
    }
    var _m = spell_catalog_entry("modifier", _id);
    var _list;
    var _limit_key;
    if (_m.scope == "spell" || (_m.scope == "both" && _active < 0)) {
        if (!mod_valid_for_form(_id, _s.form)) return "Can't attach to this Form";
        _list = _s.form_mods;
        _limit_key = "max_per_form";
        for (var i = 0; i < array_length(_list); i++)
            if (form_modifiers_conflict(_id, _list[i])) return "Can't combine these Form modifiers";
    } else {
        if (array_length(_s.effects) == 0) return "Add an Effect first";
        var _ei = (_active >= 0) ? _active : array_length(_s.effects) - 1;
        if (_ei >= array_length(_s.effects)) return "Select an Effect first";
        if (!mod_valid_for_effect(_id, _s.effects[_ei].effect)) return "Can't attach to this Effect";
        _list = _s.effects[_ei].mods;
        _limit_key = "max_per_effect";
    }
    if (array_contains(_list, _id) && !_m.is_stacks) return "Already attached";
    return modifier_limit_message(_list, _id, _limit_key, 1);
}

// Delay satellites mark a boundary AFTER their effect group.
// Optional skips let the editor validate a removal before changing the spell.
function spell_sequence_valid(_s, _skip_effect = -1, _skip_group = -1, _skip_mod = -1) {
    var _seen = [];
    for (var e = 0; e < array_length(_s.effects); e++) {
        if (e == _skip_effect) continue;
        var _fx = _s.effects[e];
        if (array_contains(_seen, _fx.effect)) return false;
        array_push(_seen, _fx.effect);
        for (var i = 0; i < array_length(_fx.mods); i++) {
            if (e == _skip_group && i == _skip_mod) continue;
            if (_fx.mods[i] == "delay") _seen = [];
        }
    }
    return true;
}

function spell_can_append_effect(_s, _id) {
    var _seen = [];
    for (var e = 0; e < array_length(_s.effects); e++) {
        var _fx = _s.effects[e];
        array_push(_seen, _fx.effect);
        if (array_contains(_fx.mods, "delay")) _seen = [];
    }
    return !array_contains(_seen, _id);
}

function spell_clear(_s) {
    _s.form = undefined; _s.form_mods = []; _s.effects = [];
}

// Returns "" on success, otherwise a message for the player
function spell_add_glyph(_s, _type, _id, _active) {
    var _message = spell_addition_message(_s, _type, _id, _active);
    if (_message != "") return _message;
	if (_type == "form") {
        _s.form = _id;
        // drop anything the new form can't use
        for (var i = array_length(_s.form_mods) - 1; i >= 0; i--)
            if (!mod_valid_for_form(_s.form_mods[i], _id)) array_delete(_s.form_mods, i, 1);
        for (var e = array_length(_s.effects) - 1; e >= 0; e--) {
            if (!effect_valid_for_form(_s.effects[e].effect, _id)) {
                array_delete(_s.effects, e, 1);
                continue;
            }
            for (var i = array_length(_s.effects[e].mods) - 1; i >= 0; i--)
                if (!mod_valid_for_effect(_s.effects[e].mods[i], _s.effects[e].effect)) array_delete(_s.effects[e].mods, i, 1);
        }
        return "";
    }

    if (_s.form == undefined) return "Pick a form first";

    if (_type == "effect") {
        array_push(_s.effects, { effect: _id, mods: [] });
        return "";
    }

    // modifier
    var _m = global.spell_glyphs.modifier[$ _id];
    var _list;
    if (_m.scope == "spell" || (_m.scope == "both" && _active < 0)) {
        _list = _s.form_mods;
    } else {
        if (array_length(_s.effects) == 0) return "Add an effect first";
        var _ei = (_active >= 0) ? _active : array_length(_s.effects) - 1;
        _list = _s.effects[_ei].mods;
    }
    if (array_contains(_list, _id) && !_m.is_stacks) return "Already attached";
    array_push(_list, _id);
    return "";
}

function spell_cost(_s) {
    var _compiled = compile_spell(_s);
    return is_struct(_compiled) ? _compiled.cost : 0;
}

// Compare against capacity, not the player's temporarily depleted mana.
function spell_mana_preview(_s, _max_mana) {
    var _cost = spell_cost(_s);
    return {
        cost: _cost,
        fill: (_max_mana > 0) ? clamp(_cost / _max_mana, 0, 1) : 0,
        too_expensive: _cost > _max_mana
    };
}

function spellbook_expensive_slots(_max_mana) {
    var _slots = "";
    for (var i = 0; i < min(spell_slot_count(), array_length(global.spellbook)); i++) {
        if (!spell_mana_preview(global.spellbook[i], _max_mana).too_expensive) continue;
        if (_slots != "") _slots += ", ";
        _slots += string(i + 1);
    }
    return _slots;
}

function spellbook_start_message(_max_mana) {
    var _message = "";
    for (var i = 0; i < min(spell_slot_count(), array_length(global.spellbook)); i++) {
        var _s = global.spellbook[i];
        // Empty and name-only slots are unused, not incomplete prepared spells.
        if (_s == undefined || _s.form == undefined) continue;
        var _reason = spell_validation_message(_s);
        if (_reason == "" && spell_cost(_s) > _max_mana) _reason = "Spell is too expensive";
        if (_reason == "") continue;
        if (_message != "") _message += "\n";
        _message += "Spell " + string(i + 1) + ": " + _reason;
    }
    return _message;
}

function gui_button(_x, _y, _w, _h, _label, _active, _mouse = undefined) {
    var _mx = (_mouse == undefined) ? device_mouse_x_to_gui(0) : _mouse.x;
    var _my = (_mouse == undefined) ? device_mouse_y_to_gui(0) : _mouse.y;
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

function gui_circle_button(_x, _y, _r, _icon, _label, _active, _enabled = true, _mouse = undefined) {
    var _mx = (_mouse == undefined) ? device_mouse_x_to_gui(0) : _mouse.x;
    var _my = (_mouse == undefined) ? device_mouse_y_to_gui(0) : _mouse.y;
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
// Fit visible glyph artwork into a square, independent of sprite padding/origin.
function draw_spell_slot_glyph(_sprite, _x, _y, _size, _disabled = false) {
    if (_sprite == undefined || _sprite < 0) return;
    var _left = sprite_get_bbox_left(_sprite), _right = sprite_get_bbox_right(_sprite);
    var _top = sprite_get_bbox_top(_sprite), _bottom = sprite_get_bbox_bottom(_sprite);
    var _scale = _size / max(1, max(_right - _left + 1, _bottom - _top + 1));
    if (_disabled) shader_set(sh_spell_recolour);
    draw_sprite_ext(_sprite, 0,
        _x - ((_left + _right) / 2 - sprite_get_xoffset(_sprite)) * _scale,
        _y - ((_top + _bottom) / 2 - sprite_get_yoffset(_sprite)) * _scale,
        _scale, _scale, 0, _disabled ? c_gray : c_white, 1);
    if (_disabled) shader_reset();
}

// Read-only counterpart of the player's input gates and cast_spell checks.
function spell_slot_can_cast(_caster, _spell, _slot, _target) {
    if (!spell_slot_unlocked(_slot) || !is_struct(_spell) || _spell.form == undefined) return false;
    if (_caster.spell_cooldowns[_slot] > 0 || _caster.mana_exhausted) return false;
    if (_caster.channel != noone || global.menu_lock || instance_exists(obj_spellbook) || !window_has_focus()) return false;
    if (_target == undefined || !is_spell_usable(_spell)) return false;
    var _compiled = compile_spell(_spell);
    if (!is_struct(_compiled)) return false;
    if (!is_instanceof(_compiled.form, Form_Beam) && _caster.mana < _compiled.cost) return false;
    if (_compiled.form.name == "Rune") {
        if (floor(tune_params("forms", "rune", "max_placed", 6)) < 1) return false;
        var _lane = _target.row div ROWS_PER_LANE;
        for (var i = 0; i < instance_number(obj_spells); i++) {
            var _existing = instance_find(obj_spells, i);
            if (_existing.form.name == "Rune" && _existing.target_col == _target.col && _existing.lane == _lane) return false;
        }
    }
    return true;
}

// Form at the center; effects and modifiers share an evenly spaced outer ring.
function draw_spell_slot_diagram(_spell, _x, _y, _size, _disabled = false) {
    if (!is_struct(_spell) || _spell.form == undefined) return;
    var _form = global.spell_glyphs.form[$ _spell.form];
    var _icons = [];
    for (var i = 0; i < array_length(_spell.form_mods); i++)
        array_push(_icons, global.spell_glyphs.modifier[$ _spell.form_mods[i]].icon);
    for (var i = 0; i < array_length(_spell.effects); i++) {
        var _fx = _spell.effects[i];
        array_push(_icons, global.spell_glyphs.effect[$ _fx.effect].icon);
        for (var j = 0; j < array_length(_fx.mods); j++)
            array_push(_icons, global.spell_glyphs.modifier[$ _fx.mods[j]].icon);
    }
    var _count = array_length(_icons);
    draw_spell_slot_glyph(_form.icon, _x, _y, _size * (_count == 0 ? 0.7 : 0.36), _disabled);
    var _radius = _size * 0.34;
    // Also shrink unusually long effect lists to keep neighboring glyphs apart.
    // Reserve the diagonal of each glyph's bounding square, keeping it inside
    // the circular slot and clear of both the center and neighboring glyphs.
    var _effect_size = min(_size * 0.22, 2 * _radius * sin(degtorad(180 / max(2, _count))) * 0.65);
    for (var i = 0; i < _count; i++) {
        var _angle = 90 + i * 360 / _count;
        draw_spell_slot_glyph(_icons[i],
            _x + lengthdir_x(_radius, _angle), _y + lengthdir_y(_radius, _angle), _effect_size, _disabled);
    }
}

function draw_glyph_group(_x, _y, _r, _glyph, _mod_ids, _base, _spread, _selected, _mouse = undefined) {
    var _out = { main: undefined, mod_r: -1, hover: "" };
    var _n = array_length(_mod_ids);
    var _px = [], _py = [];

    // connectors first, so circles sit on top
    draw_set_color(c_black);
    for (var k = 0; k < _n; k++) {
        var _spacing = min(_spread, 240 / max(1, _n - 1));
        var _a = _base + (k - (_n - 1) / 2) * _spacing;
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
        var _b = gui_circle_button(_px[k], _py[k], 24, _m.icon, _m.name, false, true, _mouse);
        if (_b.hover)    _out.hover = _m.name + "\n" + _m.desc + "\n(right-click to remove)";
        if (_b.rclicked) _out.mod_r = k;
    }

    _out.main = gui_circle_button(_x, _y, _r, _glyph.icon, _glyph.name, false, true, _mouse);
    if (_out.main.hover) _out.hover = _glyph.name + "\n" + _glyph.desc
                                    + "\n(click: select group, right-click: remove)";
    return _out;
}

function handle_triangle_click(_x, _y, _scale, _spr, _mouse, is_left) {
	var w = sprite_get_width(_spr) * _scale;
	var h = sprite_get_height(_spr) * _scale;
	
	//Top Vertice
	var x1;
	if (is_left)
		x1 =  _x + (h / 2);
	else
		x1 = _x - (h / 2);
	var y1 = _y - (w / 2);
	
	// Left/Right Vertice
	var x2;
	if (is_left) 
		x2 = _x - (h / 2);
	else
		x2 = _x + (h / 2);
	var y2 = _y;
	
	//Bottom Vertice
	var x3;
	if (is_left)
		x3 = _x + (h / 2);
	else
		x3 = _x - (h / 2);
	var y3 = _y + (w / 2);
	var is_hovering = point_in_triangle(_mouse.x, _mouse.y, x1, y1, x2, y2, x3, y3);
	return is_hovering;
}
