hp = get_village_hp();
// Fade the hit overlay over roughly 0.2 seconds.
flash_alpha = max(0, flash_alpha - delta_time / 200000);

if (hp >= round(0.67 * max_hp)) sprite_index = spr_ui_barrier_fullhealth;
else if (hp >= round(0.34 * max_hp)) sprite_index = spr_ui_barrier_midhealth2;
else sprite_index = spr_ui_barrier_lowhealth;
