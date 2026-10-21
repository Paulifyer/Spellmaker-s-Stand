
//Describes the player's owned glyphs, default values in GlyphAccessScripts
global.owned = {
	form:	["projectile", "beam", "strike"],
	effect: ["harm"],
	modifier: ["area", "amplify"]
};

enum GLYPH_STATE {
	disabled,
	locked,
	owned
}

/// @description Template for a loadout for a spell
/// @param {string} _name name of the spell
/// @param {string} _form name of the glyph
/// @param {array<string>} _form_mods array holding the names of the form mods
/// @param {array<struct>} _effects holds the effects and the mods on the effects
function loadout(_name, _form, _form_mods, _effects) constructor {
	self.name = _name;
	self.form = _form;
	self.form_mods = _form_mods;
	self.effects = _effects;
}

///@description converts a glyph state to a string
///@param {real} _state GLYPH_STATE
///@returns {real} string equivalent of GLYPH_STATE
function glyph_state_to_string(_state) {
	var _glyph_state_str = ["disabled", "locked", "owned"];
	return _glyph_state_str[_state];
}

///@description Checks availability of glyph
///@param {string} _type	string representing the type of glyph (for access)
///@param {string} _id		string representing the glyph to be checked
///@return {real}
function glyph_status(_type, _id) {
	if (!array_contains(global.owned[$ _type], _id)) return GLYPH_STATE.locked;
	return GLYPH_STATE.owned;
}

///@description Checks if glyph is owned
///@param {string} _type	string representing the type of glyph
///@param {string} _id		string representing the glyph to be checked
///@return {bool}
function is_glyph_available(_type, _id) {
	if (glyph_status(_type, _id) == GLYPH_STATE.locked) show_debug_message($"LOCKED, {_type}, {_id}");
	return (glyph_status(_type, _id) == GLYPH_STATE.owned);
}

///@description Unlocks glyphs for the player
///@param {string} _type	string representing the type (for access)
///@param {string} _id		string representing the glyph to be added
function unlock_glyph(_type, _id) {
	if (!array_contains(global.owned[$ _type], _id)) array_push(global.owned[$ _type], _id);
}

///@description Checks if the spell is usable/valid
///@param {struct.loadout} _s The loadout of the spell being checked
///@returns {bool} if the spell is valid
function is_spell_usable(_s) {
	if (_s == undefined || _s.form == undefined) return false;
	if(!is_glyph_available("form", _s.form)) return false;
	for (var i = 0; i < array_length(_s.form_mods); i++) 
		if (!is_glyph_available("modifier", _s.form_mods[i])) return false;
	for (var e = 0; e < array_length(_s.effects); e++) {
		if (!is_glyph_available("effect", _s.effects[e].effect)) return false;
		for (var i = 0; i < array_length(_s.effects[e].mods); i++)
			if (!is_glyph_available("modifier", _s.effects[e].mods[i])) return false;
	}
	return true;
}

function sanitize_owned() {
    var _types = ["form", "element", "modifier"];
    for (var t = 0; t < 3; t++) {
        if (!variable_struct_exists(global.owned, _types[t])) global.owned[$ _types[t]] = [];
        var _list = global.owned[$ _types[t]];
        for (var i = array_length(_list) - 1; i >= 0; i--)
            if (!variable_struct_exists(global.spell_glyphs[$ _types[t]], _list[i]))
                array_delete(_list, i, 1);
    }
}

