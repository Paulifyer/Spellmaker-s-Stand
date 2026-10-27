/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Ensures pull is set correctly
if (pull != undefined) enemy_update_pull(id);

// Burn Handler
if (burn_timer > 0) {
	// Include the last tick at expiry without applying damage immediately on hit.
	if ((burn_timer - 1) mod TARGET_ROOM_SPEED == 0) deal_damage(self, burn_dmg);
	burn_timer = max(0, burn_timer - 1);
}

// Frost Handler
slow_timer = max(0, slow_timer - 1);
if (slow_timer == 0) slow_amt = 0;

// Lightning starts charged immunity once, when the stun expires.
enemy_advance_lightning(self, 1);

// Hex lasts for a fixed duration after it is applied.
if (hex_timer > 0) hex_timer--;

// Delay Handler
// Process ties in insertion order so same-time effects keep their sequence order.
for (var i = 0; i < array_length(pending_effects);) {
	var _p = pending_effects[i];
	if (--_p.timer <= 0) {
		apply_effect_group(_p.spell, id, _p.fx);
		array_delete(pending_effects, i, 1);
	} else i++;
}


enemy_update_movement(self);

// Save it's current x and y
x_previous = x;
y_previous = y;
