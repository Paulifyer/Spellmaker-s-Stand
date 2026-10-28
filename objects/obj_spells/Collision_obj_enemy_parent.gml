// Collision with obj_enemy (FOR PROJECTILE && RUNE ONLY)
if (!other.is_targetable) exit;

// Keep concrete instance handles across the form/effect method scopes.
var _spell_id = id;
var _target_id = other.id;
form.on_hit(_spell_id, _target_id);

