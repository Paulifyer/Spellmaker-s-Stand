global.level_config = load_level_wave_configs("level.json");

/// @description Parse one level's wave configuration from a decoded level.json struct
/// @param {struct} _level_data A level entry containing enemy_roster and level_wave_config
/// @returns {struct.LevelWaveConfig}
function parse_level_data(_level_data)
{
	if (!is_struct(_level_data))
		throw "Level wave data must be a struct";

	if (!variable_global_exists("EnemyCatalog"))
		init_enemy_catalog();
		
	if (!variable_global_exists("mutations"))
		init_mutations();
	
	if (!variable_global_exists("enemy_info"))
		init_enemy_info();
	
	if (!variable_global_exists("tuning"))
		load_tuning();

	var _json_roster = _level_data[$ "enemy_roster"];
	var _json_config = _level_data[$ "level_wave_config"];
	var _json_glyphs = _level_data[$ "unlocked_glyphs"];
	var _roster = [];
	
	for (var i = 0; i < array_length(_json_roster); i++)
	{
		var _json_entry = _json_roster[i];
		var _enemy_key = _json_entry[$ "enemy"];
		var _enemy = global.EnemyCatalog[$ _enemy_key];

		if (!is_struct(_enemy))
			throw "Unknown enemy in level wave data: " + string(_enemy_key);

		// "none" is the JSON representation of no mutation.
		var _mutation = _json_entry[$ "mutation"];
		if (_mutation == "none")
			_mutation = undefined;

		_roster[i] = new EnemyWaveDefinition(
			_enemy,
			_json_entry[$ "weight_setting"],
			_json_entry[$ "min_setting"],
			_json_entry[$ "max_setting"],
			_mutation
		);
	}

	return {
		level_wave_config:	new LevelWaveConfig (
									_json_config[$ "wave_count"],
									_json_config[$ "starting_budget"],
									_json_config[$ "ending_budget"],
									_json_config[$ "difficulty_curve"],
									_roster
							),
		unlocked_glyphs:	_json_glyphs
	};
}

/// @description Load every level wave configuration from an included JSON file
/// @param {string} _path Defaults to level.json
/// @returns {struct} A struct keyed by level name, such as rm_level_1
function load_level_wave_configs(_path = "level.json")
{
	if (!file_exists(_path))
		throw "Level wave data file not found: " + _path;

	var _buffer = buffer_load(_path);
	var _json = buffer_read(_buffer, buffer_string);
	buffer_delete(_buffer);

	var _data = json_parse(_json);
	if (!is_struct(_data))
		throw "Level wave data must have a JSON object at its root";

	var _configs = {};
	var _level_names = variable_struct_get_names(_data);

	for (var i = 0; i < array_length(_level_names); i++)
	{
		var _level_name = _level_names[i];
		if (_level_name == "_readme")
			continue;

		_configs[$ _level_name] = parse_level_data(_data[$ _level_name]);
	}

	return _configs;
}