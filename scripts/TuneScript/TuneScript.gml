
///@description This function tries to fetch the tuning data, ensure it is called before game starts in scripts
function load_tuning() {
	global.tuning = {};
	if (!file_exists("tune.json")) {
		show_debug_message("Tuning: tune.json not found, using defaults!");
		return;
	}
	try {
		var _buf = buffer_load("tune.json");
		var _json = buffer_read(_buf, buffer_string);
		buffer_delete(_buf);
		var _data = json_parse(_json);
		if (is_struct(_data)) global.tuning = _data;
	} catch (_e) {
		show_debug_message("TUNING: tuning.json has a syntax error, using defaults.");
	}
}

///@description This function fetches values for glyphs
///@param {string} _group
///@param {string} _id
///@param {string} _key
///@param {Real} _default
// Structured/string settings are validated by their consumer instead of numeric fallback.
function tune_setting(_group, _id, _key, _default) {
	var _g = global.tuning[$ _group];
	if (!is_struct(_g)) return _default;
	var _entry = _g[$ _id];
	if (!is_struct(_entry)) return _default;
	var _value = _entry[$ _key];
	return (_value == undefined) ? _default : _value;
}

function tune_params(_group, _id, _key, _default) {
	var _g = global.tuning[$ _group];
	if (!is_struct(_g)) return _default;
	var _e = _g[$ _id];
	if (!is_struct(_e)) return _default;
	var _v = _e[$ _key];
	return is_real(_v) ? _v : _default;
}

///@description This function fetches player/gameplay json values
///@param {string} _group
///@param {string} _id
///@param {Real} _default
function tune_value(_group, _key, _default) {
	var _g = global.tuning[$ _group];
	if (!is_struct(_g)) return _default;
	var _v = _g[$ _key];
	return is_real(_v) ? _v : _default;
}

/// @description Read a boolean feature switch from tune.json
function tune_flag(_group, _key, _default = false) {
	if (!variable_global_exists("tuning")) return _default;
	var _g = global.tuning[$ _group];
	if (!is_struct(_g)) return _default;
	var _v = _g[$ _key];
	return is_bool(_v) ? _v : _default;
}

///@description This function fetches enemy json values
///@param {string} _id enemy name
///@param {string} _key parameter
///@param {Real} _default default value
function tune_enemy(_id, _key, _default) {
	var _g = global.tuning[$ "enemies"];
	if (!is_struct(_g)) return _default;
	var _e = _g[$ _id];
	if (!is_struct(_e)) return _default;
	var _v = _e[$ _key];
	return is_real(_v) ? _v : _default;
}

