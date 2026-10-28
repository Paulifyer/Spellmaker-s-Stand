for (var i = 1; i <= 9; i++) if (keyboard_check_pressed(ord("0") + i)) start_case(i);
for (var i = 0; i < 6; i++) if (keyboard_check_pressed(vk_f1 + i)) start_enemy_case(i + 1);
if (!paused && watched_lineage != undefined && instance_exists(watched_lineage.target)) {
	var _tracked = watched_lineage.target;
	if (keyboard_check_pressed(ord("K"))) _tracked.hp = 0;
	if (keyboard_check_pressed(ord("T"))) combat_status_apply(_tracked,
		(_tracked.object_index == obj_siege_beast) ? "lightning" : "burn", 3 * TARGET_ROOM_SPEED, 1);
}
if (keyboard_check_pressed(ord("R"))) {
	if (enemy_case > 0) start_enemy_case(enemy_case); else start_case(test_case);
}
if (keyboard_check_pressed(ord("P"))) {
	paused = !paused;
	if (paused) { instance_deactivate_object(obj_enemy_parent); instance_deactivate_object(obj_revive_manager); }
	else { instance_activate_object(obj_enemy_parent); instance_activate_object(obj_revive_manager); }
}
if (keyboard_check_pressed(vk_escape)) {
	instance_activate_object(obj_enemy_parent); instance_activate_object(obj_revive_manager);
	room_goto(rm_menu);
}
if (!paused && keyboard_check_pressed(ord("M")) && watched_lineage != undefined && instance_exists(watched_lineage.target)) {
	var _actor = watched_lineage.target;
	_actor.x = GRID_X0 + (test_col + 0.5) * TILE_W;
	_actor.y = global.lane_top[test_lane] + LANE_H / 2;
}
if (!paused && next_beam_tick >= 0 && combat_execution.clock >= next_beam_tick) {
	plan.hit_state.contacts = []; plan.hit_state.epoch += 1;
	spell_deliver(plan, watched_lineage.target, test_col, test_lane);
	next_beam_tick = -1;
}
