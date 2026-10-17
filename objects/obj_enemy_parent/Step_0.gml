/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Set path speed to normal speed
path_speed = my_speed

if (burn_timer > 0) { //burn_handler
	if (burn_timer mod TARGET_ROOM_SPEED == 0) {
		deal_damage(self, burn_dmg)
	}
	burn_timer--;
}

if (slow_timer > 0) {
	my_speed = (1 - slow_amt) * base_speed
	slow_timer--;
}
if (slow_timer == 0) {
	my_speed = base_speed;
	slow_amt = 0;
}

if (stun_timer > 0) {
	my_speed = 0;
	stun_timer--;
}
if (stun_timer == 0) {
	my_speed = base_speed;
	stun_timer = -1;
	stun_immune_timer = TARGET_ROOM_SPEED;
}
if (stun_immune_timer > TARGET_ROOM_SPEED) {
	stun_timer = -1;
}

if (stun_immune_timer > 0) stun_immune_timer--;


// Save it's current x and y
x_previous = x;
y_previous = y;
