event_inherited();

max_hp = get_village_hp();
hp = max_hp;
flash_alpha = 0;

sprite_index = spr_ui_barrier_fullhealth;
// Keep the stopping line stable as the barrier changes damage sprites.
front_x = bbox_right;
