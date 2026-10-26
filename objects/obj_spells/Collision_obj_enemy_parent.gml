// Collision with obj_enemy (FOR PROJECTILE && RUNE ONLY)
if (!other.is_targetable) exit;

form.on_hit(self, other);

