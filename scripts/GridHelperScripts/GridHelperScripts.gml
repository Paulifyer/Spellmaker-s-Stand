#macro TILE_W 128
#macro TILE_H 72
#macro GRID_COLS 13
#macro LANE_COUNT 6
#macro ROWS_PER_LANE 2
#macro LANE_H 144
#macro GRID_X0 128 // x of the lanes' left edge

global.lane_top = [144, 288, 432, 576, 720, 864];

function grid_to_world_center(_col, _row) {
	var _lane = _row div ROWS_PER_LANE;
	return {
		x : GRID_X0 + _col * TILE_W + TILE_W / 2,
		y : global.lane_top[_lane] + LANE_H / 2,
	};
}

function world_to_grid(_x, _y) {
	var _col = (_x - GRID_X0) div TILE_W;
	if (_col < 0 || _col >= GRID_COLS) return undefined;
	
	for (var i = 0; i < LANE_COUNT; i++) {
		var _top = global.lane_top[i];
		if (_y >= _top && _y < _top + LANE_H) {
			var _row = i * ROWS_PER_LANE + ((_y - _top) div TILE_H);
			return { col : _col, row : _row, lane: i};
		}
	}
	return undefined
}

function enemy_lane(_e) {
	if (variable_instance_exists(_e, "lane")) return _e.lane;
	var _t = world_to_grid(_e.x, _e.y);
	return (_t != undefined) ? _t.lane : -1;
}

function enemy_col_range(_e) {
	var _half = _e.hit_w / 2;
	var _cx = _e.x + _e.hit_x - GRID_X0;
	// Point-sized targets occupy their own column, including at the tower edge.
	if (_half == 0) {
		var _col = floor(_cx / TILE_W);
		return {c1: _col, c2: _col};
	}
	return {
		c1: floor((_cx - _half) / TILE_W),
		c2: floor((_cx + _half - 0.01) / TILE_W)
	};
}

function enemy_overlaps_region(_e, _c1, _c2, _l1, _l2) {
	var _l = enemy_lane(_e);
	if (_l < _l1 || _l > _l2) return false;
	var _r = enemy_col_range(_e);
	return _r.c1 <= _c2 && _r.c2 >= _c1;
}

function enemies_in_region_list(c1, c2, l1, l2) {
	c1 = max(c1, 0); c2 = min(c2, GRID_COLS - 1);
	l1 = max(l1, 0); l2 = min(l2, LANE_COUNT - 1);
	var out = []
	with (obj_enemy_parent) {
		if (enemy_overlaps_region(id, c1, c2, l1, l2)) array_push(out, id);
	}
	return out;
}
