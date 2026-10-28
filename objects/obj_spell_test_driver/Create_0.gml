// Developer-only room: inherit the manager's clock/flush events, not its campaign setup.
combat_execution = combat_execution_create();
paused = false; game_over = false; money = 0; village_hp = 30; active_enemy_count = 0;
level_paths = [Path1, Path2, Path3, Path4, Path5, Path6];
display_set_gui_size(1920, 1080);
test_col = 5; test_lane = 2; test_case = 0; enemy_case = 0; next_beam_tick = -1;
watched_lineage = undefined; description = "";

test_plan = function(_form, _effects, _mods = []) {
	var _compiled = compile_spell({form: _form, form_mods: _mods, effects: _effects});
	return {compiled: _compiled, form: _compiled.form, effects: _compiled.effects,
		area: _compiled.area, pierce: _compiled.pierce, caster: noone, col: c_white,
		x: GRID_X0, y: global.lane_top[test_lane], target_col: test_col,
		target_row: test_lane * ROWS_PER_LANE, cast_id: combat_next_id(), delivery_index: 0,
		hit_state: {contacts: [], applications: {}, epoch: 0}};
};

start_case = function(_case) {
	enemy_case = 0;
	instance_activate_object(obj_enemy_parent);
	instance_activate_object(obj_revive_manager);
	with (obj_enemy_parent) instance_destroy();
	with (obj_revive_manager) instance_destroy();
	combat_execution = combat_execution_create(); paused = false; next_beam_tick = -1;
	test_case = _case;
	var _actor = instance_create_layer(GRID_X0 + (test_col + 1.5) * TILE_W,
		global.lane_top[test_lane] + LANE_H / 2, "Instances", obj_spell_test_enemy);
	_actor.wave_owner = id; active_enemy_count = 1;
	var _effects = [{effect: "pull", mods: ["delay"]}, {effect: "harm", mods: []}];
	var _form = "strike"; var _mods = [];
	switch (_case) {
		case 1: _effects[0].mods = []; description = "No Delay: Pull starts; immediate Harm misses the travelling enemy."; break;
		case 2: description = "Strike + Pull + Delay + Harm: Harm reselects the tile after one second."; break;
		case 3: _form = "rune"; description = "Triggered Rune delivery: delayed Harm reselects the original trigger tile."; break;
		case 4:
			_form = "projectile"; _mods = ["area"];
			_actor.x = GRID_X0 + (test_col + 2.5) * TILE_W;
			_effects = [{effect: "harm", mods: ["delay"]}, {effect: "harm", mods: []}];
			description = "Projectile AoE: first Harm misses; move the enemy into the area with M before delayed Harm.";
			break;
		case 5:
			_form = "beam"; _actor.x = GRID_X0 + (test_col + 0.5) * TILE_W;
			_effects = [{effect: "harm", mods: ["delay"]}, {effect: "harm", mods: []}];
			description = "Two Beam deliveries 0.25 seconds apart: both delayed Harm applications must run.";
			next_beam_tick = 15;
			break;
		case 6:
			_form = "projectile"; _actor.hp = 50; enemy_apply_mutations(_actor, "skeletal");
			_effects = [{effect: "harm", mods: ["delay"]}, {effect: "harm", mods: []}];
			description = "Skeletal direct hit: lethal Harm, then queued Harm follows the lineage and destroys its pile.";
			break;
	}
	plan = test_plan(_form, _effects, _mods);
	watched_lineage = enemy_get_lineage(_actor);
	spell_deliver(plan, (_form == "beam" || (_form == "projectile" && !plan.area)) ? _actor : noone,
		test_col, test_lane, plan.area ? 1 : 0);
};
start_case(2);

// F1-F6 use real enemy objects, so Draw/lifecycle/path events can be checked in-engine.
spawn_test_enemy = function(_object, _col, _lane, _mutations = [], _moving = false) {
	var _enemy = instance_create_layer(GRID_X0 + (_col + 0.5) * TILE_W,
		global.lane_top[_lane] + LANE_H / 2, "Instances", _object);
	_enemy.wave_owner = id; _enemy.lane = _lane; active_enemy_count++;
	enemy_apply_mutations(_enemy, _mutations);
	if (_moving) {
		var _path = level_paths[_lane];
		with (_enemy) path_start(_path, my_speed, path_action_stop, true);
		enemy_initialize_mole_marker(_enemy, level_paths[_lane]);
	} else _enemy.base_speed = 0;
	return _enemy;
};
start_enemy_case = function(_case) {
	start_case(2);
	enemy_case = _case;
	with (obj_enemy_parent) instance_destroy();
	combat_execution = combat_execution_create(); active_enemy_count = 0; watched_lineage = undefined;
	var _actor = noone;
	switch (_case) {
		case 1:
			_actor = spawn_test_enemy(obj_mook, 5, 2, ["fire-warded"]);
			spawn_test_enemy(obj_brute, 7, 2, ["frost-warded"]);
			spawn_test_enemy(obj_carrion, 9, 2, ["lightning-warded"]);
			description = "Wards: narrow Mook/Brute, wide Carrion. T burns tracked Mook: its ward disappears, then returns.";
			break;
		case 2:
			_actor = spawn_test_enemy(obj_mook, 5, 2, ["banneret", "skeletal"]);
			spawn_test_enemy(obj_mook, 6, 2);
			description = "Banner + Skeletal: K kills tracked source. Pile has no banner/aura; revived body regains Banneret.";
			break;
		case 3:
			_actor = spawn_test_enemy(obj_swarmer, 5, 2);
			plan = test_plan("rune", [{effect: "harm", mods: []}]);
			spell_deliver(plan, _actor, 5, 2);
			description = "Swarmer: direct Rune delivery leaves HP unchanged. K still kills through the normal death lifecycle.";
			break;
		case 4:
			_actor = spawn_test_enemy(obj_siege_beast, 5, 2, [], true);
			description = "Siege: uninterrupted arrival deals one doubled hit. T stuns tracked beast and permanently interrupts charge.";
			break;
		case 5:
			_actor = spawn_test_enemy(obj_mole, 5, 2, ["banneret"], true);
			description = "Mole: destination marker while burrowing; banner hidden until emergence. Marker disappears on emergence.";
			break;
		case 6:
			spawn_test_enemy(obj_carrion, 5, 2);
			_actor = spawn_test_enemy(obj_mook, 6, 2, ["skeletal"]);
			description = "Carrion: K kills tracked skeletal neighbor. Body death grows Carrion once; pile destruction adds no growth.";
			break;
	}
	if (instance_exists(_actor)) watched_lineage = enemy_get_lineage(_actor);
};
