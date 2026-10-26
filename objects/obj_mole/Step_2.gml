/// @description Enemy Mole

if (path_position < pos_to_stop) {
    if (point_distance(x, y, trail_last_x, trail_last_y) >= trail_spacing) {
        array_insert(trail_points, 0, {
            x: trail_last_x,
            y: trail_last_y
        });

        trail_last_x = x;
        trail_last_y = y;

        if (array_length(trail_points) > trail_max) {
            array_pop(trail_points);
        }
    }
} else {
    trail_points = [];
}

event_inherited();