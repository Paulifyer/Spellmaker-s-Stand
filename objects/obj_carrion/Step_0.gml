/// @description Enemy Carrion

for (var i = 0; i < array_length(nearby_list); i++) {
	if (!instance_exists(nearby_list[i])) { // checks if any enemies nearby have died
		var _add_hp = base_hp * enrage_hp_mult;
		var _add_spd = base_speed_original * enrage_spd_mult;
		hp += _add_hp;
		base_speed += _add_spd;
	}
}
var _tile = world_to_grid(x, y);
if (_tile != undefined)
	nearby_list = enemies_in_region_list(_tile.col - 1, _tile.col + 1, _tile.row - 1, _tile.row + 1);

// Inherit the parent event
event_inherited();
