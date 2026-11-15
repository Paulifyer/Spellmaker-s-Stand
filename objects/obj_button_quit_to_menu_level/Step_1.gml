/// @description Level Select Back Button

event_inherited();

// on top of the game. So input for these buttons must also be taken on the GUI layer.
var _mouse_gui_x = device_mouse_x_to_gui(0);

// Get the Y position of the mouse on the GUI layer
var _mouse_gui_y = device_mouse_y_to_gui(0);

if (collision_point(_mouse_gui_x, _mouse_gui_y, object_index, false, false) == id) {
	sprite_index = spr_level_button_hover;
} else {
	sprite_index = spr_level_button;
}