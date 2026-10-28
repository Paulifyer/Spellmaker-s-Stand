#macro WARDED_COST		1
#macro SKELETAL_COST	1
#macro BANNERET_COST	3



//dictionary holding mutation stucts
function init_mutations() {
	global.mutations = {};
	var _mut = new FrostWardedMut();
	register_mutation(_mut.key, _mut);
	_mut = new FireWardedMut();
	register_mutation(_mut.key, _mut);
	_mut = new LightningWardedMut();
	register_mutation(_mut.key, _mut);
	_mut = new SkeletalMut();
	register_mutation(_mut.key, _mut);
	_mut = new BanneretMut();
	register_mutation(_mut.key, _mut);
}

function normalize_mutation_keys(_setting) {
	if (_setting == undefined) return [];
	if (is_string(_setting) && _setting == "none") return [];
	var _input = is_array(_setting) ? _setting : [_setting];
	var _keys = []; var _wards = 0;
	for (var i = 0; i < array_length(_input); i++) {
		var _key = _input[i];
		if (!is_string(_key) || !variable_struct_exists(global.mutations, _key)) throw "Unknown mutation: " + string(_key);
		if (array_contains(_keys, _key)) throw "Duplicate mutation: " + _key;
		if (string_pos("-warded", _key) > 0) _wards++;
		if (_wards > 1) throw "An enemy may have at most one elemental ward";
		array_push(_keys, _key);
	}
	return _keys;
}

function mutation_total_cost(_setting) {
	var _keys = normalize_mutation_keys(_setting); var _cost = 0;
	for (var i = 0; i < array_length(_keys); i++) _cost += global.mutations[$ _keys[i]].cost;
	return _cost;
}

function enemy_has_mutation(_enemy, _key) {
	return variable_instance_exists(_enemy, "mutation_keys") && array_contains(_enemy.mutation_keys, _key);
}

function EnemyMutationSet(_setting) constructor {
	keys = normalize_mutation_keys(_setting); name = ""; cost = mutation_total_cost(keys);
	tint = array_contains(keys, "skeletal") ? c_gray : c_white;
	for (var i = 0; i < array_length(keys); i++) {
		if (i > 0) name += " "; name += global.mutations[$ keys[i]].name;
	}
	on_spawn = function(enemy) { for (var i = 0; i < array_length(keys); i++) global.mutations[$ keys[i]].on_spawn(enemy); };
	on_step = function(enemy) { for (var i = 0; i < array_length(keys); i++) global.mutations[$ keys[i]].on_step(enemy); };
	on_death = function(enemy) { for (var i = 0; i < array_length(keys); i++) global.mutations[$ keys[i]].on_death(enemy); };
}

function enemy_apply_mutations(_enemy, _setting) {
	_enemy.mutation_keys = normalize_mutation_keys(_setting);
	_enemy.mutation = undefined; _enemy.image_blend = c_white;
	if (array_length(_enemy.mutation_keys) == 0) return;
	_enemy.mutation = new EnemyMutationSet(_enemy.mutation_keys);
	_enemy.image_blend = _enemy.mutation.tint;
	_enemy.mutation.on_spawn(_enemy);
}

function mutation_description(_setting) {
	var _keys = normalize_mutation_keys(_setting);
	return array_length(_keys) > 0 ? new EnemyMutationSet(_keys) : undefined;
}


///@description This adds mutations to the global mutations struct
///@param {string} _key		the stuct parameter for the mutation
///@param {Struct.EnemyMutation} _m		The mutation object being registered
function register_mutation(_key, _m) { global.mutations[$ _key] = _m; }

///@description The template for mutation objects to be applied onto enemies
///@param {String}	_key		For struct access to global.mutations
///@param {String}	_name		Name of the mutation
///@param {Real}	_cost		Cost of the mutation on the wave budget
function EnemyMutation(_key, _name, _cost) constructor {
	key = _key; name = _name; cost = _cost;
	tint = c_white;
	on_spawn = function(enemy) {};
	on_step = function(enemy) {};
	on_damaged = function(enemy) {};
	on_death = function(enemy) {};
}

function FrostWardedMut() : EnemyMutation("frost-warded", "Frost-Warded", WARDED_COST) constructor {}
function FireWardedMut() : EnemyMutation("fire-warded", "Fire-Warded", WARDED_COST) constructor {}
function LightningWardedMut() : EnemyMutation("lightning-warded", "Lightning-Warded", WARDED_COST) constructor {}

// One predicate drives both protection and the visible shield.
function enemy_ward_key(_enemy) {
	var _keys = ["fire-warded", "frost-warded", "lightning-warded"];
	for (var i = 0; i < array_length(_keys); i++) if (enemy_has_mutation(_enemy, _keys[i])) return _keys[i];
	return "";
}

function enemy_ward_active(_enemy) {
	var _key = enemy_ward_key(_enemy);
	if (_key == "" || _enemy.hp <= 0) return false;
	var _status = (_key == "fire-warded") ? "burn" : ((_key == "frost-warded") ? "frost" : "lightning");
	return !combat_status_active(_enemy, _status);
}

function enemy_ward_sprite(_enemy) {
	var _wide = _enemy.ward_variant == "wide";
	switch (enemy_ward_key(_enemy)) {
		case "fire-warded": return _wide ? spr_ward_fire_wide : spr_ward_fire_narrow;
		case "frost-warded": return _wide ? spr_ward_frost_wide : spr_ward_frost_narrow;
		case "lightning-warded": return _wide ? spr_ward_lightning_wide : spr_ward_lightning_narrow;
	}
	return -1;
}

