/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Set the sprite's direction 
image_xscale = -1;
	
// Set path speed to normal speed
path_speed = my_speed;

if (burn_timer > 0) { //burn_handler
	if (burn_timer mod 5 == 0) {
		deal_damage(self, burn_dmg / (TARGET_ROOM_SPEED / 5))
	}
	burn_timer--;
}

if (slow_timer > 0) {
	my_speed = (1 - slow_amt) * ENEMY_SPEED
	slow_timer--;
}
if (slow_timer == 0) my_speed = ENEMY_SPEED;

if (stun_timer > 0) {
	my_speed = 0;
	stun_timer--;
}
if (stun_timer == 0) {
	my_speed = ENEMY_SPEED;
	stun_timer = -1;
	stun_immune_timer = TARGET_ROOM_SPEED;
}
if (stun_immune_timer > TARGET_ROOM_SPEED) {
	stun_timer = -1;
}






// Save it's current x and y
x_previous = x;
y_previous = y;
