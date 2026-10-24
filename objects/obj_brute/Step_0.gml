// Inherit the parent event
event_inherited();

if (hp < max_hp / 2) { // Enrage Handle
	attack_delay = max_attack_delay / enrage_mult;
	my_speed = base_speed * enrage_mult * (1 - slow_amt);
}

