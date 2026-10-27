/// @description Draws UI elements for spellbook
// Controls selection of spells too

var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
hover_text = "";
draw_sprite(spr_spell_crafting_gui, 0, 0, 0);
draw_set_color(c_black);
draw_set_font(fnt_Arcane);


var _spell = global.spellbook[sel];

var _has_form = (_spell != undefined && _spell.form != undefined);

// ---- Glyph palette (left page) ----
for (var c = 0; c < 3; c++) {
    var _key = column_keys[c];
    var _ids = global.glyph_order[$ _key];
    for (var g = 0; g < array_length(_ids); g++) {
        var _id    = _ids[g];
        var _glyph = global.spell_glyphs[$ _key][$ _id];

        // form always available; the rest need a form, and modifiers must suit it
        var _status = glyph_status(_key, _id);
        var _reason = spell_addition_message(_spell, _key, _id, active_group);
		var _enabled = _status == GLYPH_STATE.owned && _reason == "";

        var _current = (c == 0 && _has_form) ? (_spell.form == _id) : false;
		var _locked = _status == GLYPH_STATE.locked;
		var _display_icon = _locked ? undefined : _glyph.icon;
		var _display_label = _locked ? "?" : _glyph.name;
		
		// Number of Glyphs per row
		var _per_row = 4;
		
		var _px = 140 + (g mod _per_row) * 150;
		var _py = glyph_row_y[c] + (g div _per_row) *130;
		
        var _b = gui_circle_button(_px, _py, 55, _display_icon, _display_label, _current, _enabled);

        if (_b.hover) {
			if (_locked) {
				hover_text = "???\nNot unlocked yet...";
			} else {
				hover_text = _glyph.name + "  (cost " + string(_glyph.cost) + ")\n" + _glyph.desc;
				if (_status == GLYPH_STATE.disabled) hover_text += "\nSome force has disabled this?";
                if (!_enabled && _reason != "") hover_text += "\n" + _reason;
			}
        }
        if (_b.clicked) {
            _spell = spell_ensure(sel);
            var _msg = spell_add_glyph(_spell, _key, _id, active_group);
            if (_msg != "") { notice = _msg; notice_timer = 120; }
            else if (_key == "form")    active_group = -1;
            else if (_key == "effect") active_group = array_length(_spell.effects) - 1;
            _spell = spell_prune(sel);
            _has_form = (_spell != undefined && _spell.form != undefined);
        }
    }
}

// ---- Crafting circle: form group in the centre ----
if (_has_form) {
    var _fg = draw_glyph_group(craft_cx, craft_cy, 45, global.spell_glyphs.form[$ _spell.form],
                               _spell.form_mods, 90, 120, active_group == -1);
    if (_fg.hover != "") hover_text = _fg.hover;
    if (_fg.main.clicked)  active_group = -1;
    if (_fg.main.rclicked) { spell_clear(_spell); active_group = -1; }   // removing the form clears the spell
    if (_fg.mod_r >= 0)    array_delete(_spell.form_mods, _fg.mod_r, 1);
} else {
    draw_set_alpha(0.4);
    draw_circle(craft_cx, craft_cy, 45, true);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_text(craft_cx, craft_cy, "Form");
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_alpha(1);
}

// ---- Effect groups around it ----
_has_form = (_spell != undefined && _spell.form != undefined);   // may have just been cleared
var _rm_effect = -1;
var _count = _has_form ? array_length(_spell.effects) : 0;

