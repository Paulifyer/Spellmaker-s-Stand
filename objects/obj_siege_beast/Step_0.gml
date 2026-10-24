// Inherit the parent event
event_inherited();

// handle speed based on interrupt vs non-interrupt
if (stun_timer > 0) {
	base_speed = normal_speed;
}

