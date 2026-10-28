/// @description Debug level selector
if (!tune_flag("debug", "level_select_enabled")) {
	room_goto(rm_menu);
	exit;
}
window_set_cursor(cr_default);
global.menu_lock = false;
level_rooms = [rm_level_1, rm_level_2, rm_level_3, rm_level_4,
               rm_level_5, rm_level_6, rm_level_7, rm_level_8];
level_warnings = ["", "", "Combust missing", "Snap missing",
                  "Chain missing", "Force / Earth missing", "Discharge missing", ""];
