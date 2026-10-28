// F9 records five seconds of frame intervals, including stalls between frames.
if (room == rm_menu && variable_global_exists("debug_level_select_active")
&& global.debug_level_select_active) {
	global.current_level = 0;
	global.debug_level_select_active = false;
}

if (room == rm_menu && keyboard_check_pressed(vk_f8)) {
	room_goto(rm_debug_level_select);
	exit;
}

if (keyboard_check_pressed(vk_f9)) {
	perf_capture = true;
	perf_elapsed_us = 0;
	perf_frames = 0;
	perf_worst_us = 0;
	perf_stalls = 0;
	show_debug_message("PERF: recording five seconds...");
} else if (perf_capture) {
	perf_elapsed_us += delta_time;
	perf_frames++;
	perf_worst_us = max(perf_worst_us, delta_time);
	if (delta_time > 33333) perf_stalls++;
	if (perf_elapsed_us >= 5000000) {
		perf_capture = false;
		show_debug_message("PERF: room=" + room_get_name(room)
			+ " avg_ms=" + string(perf_elapsed_us / perf_frames / 1000)
			+ " worst_ms=" + string(perf_worst_us / 1000)
			+ " frames_over_33ms=" + string(perf_stalls)
			+ " instances=" + string(instance_count)
			+ " layers=" + string(array_length(layer_get_all())));
	}
}
