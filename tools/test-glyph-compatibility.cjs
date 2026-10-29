const assert = require('node:assert/strict');
const {makeContext} = require('./construction-test-context.cjs');
const {read, load} = require('./gml-test-utils.cjs');
const ctx = makeContext();
ctx.global.tuning = JSON.parse(read('datafiles/tune.json'));
load(ctx, 'scripts/TuneScript/TuneScript.gml', ['tune_setting']);
const spell = (mods = []) => ({form:'projectile', form_mods:mods, effects:[{effect:'harm', mods:[]}]});

assert.equal(ctx.mod_valid_for_form('area', 'beam'), false);
assert.equal(ctx.mod_valid_for_form('area', 'projectile'), true);
assert.equal(ctx.mod_valid_for_effect('area', 'combust'), true);
for (const [a,b] of [['area','pierce'],['area','chain'],['pierce','chain']]) {
    assert.match(ctx.spell_add_glyph(spell([a]), 'modifier', b, -1), /combine/);
    assert.match(ctx.spell_add_glyph(spell([b]), 'modifier', a, -1), /combine/);
    const s = spell([a,b]);
    assert.match(ctx.spell_validation_message(s), /combine/);
    assert.equal(ctx.is_spell_usable(s), false);
    ctx.global.spellbook = [s];
    assert.match(ctx.spellbook_start_message(100), /combine/);
}
for (const id of ['pierce','chain']) {
    const s = spell([id]);
    assert.equal(ctx.spell_add_glyph(s, 'modifier', id, -1), '');
    assert.equal(ctx.spell_validation_message(s), '');
}
assert.match(ctx.spell_add_glyph(spell(['area']), 'modifier', 'area', -1), /Already/);
let s = spell(['area']);
assert.equal(ctx.spell_add_glyph(s, 'form', 'beam', -1), '');
assert.equal(s.form_mods.length, 0);
assert.match(ctx.spell_add_glyph(s, 'modifier', 'area', -1), /attach/);
s.form_mods = ['area'];
assert.equal(ctx.is_spell_usable(s), false);
s = spell(['pierce']);
s.form = 'beam';
s.effects = [{effect:'combust', mods:[]}];
assert.equal(ctx.spell_add_glyph(s, 'modifier', 'area', 0), '');
assert.equal(ctx.spell_validation_message(s), '');

// Removing the override restores combinations, but cannot enable unsupported ones.
ctx.global.tuning.compatibility = {form_modifier_exclusions:{}, exclusive_form_modifier_groups:[]};
assert.equal(ctx.mod_valid_for_form('area', 'beam'), true);
assert.equal(ctx.spell_add_glyph(spell(['pierce']), 'modifier', 'chain', -1), '');
assert.equal(ctx.mod_valid_for_form('pierce', 'strike'), false);
ctx.global.tuning = {};
assert.equal(ctx.mod_valid_for_form('area', 'beam'), true);
assert.equal(ctx.spell_validation_message(spell(['area','chain'])), '');
console.log('Tunable compatibility checks passed: editor, validation, Start, stacking, Form changes, Effect AoE and defaults.');
