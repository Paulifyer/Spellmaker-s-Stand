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

function SkeletalMut() : EnemyMutation("skeletal", "Skeletal", SKELETAL_COST) constructor {
	tint = c_gray;
	on_death = function(enemy) {
		var _e_struct = {
			e_path_index : enemy.path_index,
			e_path_position : enemy.path_position,
			ex : enemy.x,
			ey : enemy.y,
			held_enemy : enemy.object_index,
			wave_owner : enemy.wave_owner
		};
		var _rev_mngr = instance_create_layer(1024, 1024, "Instances", obj_revive_manager, _e_struct) //location is arbitrary, obj is invisible with no collision
	};
}

function BanneretMut() : EnemyMutation("banneret", "Banneret", BANNERET_COST) constructor {
}

function NoneMut() : EnemyMutation("None", "none", 0) constructor {
}
