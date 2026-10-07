// Collision with obj_enemy (FOR PROJECTILE ONLY)
if (!array_contains(hit_list, other)) {
	if (area) {
		var _col = (other.x - GRID_X0) div TILE_W;
		var _t = world_to_grid(other.x, other.y);
		var _lane = (_t != undefined) ? _t.lane : target_row div ROWS_PER_LANE;
		spell_hit_area(id, _col - 1, _col + 1, _lane - 1, _lane + 1);
	} else {
		form.on_hit(self, other);
		element.on_hit(self, other);
		if (modifier.on_hit != undefined) modifier.on_hit(self, other);
		array_push(hit_list, other);
	}
	if (pierce-- <= 0) {
		instance_destroy();	
	}
}
