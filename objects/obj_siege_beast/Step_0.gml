// Inherit the parent event
var _was_stunned = stun_timer > 0;
event_inherited();

// handle speed based on interrupt vs non-interrupt
if (_was_stunned || stun_timer > 0) {
	base_speed = normal_speed;
}
enemy_update_movement(self);

