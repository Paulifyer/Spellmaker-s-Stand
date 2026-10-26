if (!instance_exists(target)) {
	instance_destroy();
	exit;
}

var _tx = target.x;
var _ty = target.y - 30;
var _dist = point_distance(x, y, _tx, _ty);

if (_dist <= move_speed) {
	instance_destroy();
	exit;
}

var _dir = point_direction(x, y, _tx, _ty);
x += lengthdir_x(move_speed, _dir);
y += lengthdir_y(move_speed, _dir);

move_speed += 0.2;
depth = -y - 1;