function enemy_visual_bounds(_enemy) {
	var _sprite = _enemy.sprite_index;
	return {
		x: _enemy.x + ((sprite_get_bbox_left(_sprite) + sprite_get_bbox_right(_sprite)) / 2 - sprite_get_xoffset(_sprite)) * _enemy.image_xscale,
		y: _enemy.y + ((sprite_get_bbox_top(_sprite) + sprite_get_bbox_bottom(_sprite)) / 2 - sprite_get_yoffset(_sprite)) * _enemy.image_yscale,
		width: max(1, (sprite_get_bbox_right(_sprite) - sprite_get_bbox_left(_sprite) + 1) * abs(_enemy.image_xscale)),
		height: max(1, (sprite_get_bbox_bottom(_sprite) - sprite_get_bbox_top(_sprite) + 1) * abs(_enemy.image_yscale))
	};
}

function enemy_draw_ward(_enemy) {
	if (!enemy_ward_active(_enemy)) { _enemy.ward_visible_since = -1; return; }
	var _sprite = enemy_ward_sprite(_enemy);
	if (_sprite < 0) return;
	var _execution = combat_execution_state();
	var _clock = is_struct(_execution) ? _execution.clock : 0;
	if (_enemy.ward_visible_since < 0) _enemy.ward_visible_since = _clock;
	var _elapsed = (_clock - _enemy.ward_visible_since) * sprite_get_speed(_sprite) / TARGET_ROOM_SPEED;
	// The supplied references use frame 1 as appearance, then loop frames 2 onward.
	var _frame = (_elapsed < 1) ? 0 : 1 + (floor(_elapsed - 1) mod (sprite_get_number(_sprite) - 1));
	var _bounds = enemy_visual_bounds(_enemy);
	var _scale = _bounds.width * 1.15 / max(1, sprite_get_bbox_right(_sprite) - sprite_get_bbox_left(_sprite) + 1);
	draw_sprite_ext(_sprite, _frame, _bounds.x, _bounds.y, _scale, _scale, 0, c_white, 1);
}

// Status state is independent from scheduled work; the room queue follows lineage.
function enemy_capture_status(_enemy) { return combat_status_capture(_enemy); }
function enemy_age_status(_state, _frames) { combat_status_advance(_state, _frames, false); }
function enemy_restore_status(_enemy, _state) {
	combat_status_restore(_enemy, _state);
	_enemy.my_speed = _enemy.base_speed * (1 - _enemy.slow_amt);
}

function SkeletalMut() : EnemyMutation("skeletal", "Skeletal", SKELETAL_COST) constructor {
	tint = c_gray;
	on_death = function(enemy) {
		var _retained = [];
		for (var i = 0; i < array_length(enemy.mutation_keys); i++) if (enemy.mutation_keys[i] != "skeletal") array_push(_retained, enemy.mutation_keys[i]);
		var _lineage = enemy_get_lineage(enemy);
		_lineage.gap = true;
		_lineage.target = noone;
		var _e_struct = {
			revived_mutations: _retained,
			lineage: _lineage,
			e_path_index : enemy.path_index,
			e_path_position : enemy.path_position,
			ex : enemy.x,
			ey : enemy.y,
			held_enemy : enemy.object_index,
			status_state : enemy_capture_status(enemy),
			wave_owner : enemy.wave_owner
		};
		var _rev_mngr = instance_create_layer(1024, 1024, "Instances", obj_revive_manager, _e_struct) //location is arbitrary, obj is invisible with no collision
	};
}

function BanneretMut() : EnemyMutation("banneret", "Banneret", BANNERET_COST) constructor {
}

function enemy_is_bonepile(_enemy) {
	return variable_instance_exists(_enemy, "is_bonepile") && _enemy.is_bonepile;
}

function enemy_banner_source_active(_enemy) {
	return _enemy.hp > 0 && _enemy.is_targetable && !enemy_is_bonepile(_enemy) && enemy_has_mutation(_enemy, "banneret");
}

function enemy_banner_speed(_target) {
	if (_target.hp <= 0 || enemy_is_bonepile(_target)) return 1;
	var _best = 1;
	var _radius = max(0, floor(tune_params("mutations", "banneret", "radius_tiles", 1)));
	for (var i = 0; i < instance_number(obj_enemy_parent); i++) {
		var _source = instance_find(obj_enemy_parent, i);
		if (_source == _target || !enemy_banner_source_active(_source)) continue;
		var _tile = world_to_grid(_source.x, _source.y);
		if (_tile == undefined) continue;
		if (enemy_overlaps_region(_target, _tile.col - _radius, _tile.col + _radius, _tile.lane - _radius, _tile.lane + _radius))
			_best = max(_best, tune_params("mutations", "banneret", "speed_mult", 1.3));
	}
	return _best;
}

function enemy_draw_banner(_enemy) {
	if (!enemy_banner_source_active(_enemy)) return;
	var _bounds = enemy_visual_bounds(_enemy);
	var _height = sprite_get_bbox_bottom(spr_banneret_speed) - sprite_get_bbox_top(spr_banneret_speed) + 1;
	var _scale = _bounds.height * 1.15 / max(1, _height);
	draw_sprite_ext(spr_banneret_speed, 0, _bounds.x + _bounds.width * 0.3, _bounds.y - _bounds.height * 0.15, _scale, _scale, 0, c_white, 1);
}

function NoneMut() : EnemyMutation("None", "none", 0) constructor {
}
