// Inherit the parent event
if (charge_active) walk_side_sprite = spr_enemy_siegebeast_charge;
else walk_side_sprite = spr_enemy_siegebeast_walk;

if (stun_timer > 0) enemy_interrupt_charge(id, "stun");
if (is_blocked) enemy_interrupt_charge(id, "blocked")
event_inherited();

// handle speed based on interrupt vs non-interrupt
if (stun_timer > 0) enemy_interrupt_charge(id, "stun");
if (is_blocked) enemy_interrupt_charge(id, "blocked")
enemy_update_movement(id);

