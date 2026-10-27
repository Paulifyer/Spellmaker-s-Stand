/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Set path speed to normal speed
path_speed = (stun_timer > 0) ? 0 : my_speed;

// Ensures pull is set correctly
if (pull != undefined) enemy_update_pull(id);

// Burn Handler
if (--burn_timer > 0 && burn_timer mod TARGET_ROOM_SPEED == 0) { //burn_handler
		deal_damage(self, burn_dmg)
}

// Frost Handler
if (--slow_timer > 0) {
	my_speed = (1 - slow_amt) * base_speed
}

if (slow_timer == 0) {
	my_speed = base_speed;
	slow_amt = 0;
}

// Lightning Handler
if (stun_timer == 0) {
	my_speed = base_speed;
	stun_immune_timer = TARGET_ROOM_SPEED * 3;
}

if (stun_timer > 0) stun_timer--;

// Hex lasts for a fixed duration after it is applied.
if (hex_timer > 0) hex_timer--;

if (stun_immune_timer > 0) stun_immune_timer--;

// Delay Handler
// Process ties in insertion order so same-time effects keep their sequence order.
for (var i = 0; i < array_length(pending_effects);) {
	var _p = pending_effects[i];
	if (--_p.timer <= 0) {
		apply_effect_group(_p.spell, id, _p.fx);
		array_delete(pending_effects, i, 1);
	} else i++;
}


// Save it's current x and y
x_previous = x;
y_previous = y;
