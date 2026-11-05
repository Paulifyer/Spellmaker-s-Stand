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
assert.match(ctx.spell_add_glyph(s, 'modifier', 'area', 0), /combine/);
// General groups cover Form and Effect attachments together.
s.effects[0].mods=['area'];
assert.match(ctx.spell_validation_message(s), /combine/);

for(const first of ['fire','ice','lightning']){
 for(const second of ['fire','ice','lightning']){
  if(first===second)continue;
  const elemental={form:'projectile',form_mods:[],effects:[{effect:first,mods:['delay']}]};
  assert.match(ctx.spell_add_glyph(elemental,'effect',second,-1),/combine/);
  elemental.effects.push({effect:second,mods:[]});
  assert.match(ctx.spell_validation_message(elemental),/combine/);
  assert.equal(ctx.is_spell_usable(elemental),false);
  ctx.global.spellbook=[elemental];
  assert.match(ctx.spellbook_start_message(100),/combine/);
 }
 const repeated={form:'projectile',form_mods:[],effects:[{effect:first,mods:['delay']},{effect:first,mods:[]}]};
 assert.equal(ctx.spell_validation_message(repeated),'');
}
// Groups may mix categories, and replacing a Form ignores the old Form.
ctx.global.tuning.compatibility.exclusive_glyph_groups.push(['beam','fire'],['projectile','rune']);
s={form:'projectile',form_mods:[],effects:[{effect:'fire',mods:[]}]};
assert.match(ctx.spell_add_glyph(s,'form','beam',-1),/combine/);
assert.equal(s.form,'projectile');
assert.equal(ctx.spell_add_glyph(s,'form','rune',-1),'');
assert.equal(ctx.spell_validation_message(s),'');

// Removing the override restores combinations, but cannot enable unsupported ones.
ctx.global.tuning.compatibility = {form_modifier_exclusions:{}, exclusive_form_modifier_groups:[]};
assert.equal(ctx.mod_valid_for_form('area', 'beam'), true);
assert.equal(ctx.spell_add_glyph(spell(['pierce']), 'modifier', 'chain', -1), '');
assert.equal(ctx.mod_valid_for_form('pierce', 'strike'), false);
// Legacy groups retain their original Form-only scope.
ctx.global.tuning.compatibility.exclusive_form_modifier_groups=[['area','pierce']];
assert.match(ctx.spell_add_glyph(spell(['area']),'modifier','pierce',-1),/combine/);
s=spell(['pierce']);s.effects=[{effect:'combust',mods:[]}];
assert.equal(ctx.spell_add_glyph(s,'modifier','area',0),'');
ctx.global.tuning = {};
assert.equal(ctx.mod_valid_for_form('area', 'beam'), true);
assert.equal(ctx.spell_validation_message(spell(['area','chain'])), '');
console.log('Tunable compatibility checks passed: editor, validation, Start, stacking, Form changes, Effect AoE and defaults.');