// The JSON limit permits up to seven effects in the documented eight-glyph spell.
// Keep existing excess groups visible so an invalid spell can still be repaired.
var _effect_slots = max(1, spell_max_glyphs() - 1, _count);
for (var e = 0; e < _effect_slots; e++) {
    var _ang = 90 + e * 360 / _effect_slots;
    var _gx = craft_cx + lengthdir_x(200, _ang);
    var _gy = craft_cy + lengthdir_y(200, _ang);

    if (e < _count) {
        var _fx = _spell.effects[e];
        var _gr = draw_glyph_group(_gx, _gy, 45, global.spell_glyphs.effect[$ _fx.effect],
                                   _fx.mods, _ang, 50, active_group == e);
        if (_gr.hover != "") hover_text = _gr.hover;
        if (_gr.main.clicked)  active_group = e;
        if (_gr.main.rclicked) _rm_effect = e;
        if (_gr.mod_r >= 0) {
            if (spell_sequence_valid(_spell, -1, e, _gr.mod_r)) {
                array_delete(_fx.mods, _gr.mod_r, 1);
            } else {
                notice = "Remove the repeated effect before removing its Delay";
                notice_timer = 120;
            }
        }
    } else if (_has_form && e == _count) {
        draw_set_alpha(0.4);
        draw_circle(_gx, _gy, 45, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_text(_gx, _gy, "+ Effect");
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_alpha(1);
    }
}
if (_rm_effect >= 0) {
    if (spell_sequence_valid(_spell, _rm_effect)) {
        array_delete(_spell.effects, _rm_effect, 1);   // its modifiers go with it
        active_group = -1;
    } else {
        notice = "This group contains the Delay separating repeated effects";
        notice_timer = 120;
    }
}

// ---- Clear button ----
if (_has_form && gui_button(1340, 880, 150, 50, "Clear spell", false)) {
    spell_clear(_spell);
    active_group = -1;
}
_spell = spell_prune(sel);   // (name-only spells stay; empty ones free the slot)

// ---- Mana / cost ----
var _player = instance_find(Player, 0);
var _max_mana = instance_exists(_player) ? max(0, _player.max_mana) : 0;
var _mana_preview = spell_mana_preview(_spell, _max_mana);
var _expensive_slots = spellbook_expensive_slots(_max_mana);
var _start_message = spellbook_start_message(_max_mana);
var _spell_message = _has_form ? spell_validation_message(_spell) : "";
draw_text(960, 63, "Glyphs: " + string(spell_glyph_count(_spell)) + " / " + string(spell_max_glyphs()));
draw_text(960, 97, string(_mana_preview.cost) + " / " + string(_max_mana) + " mana");
var _bar_x = 960, _bar_y = 132, _bar_w = 450, _bar_h = 22;
draw_set_color(#263442);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, false);
if (_mana_preview.fill > 0) {
    draw_set_color(_mana_preview.too_expensive ? c_red : c_aqua);
    draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w * _mana_preview.fill, _bar_y + _bar_h, false);
}
draw_set_color(c_black);
draw_rectangle(_bar_x, _bar_y, _bar_x + _bar_w, _bar_y + _bar_h, true);
if (_mana_preview.too_expensive) {
    draw_set_color(c_red);
    draw_text(960, 163, "Spell is too expensive");
    draw_set_color(c_black);
} else if (_spell_message != "") {
    draw_set_color(c_red);
    draw_text(960, 163, _spell_message);
    draw_set_color(c_black);
}
if (notice_timer > 0 && notice != "") {
    draw_text_ext(960, 205, notice, 26, 500);
}
if (_spell != undefined && _spell.form == undefined) {
    draw_set_color(c_red);
    draw_text(960, 163, "Needs a form to be usable");
    draw_set_color(c_black);
}

// ---- Spell name field ----
var _name = (_spell != undefined) ? _spell.name : "";
draw_text(990, 808, _name + (naming && (current_time div 500) mod 2 == 0 ? "|" : ""));
if (mouse_check_button_pressed(mb_left)) {
    var _in = point_in_rectangle(_mx, _my, 985, 795, 1400, 835);
    if (_in && !naming) { naming = true; keyboard_string = _name; }
    else if (!_in && naming) { naming = false; spell_prune(sel); }
}

// ---- Spell slots 1-3 ----
var _slot_x = [1023, 1141, 1256];
for (var i = 0; i < SPELL_SLOTS; i++) {
    var _sp = global.spellbook[i];
    var _ic = (_sp != undefined && _sp.form != undefined) ? global.spell_glyphs.form[$ _sp.form].icon : undefined;
    var _b = gui_circle_button(_slot_x[i], 990, 30, _ic, string(i + 1), i == sel);
	var _too_expensive = spell_mana_preview(_sp, _max_mana).too_expensive;
	var _bad_spell = (_sp != undefined && _sp.form != undefined && !is_spell_usable(_sp)) || _too_expensive;
	if (_bad_spell) {
		draw_set_colour(c_red);
		draw_circle(_slot_x[i], 990, 30, true);
		draw_set_colour(c_white);
	}
    if (_b.hover && _sp != undefined && _sp.name != "") hover_text = _sp.name;
    if (_b.hover && _sp != undefined && _sp.form != undefined && !is_spell_usable(_sp)) hover_text = spell_validation_message(_sp);
    if (_b.hover && _too_expensive) hover_text = "Spell " + string(i + 1) + " is too expensive. Reduce its mana cost.";
    if (_b.clicked) { sel = i; naming = false; }
}

// ---- Crystal ball: enemies (click to cycle) ----
var _n = array_length(enemies_in_level);
if (_n > 0) {
    var _entry = enemies_in_level[enemy_view];
	var _info = global.enemy_info[$ object_get_name(_entry.enemy)];
	var _mut = (_entry.mutation != undefined) ? global.mutations[$ _entry.mutation] : undefined;
    if (_info != undefined) {
        if (_info.icon != undefined) draw_sprite_ext(_info.icon, 0, 1714, 400, 0.75, 0.75, 0, (_mut != undefined) ? _mut.tint : c_white, 1);   // centered origin assumed
        draw_set_halign(fa_center);
        draw_text(1714, 520, ((_mut != undefined) ? _mut.name + " " : "") + _info.name);
        draw_set_halign(fa_left);
        if (point_distance(_mx, _my, 1714, 310) <= 143) {
            hover_text = _info.name + "\n" + _info.notes + "\n(click for next enemy)";
            if (mouse_check_button_pressed(mb_left)) enemy_view = (enemy_view + 1) mod _n;
        }
    }
}

// ---- Description scroll ----

draw_text_ext(1610, 680, hover_text, 26, 220);

// ---- Start ----
if (_start_message != "") {
    draw_set_color(c_red);
    draw_text(960, 1040, "Fix highlighted spell slots before starting");
    draw_set_color(c_black);
    draw_set_alpha(0.45);
}
if (!close_requested && !naming && gui_button(1340, 950, 150, 70, "Start", false)) {
    if (_start_message != "") {
        notice = _start_message;
        notice_timer = 120;
    } else {
        close_requested = true;
		start_next_wave();
		audio_play_sound(snd_button_click, 0, false);
        alarm[0] = 1;
    }
}
draw_set_alpha(1);

draw_set_color(c_white);
