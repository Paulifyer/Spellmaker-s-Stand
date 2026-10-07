#macro TILE_W 128
#macro TILE_H 72
#macro GRID_COLS 13
#macro LANE_COUNT 5
#macro ROWS_PER_LANE 2
#macro LANE_H 144
#macro GRID_X0 128 // x of the lanes' left edge

global.lane_top = [144, 288, 432, 576, 720];

function grid_to_world_center(_col, _row) {
	var _lane = _row div ROWS_PER_LANE;
	return {
		x : GRID_X0 + _col * TILE_W + TILE_W / 2,
		y : global.lane_top[_lane] + (_row mod ROWS_PER_LANE) * TILE_H + TILE_H / 2,
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