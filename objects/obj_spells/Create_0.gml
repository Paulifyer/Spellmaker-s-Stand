//obj_spell Create

//form = undefined; element = undefined; modifer = undefined;
spd = 4; dmg = 1; lifetime = 60; pierce = 0; dir = 0;
dmg_multiplier = 1; elem_multiplier = 1;
col = c_white
landed = false;
lane = 0;
target_x = 0; target_y = 0;
area = false; // If area glyph is used
hit_list = []; beam_lanes = [];

form.on_cast(self);
element.on_cast(self);
modifier.on_cast(self);
