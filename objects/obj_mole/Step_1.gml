/// @description Enemy Mole

// Attacks begin only after the emerging animation has finished.
if (emerged) {
	if (!emerging) event_inherited();
	exit;
}

// This is to prevent the mole from emerging on a rock
if (pull == undefined && place_meeting(path_get_x(path_index, pos_to_stop), y, obj_rock)) {
	pos_to_stop -= 1/13;
} else {
	pos_to_stop = base_pos_to_stop;
}

// Check if the enemies position on the path is greater than or equal to 1
// which means that it is at the end of the path
if (path_position >= pos_to_stop || is_blocked)
{
	if (!emerged) {
		emerged = true;
		emerging = true;
		is_stop_reached = true;
		walk_side_sprite = emerge_sprite;
		sprite_index = emerge_sprite;
		image_index = 0;
		image_speed = 1;
		is_targetable = emerged;
		path_position = pos_to_stop;
		path_speed = 0;
		if (is_struct(emergence_marker)) {
			x = emergence_marker.x; y = emergence_marker.y;
			emergence_marker.active = false;
		}
	}
}
	
