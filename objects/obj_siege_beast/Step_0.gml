// Inherit the parent event
if (stun_timer > 0) enemy_interrupt_charge(id, "stun");
event_inherited();

// handle speed based on interrupt vs non-interrupt
if (stun_timer > 0) enemy_interrupt_charge(id, "stun");
enemy_update_movement(id);

