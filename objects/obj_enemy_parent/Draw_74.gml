// Hide the health bar immediately on death and throughout the death fade.
if (hp <= 0 || is_dying) exit;

var _delay = combat_pending_delay(self);
if (_delay) {
	draw_sprite_ext(delay_spr, delay_frame, x + health_offset_x + 6, y + health_offset_y - 14, 0.25, 0.25, 0, c_white, 1);
}

// Draws health bar at set location
draw_healthbar(x + health_offset_x, y + health_offset_y, x + health_offset_x + 69, y + health_offset_y + 6, health_bar, c_red, c_lime, c_lime, 0, true, true);