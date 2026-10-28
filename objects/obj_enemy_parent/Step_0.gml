/// @description Enemy Parent

// Set the sprite to the sideways sprite
sprite_index = walk_side_sprite;
	
// Ensures pull is set correctly
if (pull != undefined) enemy_update_pull(id);

combat_status_advance(self, 1);

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
