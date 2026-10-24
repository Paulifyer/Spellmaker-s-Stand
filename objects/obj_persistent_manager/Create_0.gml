/// @description Persistent Manager



// This variable tells you whether or not a popup menu currently exists
global.popup_menu_exists = false;

// This variable tells you whether or not the menu is locked.
// If this variable is true, it prevents you from interacting with instances
global.menu_lock = false;

// This variable stores the current screenshot id if one exists. Otherwise, it will store -1.
global.screen_shot_id = -1;

window_set_cursor(cr_none);
cursor_sprite = spr_cursor;

perf_capture = false;
perf_elapsed_us = 0;
perf_frames = 0;
perf_worst_us = 0;
perf_stalls = 0;



