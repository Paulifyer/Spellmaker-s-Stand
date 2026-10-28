if (hp > 0 && is_struct(emergence_marker) && emergence_marker.active) {
	draw_set_color(c_orange); draw_set_alpha(0.75);
	var _mx = emergence_marker.x, _my = emergence_marker.y;
	draw_ellipse(_mx - TILE_W * 0.3, _my - LANE_H * 0.12, _mx + TILE_W * 0.3, _my + LANE_H * 0.12, true);
	draw_line(_mx - 10, _my, _mx + 10, _my);
	draw_line(_mx, _my - 6, _mx, _my + 6);
	draw_set_alpha(1); draw_set_color(c_white);
}

// trail_points: newest position first
for (var i = array_length(trail_points) - 1; i >= 0; i--) {
    var _p = trail_points[i];
    var _phase = current_time * 0.012 - i * 0.8;
    var _size = image_xscale * power(0.8, i + 1);
    var _pulse = sin(_phase);

    draw_sprite_ext(
        burrow_sprite, 0,
        _p.x, _p.y + _pulse * 2,
        _size * (1 + _pulse * 0.08),
        _size * (1 - _pulse * 0.12),
        0, image_blend, image_alpha
    );
}

event_inherited();
