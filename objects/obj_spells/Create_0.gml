//obj_spell Create

form = undefined; element = undefined; modifer = null;
spd = 4; dmg = 1; lifetime = 60; pierce = 0; dir = 0;

init = function(_p, _e, _m) {
	form = _p; element = _e; modifier = _m;
	form.on_cast(self);
	modifier.on_cast(self);
}
