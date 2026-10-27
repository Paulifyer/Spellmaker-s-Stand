// Inherit the parent event
event_inherited();

var _enraged = hp < max_hp / 2;
if (_enraged) { // Enrage Handle
	attack_delay = max_attack_delay / enrage_mult;
} else {
	attack_delay = max_attack_delay;
}
enemy_update_movement(self, _enraged ? enrage_mult : 1);

