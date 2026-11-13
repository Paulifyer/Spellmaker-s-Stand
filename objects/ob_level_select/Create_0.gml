/// @description Campaign level selector
window_set_cursor(cr_default);
global.menu_lock = false;
level_rooms = global.level_array;
level_progress = level_select_progress(level_rooms);
debug_unlock_all = false;
level_warnings = ["", "", "", "",
                  "", "", "", ""];

// Layout in sprite-local coordinates; Draw applies the animated instance transform.
display_set_gui_size(room_width, room_height);
var _left = 0;
var _top = 0;
var _width = sprite_get_width(sprite_index);
var _height = sprite_get_height(sprite_index);
level_buttons = [];
for (var i = 0; i < array_length(level_rooms); i++) {
	array_push(level_buttons, {
		x: _left + _width * (0.15 + (i mod 2) * 0.365),
		y: _top + _height * (0.25 + (i div 2) * 0.145),
		w: _width * 0.335,
		h: _height * 0.115
	});
}
back_button = {x: _left + _width * 0.36, y: _top + _height * 0.86,
	w: _width * 0.28, h: _height * 0.065};
heading_x = _left + _width * 0.5;
heading_y = _top + _height * 0.13;
instructions_y = _top + _height * 0.19;


// Convert the room pointer into the scroll's current animated coordinates.
level_select_mouse = function() {
    if (image_xscale == 0 || image_yscale == 0) return {x: -10000, y: -10000};
    var _dx = mouse_x - x;
    var _dy = mouse_y - y;
    return {
        x: (_dx * dcos(image_angle) - _dy * dsin(image_angle)) / image_xscale + sprite_get_xoffset(sprite_index),
        y: (_dx * dsin(image_angle) + _dy * dcos(image_angle)) / image_yscale + sprite_get_yoffset(sprite_index)
    };
};
