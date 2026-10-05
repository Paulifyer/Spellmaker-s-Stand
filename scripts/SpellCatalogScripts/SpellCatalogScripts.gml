global.spell_glyphs = {
	form : {
		projectile : new Form_Projectile(),
		beam : new Form_Beam(),
		strike: new Form_Strike() 
	},
	element : {
		fire : new Elem_Fire(),
		ice : new Elem_Ice(),
		lightning : new Elem_Ice() 
	},
	modifier : {
		area : new Mod_Area(),
		amplify : new Mod_Amplify(),
		pierce : new Mod_Pierce()
	}
};