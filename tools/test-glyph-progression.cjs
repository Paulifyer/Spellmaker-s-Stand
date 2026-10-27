const assert = require('node:assert/strict');
const vm = require('node:vm');
const {read, load} = require('./gml-test-utils.cjs');
const config = JSON.parse(read('datafiles/level.json'));
for (const [key, level] of Object.entries(config)) {
    if (key === '_readme') continue;
    assert.ok(Number.isInteger(level.max_glyphs) && level.max_glyphs >= 2);
}
assert.deepEqual([1,2,3].map(n => config[`rm_level_${n}`].max_glyphs), [2,3,5]);
const ctx = vm.createContext({
    room: 'rm_level_1', room_get_name: x => x,
    global: {level_config: config, spell_glyphs: {form: {}, effect: {}, modifier: {}}},
    array_length: a => a.length, array_contains: (a,v) => a.includes(v), array_push: (a,v) => a.push(v),
    real: Number, string: String, string_delete: (s,start,len) => s.slice(0,start-1)+s.slice(start-1+len),
    is_struct: x => !!x && typeof x === 'object', variable_struct_exists: (s,k) => Object.hasOwn(s,k),
});
for (const level of Object.values(config).filter(x => typeof x === 'object'))
    for (const glyph of level.unlocked_glyphs) ctx.global.spell_glyphs[glyph.type][glyph.id] = {};
load(ctx, 'scripts/GlyphAccessScripts/GlyphAccessScripts.gml', ['unlock_glyph','unlock_glyphs_through_level']);
load(ctx, 'scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml', ['spell_max_glyphs','spell_glyph_count']);
ctx.unlock_glyphs_through_level('rm_level_3');
assert.ok(ctx.global.owned.modifier.includes('delay'));
assert.ok(ctx.global.owned.effect.includes('fire'));
assert.ok(ctx.global.owned.form.includes('projectile'));
ctx.unlock_glyphs_through_level('rm_level_1');
assert.equal(ctx.global.owned.modifier.length, 0);
assert.equal(ctx.global.owned.effect.includes('fire'), false);
assert.equal(ctx.spell_glyph_count(undefined), 0);
assert.equal(ctx.spell_glyph_count({form:'projectile',form_mods:['pierce'],effects:[{effect:'harm',mods:['amplify','amplify']}]}), 5);
config.rm_level_1.max_glyphs = 4;
assert.equal(ctx.spell_max_glyphs(), 4); // no hardcoded per-level limit
config.rm_level_1.unlocked_glyphs.push({type:'effect',id:'not_implemented'});
assert.throws(() => ctx.unlock_glyphs_through_level('rm_level_1'), /Unknown unlocked glyph/);
console.log('Glyph progression checks passed: JSON limits, counting, cumulative/direct entry, reset and unknown glyph rejection.');
