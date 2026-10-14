var _mx = device_mouse_x_to_gui(0), _my = device_mouse_y_to_gui(0);
hover_text = "";
draw_sprite(spr_spell_crafting_gui, 0, 0, 0);
draw_set_color(c_black);

var _spell = global.spellbook[sel];

// ---- Glyph palette (left page) ----
for (var c = 0; c < 3; c++) {
    var _key = column_keys[c];
    var _ids = global.glyph_order[$ _key];
    for (var g = 0; g < array_length(_ids); g++) {
        var _id    = _ids[g];
        var _glyph = global.spell_glyphs[$ _key][$ _id];
        var _cur   = (_spell != undefined) ? _spell[$ _key] : undefined;

        var _b = gui_circle_button(160 + g * 190, glyph_row_y[c], 60, _glyph.icon, _glyph.name, _cur == _id);
        if (_b.hover) hover_text = _glyph.name + "  (cost " + string(_glyph.cost) + ")\n" + _glyph.desc;
        if (_b.clicked) {
            _spell = spell_ensure(sel);
            _spell[$ _key] = (_cur == _id) ? undefined : _id;   // click again to remove
            _spell = spell_prune(sel);
        }
    }
}

// ---- Placed glyphs around the hexagram ----
for (var c = 0; c < 3; c++) {
    var _px = craft_cx + lengthdir_x(190, slot_angles[c]);
    var _py = craft_cy + lengthdir_y(190, slot_angles[c]);
    var _key = column_keys[c];
    var _id  = (_spell != undefined) ? _spell[$ _key] : undefined;

    if (_id == undefined) {
        draw_set_alpha(0.4);
        draw_circle(_px, _py, 45, true);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        draw_text(_px, _py, column_titles[c]);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_alpha(1);
    } else {
        var _glyph = global.spell_glyphs[$ _key][$ _id];
        var _b = gui_circle_button(_px, _py, 45, _glyph.icon, _glyph.name, false);
        if (_b.hover) hover_text = _glyph.name + "  (click to remove)\n" + _glyph.desc;
        if (_b.clicked) {
            _spell[$ _key] = undefined;
            _spell = spell_prune(sel);
        }
    }
}

// ---- Mana / cost ----
draw_text(960, 97, "Cost: " + string(spell_cost(_spell)));
if (_spell != undefined && _spell.form == undefined) {
    draw_set_color(c_red);
    draw_text(960, 140, "Needs a form to be usable");
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
    if (_b.hover && _sp != undefined && _sp.name != "") hover_text = _sp.name;
    if (_b.clicked) { sel = i; naming = false; }
}

// ---- Crystal ball: enemies (click to cycle) ----
var _n = array_length(enemies_in_level);
if (_n > 0) {
    var _info = global.enemy_info[$ object_get_name(enemies_in_level[enemy_view])];
    if (_info != undefined) {
        if (_info.icon != undefined) draw_sprite(_info.icon, 0, 1714, 310);   // centered origin assumed
        draw_set_halign(fa_center);
        draw_text(1714, 520, _info.name);
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
if (!close_requested && !naming && gui_button(1340, 950, 150, 70, "Start", false)) {
    close_requested = true;
    alarm[0] = 1;
}

draw_set_color(c_white);