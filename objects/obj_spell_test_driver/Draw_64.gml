draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white);
draw_text(40, 25, "SPELL EXECUTION TEST ROOM");
draw_text(40, 60, "1 No Delay   2 Strike Delay   3 Rune policy   4 Projectile AoE   5 Beam ticks   6 Skeleton");
draw_text(40, 90, "R restart case   P pause   M move enemy into impact tile   Esc menu");
draw_text(40, 125, description);
draw_text(40, 160, "Clock: " + string(combat_execution.clock) + "  Queued: " + string(array_length(combat_execution.events)) + "  Paused: " + string(paused));
if (watched_lineage != undefined) {
	var _target = watched_lineage.target;
	var _state = watched_lineage.gap ? "skeleton gap" : "destroyed";
	if (instance_exists(_target)) _state = "HP " + string(_target.hp) + "  x " + string(round(_target.x));
	draw_text(40, 195, "Tracked enemy: " + _state);
}
draw_text(40, 235, "Tests native execution/timers/Pull movement. Campaign checks are still needed for projectile collisions and Rune arming.");
draw_text(40, 270, "F1 Wards   F2 Banner/Skeleton   F3 Swarmer   F4 Siege   F5 Mole   F6 Carrion   T status   K kill tracked");
draw_text(40, 305, "7 Snap/Frost Ward   8 Harm before Combust   9 Discharge chain");
var _x = GRID_X0 + test_col * TILE_W;
var _y = global.lane_top[test_lane];
draw_set_color(c_aqua); draw_rectangle(_x, _y, _x + TILE_W, _y + LANE_H, true);
if (plan.area) draw_rectangle(_x - TILE_W, _y - LANE_H, _x + 2 * TILE_W, _y + 2 * LANE_H, true);
draw_set_color(c_white);
