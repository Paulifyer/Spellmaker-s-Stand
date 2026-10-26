/// @description Enemy Carrion

for (var i = 0; i < array_length(nearby_list); i++) {
	if (!instance_exists(nearby_list[i])) { // checks if any enemies nearby have died
		var _enemy = nearby_enemy_xys[i];
		var _add_hp = base_hp * enrage_hp_mult;
		var _add_spd = base_speed_original * enrage_spd_mult;
		max_hp += _add_hp;
		hp += _add_hp;
		base_speed += _add_spd;
		image_xscale += 0.1;
		image_yscale += 0.1;
		hit_w += 12;
		show_debug_message($"{_enemy.x}, {_enemy.y}")
		instance_create_depth(
			_enemy.x, _enemy.y - 30,
			_enemy.y - 1, obj_siphon,
			{ target: id }
		)
	}
}
var _tile = world_to_grid(x, y);
if (_tile != undefined)
	nearby_list = enemies_in_region_list(_tile.col - 1, _tile.col + 1, _tile.lane - 1, _tile.lane + 1);

nearby_enemy_xys = [];
for (var e = 0; e < array_length(nearby_list); e++) {
	var _enemy = nearby_list[e];
	array_push(nearby_enemy_xys, { x: _enemy.x, y: _enemy.y });
}

// Inherit the parent event
event_inherited();
