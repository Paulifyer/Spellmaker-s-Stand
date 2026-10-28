// Developer-only room: inherit the manager's clock/flush events, not its campaign setup.
combat_execution = combat_execution_create();
paused = false; game_over = false; money = 0; village_hp = 30; active_enemy_count = 0;
level_paths = [Path1, Path2, Path3, Path4, Path5, Path6];
display_set_gui_size(1920, 1080);
test_col = 5; test_lane = 2; test_case = 0; next_beam_tick = -1;
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
