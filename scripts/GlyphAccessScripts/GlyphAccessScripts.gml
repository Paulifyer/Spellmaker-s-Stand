
//Describes the player's owned glyphs, default values in GlyphAccessScripts
global.owned = {
	form:	["projectile", "strike"],
	effect: ["harm"],
	modifier: []
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
	return (glyph_status(_type, _id) == GLYPH_STATE.owned);
}

///@description Unlocks glyphs for the player
///@param {string} _type	string representing the type (for access)
///@param {string} _id		string representing the glyph to be added
function unlock_glyph(_type, _id) {
	if (!array_contains(global.owned[$ _type], _id)) array_push(global.owned[$ _type], _id);
}

// Rebuild cumulative ownership from the room's level number, including direct entry.
function unlock_glyphs_through_level(_room) {
    var _number = real(string_delete(room_get_name(_room), 1, 9));
    global.owned = { form: [], effect: [], modifier: [] };
    for (var n = 1; n <= _number; n++) {
        var _config = global.level_config[$ "rm_level_" + string(n)];
        if (!is_struct(_config)) continue;
        var _glyphs = _config.unlocked_glyphs;
        for (var i = 0; i < array_length(_glyphs); i++) {
            var _glyph = _glyphs[i];
            var _catalog = global.spell_glyphs[$ _glyph.type];
            if (!is_struct(_catalog) || !variable_struct_exists(_catalog, _glyph.id))
                throw "Unknown unlocked glyph in level.json: " + string(_glyph.id);
            unlock_glyph(_glyph.type, _glyph.id);
        }
    }
}

///@description Checks if the spell is usable/valid
///@param {struct.loadout} _s The loadout of the spell being checked
///@returns {bool} if the spell is valid
function is_spell_usable(_s) {
	return spell_validation_message(_s) == "";
}

function sanitize_owned() {
    var _types = ["form", "effect", "modifier"];
    for (var t = 0; t < 3; t++) {
        if (!variable_struct_exists(global.owned, _types[t])) global.owned[$ _types[t]] = [];
        var _list = global.owned[$ _types[t]];
        for (var i = array_length(_list) - 1; i >= 0; i--)
            if (!variable_struct_exists(global.spell_glyphs[$ _types[t]], _list[i]))
                array_delete(_list, i, 1);
    }
}

