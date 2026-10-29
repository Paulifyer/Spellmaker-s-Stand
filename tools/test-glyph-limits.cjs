const assert = require('node:assert/strict');
const {makeContext} = require('./construction-test-context.cjs');
const {read, load} = require('./gml-test-utils.cjs');
const ctx = makeContext(30);
ctx.global.tuning = JSON.parse(read('datafiles/tune.json'));
load(ctx, 'scripts/TuneScript/TuneScript.gml', ['tune_setting']);
const fresh = () => ({form:'projectile',form_mods:[],effects:[{effect:'harm',mods:[]}]});
for (const [id,active] of [['chain',-1],['amplify',0]]) {
    const s = fresh();
    assert.equal(ctx.spell_add_glyph(s,'modifier',id,active),'');
    assert.equal(ctx.spell_add_glyph(s,'modifier',id,active),'');
    assert.equal(ctx.is_spell_usable(s),true);
    assert.match(ctx.spell_add_glyph(s,'modifier',id,active),/Max 2/);
    const list = active < 0 ? s.form_mods : s.effects[0].mods;
    assert.equal(list.length,2); // rejected addition preserves the spell
    list.push(id); // saved spell from before a balance change
    assert.match(ctx.spell_validation_message(s),/Max 2/);
    assert.equal(ctx.is_spell_usable(s),false);
    ctx.global.spellbook = [s];
    assert.match(ctx.spellbook_start_message(10000),/Max 2/);
    list.pop();
    assert.equal(ctx.is_spell_usable(s),true);
}
const repeated = fresh();
repeated.effects = [
    {effect:'harm',mods:['amplify','amplify','delay']},
    {effect:'harm',mods:['amplify','amplify']},
    {effect:'fire',mods:['amplify','amplify']}
];
assert.equal(ctx.is_spell_usable(repeated),true);
assert.match(ctx.spell_add_glyph(repeated,'modifier','amplify',1),/Max 2/);
ctx.global.tuning.modifiers.amplify.max_per_effect = 3;
assert.equal(ctx.spell_add_glyph(repeated,'modifier','amplify',1),'');
assert.equal(repeated.effects[0].mods.length,3);
assert.equal(repeated.effects[1].mods.length,3);
assert.equal(repeated.effects[2].mods.length,2);
ctx.global.tuning.modifiers.chain.max_per_form = 0;
assert.match(ctx.spell_add_glyph(fresh(),'modifier','chain',-1),/Max 0/);
delete ctx.global.tuning.modifiers.chain.max_per_form;
delete ctx.global.tuning.modifiers.amplify.max_per_effect;
const uncapped = fresh();
uncapped.form_mods = ['chain','chain','chain'];
uncapped.effects[0].mods = ['amplify','amplify','amplify'];
assert.equal(ctx.is_spell_usable(uncapped),true);

// A modifier that attaches to both scopes gets independent limits.
ctx.global.tuning.modifiers.area.max_per_form = 0;
ctx.global.tuning.modifiers.area.max_per_effect = 1;
const area = fresh();
area.effects = [{effect:'combust',mods:[]}];
assert.match(ctx.spell_add_glyph(area,'modifier','area',-1),/Max 0/);
assert.equal(ctx.spell_add_glyph(area,'modifier','area',0),'');
assert.match(ctx.spell_add_glyph(area,'modifier','area',0),/Already/);
assert.equal(ctx.is_spell_usable(area),true);
assert.equal(ctx.mod_valid_for_form('pierce','strike'),false);
ctx.global.level_config.rm_test.max_glyphs = 2;
assert.match(ctx.spell_add_glyph(fresh(),'modifier','chain',-1),/limit/);
ctx.global.level_config.rm_test.max_glyphs = 30;
for (const invalid of [-1,1.5,'2']) {
    ctx.global.tuning.modifiers.chain.max_per_form = invalid;
    assert.throws(() => ctx.spell_add_glyph(fresh(),'modifier','chain',-1),/non-negative integer/);
}
ctx.global.tuning = {};
assert.equal(ctx.is_spell_usable(uncapped),true);
console.log('Glyph limits passed: boundaries, saved spells, Start, independent attachments, overrides, defaults and existing rules.');
