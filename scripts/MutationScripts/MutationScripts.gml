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

function FrostWardedMut() : EnemyMutation("frost-warded", "Frost-Warded", WARDED_COST) constructor {
	tint = c_purple;
	on_spawn = function(enemy) {
		enemy.dmg_reduction = 0.5;	
	};
	on_step = function(enemy) {
		if (enemy.slow_amt > 0) {
			enemy.dmg_reduction = 0;
		} else {
			enemy.dmg_reduction = 0.5;
		}
	};
}

function FireWardedMut() : EnemyMutation("fire-warded", "Fire-Warded", WARDED_COST) constructor {
	tint = c_purple;
	on_spawn = function(enemy) {
		enemy.dmg_reduction = 0.5;	
	};
	on_step = function(enemy) {
		if (enemy.burn_timer > 0) {
			enemy.dmg_reduction = 0;
		} else {
			enemy.dmg_reduction = 0.5;
		}
	};
}

function LightningWardedMut() : EnemyMutation("lightning-warded", "Lightning-Warded", WARDED_COST) constructor {
	tint = c_purple;
	on_spawn = function(enemy) {
		enemy.dmg_reduction = 0.5;	
	};
	on_step = function(enemy) {
		if (enemy.stun_timer > 0) {
			enemy.dmg_reduction = 0;
		} else {
			enemy.dmg_reduction = 0.5;
		}
	};
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

function NoneMut() : EnemyMutation("None", "none", 0) constructor {
}
