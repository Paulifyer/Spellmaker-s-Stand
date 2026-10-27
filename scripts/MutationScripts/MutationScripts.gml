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

// Copy mutable timers so each stage owns its queue without retaining a dead instance.
function enemy_capture_status(_enemy) {
	var _pending = [];
	for (var i = 0; i < array_length(_enemy.pending_effects); i++) {
		var _p = _enemy.pending_effects[i];
		array_push(_pending, { timer: _p.timer, fx: _p.fx, spell: _p.spell });
	}
	return {
		burn_dmg: _enemy.burn_dmg, burn_timer: max(0, _enemy.burn_timer),
		slow_amt: _enemy.slow_amt, slow_timer: max(0, _enemy.slow_timer),
		stun_timer: max(0, _enemy.stun_timer),
		stun_immune_timer: max(0, _enemy.stun_immune_timer),
		hex_timer: max(0, _enemy.hex_timer), pending_effects: _pending
	};
}

// Time passes while no target exists. Burn ticks in this gap deal no damage.
function enemy_age_status(_state, _frames) {
	_frames = max(0, _frames);
	_state.burn_timer = max(0, _state.burn_timer - _frames);
	_state.slow_timer = max(0, _state.slow_timer - _frames);
	if (_state.slow_timer == 0) _state.slow_amt = 0;
	_state.hex_timer = max(0, _state.hex_timer - _frames);
	var _stun = _state.stun_timer;
	_state.stun_timer = max(0, _stun - _frames);
	if (_stun > 0 && _stun <= _frames) {
		var _charged = round(tune_params("effects", "lightning", "stun_immune_duration", 3) * TARGET_ROOM_SPEED);
		_state.stun_immune_timer = max(0, _charged - (_frames - _stun));
	} else {
		_state.stun_immune_timer = max(0, _state.stun_immune_timer - _frames);
	}
	for (var i = 0; i < array_length(_state.pending_effects); i++) {
		// Negative values preserve which effects became due first during the gap.
		_state.pending_effects[i].timer -= _frames;
	}
}

function enemy_restore_status(_enemy, _state) {
	_enemy.burn_dmg = _state.burn_dmg;
	_enemy.burn_timer = _state.burn_timer;
	_enemy.slow_amt = (_state.slow_timer > 0) ? _state.slow_amt : 0;
	_enemy.slow_timer = _state.slow_timer;
	_enemy.stun_timer = _state.stun_timer;
	_enemy.stun_immune_timer = _state.stun_immune_timer;
	_enemy.hex_timer = _state.hex_timer;
	_enemy.pending_effects = _state.pending_effects;
	_enemy.my_speed = _enemy.base_speed * (1 - _enemy.slow_amt);
}

// Apply overdue effects once to the new pile, earliest due first; ties keep insertion order.
function enemy_apply_overdue_effects(_enemy) {
	while (true) {
		var _first = -1;
		for (var i = 0; i < array_length(_enemy.pending_effects); i++) {
			var _p = _enemy.pending_effects[i];
			if (_p.timer > 0) continue;
			if (_first < 0 || _p.timer < _enemy.pending_effects[_first].timer) _first = i;
		}
		if (_first < 0) break;
		var _p = _enemy.pending_effects[_first];
		array_delete(_enemy.pending_effects, _first, 1);
		apply_effect_group(_p.spell, _enemy, _p.fx);
	}
}

function SkeletalMut() : EnemyMutation("skeletal", "Skeletal", SKELETAL_COST) constructor {
	tint = c_gray;
	on_death = function(enemy) {
		var _e_struct = {
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
