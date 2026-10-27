// Runs the project's GML builder and scheduling logic with mocked engine calls.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const read = p => fs.readFileSync(path.join(__dirname, '..', p), 'utf8');
const helpers = read('scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml');
const catalog = read('scripts/SpellCatalogScripts/SpellCatalogScripts.gml');
function extract(source, name) {
    const start = source.indexOf(`function ${name}(`);
    assert.ok(start >= 0, name);
    const open = source.indexOf('{', start);
    let depth = 1, end = open + 1;
    while (depth) { if (source[end] === '{') depth++; if (source[end] === '}') depth--; end++; }
    return source.slice(start, end);
}
// Translate only the GML dynamic-struct accessor and one integer division.
const translate = s => s.replace(/\[\$\s*([^\]]+)\]/g, '[$1]')
    .replace('_row div ROWS_PER_LANE', 'Math.floor(_row / ROWS_PER_LANE)')
    .replace('_existing.lane = _lane', '_existing.lane == _lane');
const log = [];
const manager = {pending_spell_impacts: []};
const ctx = {
    MAX_EFFECTS: 5, MAX_MODS: 5, TARGET_ROOM_SPEED: 60, ROWS_PER_LANE: 1,
    DELAY_COST: 5, DELAY_AMT: 1, noone: null, obj_gameplay_manager: 1, obj_spells: 2,
    array_length: a => a.length, array_contains: (a, x) => a.includes(x),
    array_push: (a, x) => a.push(x), array_delete: (a, i, n) => a.splice(i, n),
    is_struct: x => !!x && typeof x === 'object',
    min: Math.min, max: Math.max, round: Math.round,
    is_glyph_available: () => true, mod_valid_for_form: () => true,
    is_instanceof: () => false, Mod_Amplify: function(){}, Form_Beam: function(){},
    instance_exists: x => !!x && !x.destroyed,
    instance_find: () => manager, instance_number: () => 0,
    json_stringify: JSON.stringify, tune_params: (_, __, ___, value) => value,
    global: {spell_glyphs: {form: {}, modifier: {}, effect: {}}},
};
vm.createContext(ctx);
for (const name of ['spell_sequence_valid', 'spell_can_append_effect', 'spell_add_glyph', 'spell_cost'])
    vm.runInContext(translate(extract(helpers, name)), ctx);
vm.runInContext(translate(extract(read('scripts/GlyphAccessScripts/GlyphAccessScripts.gml'), 'is_spell_usable')), ctx);
for (const name of ['apply_effect_group', 'schedule_effect', 'spell_snapshot', 'spell_hit', 'spell_impact', 'cast_spell'])
    vm.runInContext(translate(extract(catalog, name)), ctx);
const modifierSource = read('scripts/ModifierGlyphs/ModifierGlyphs.gml');
const delayBody = extract(modifierSource, 'Mod_Delay');
const delayCallback = delayBody.slice(delayBody.indexOf('function(spell, fx)'), delayBody.lastIndexOf('}') - 1).trim().replace(/;$/, '');
const delay = {cost: 5, scope: 'effect', is_stacks: true, on_cast: vm.runInContext(`(${delayCallback})`, ctx)};
ctx.global.spell_glyphs.modifier.delay = delay;
ctx.global.spell_glyphs.form.projectile = {cost: 5, name: 'Projectile', on_cast: () => {}};
for (const name of ['harm', 'fire', 'ice', 'pull']) ctx.global.spell_glyphs.effect[name] = {
    cost: 10, on_cast: () => {},
    on_hit: () => log.push(name), on_impact: () => log.push(`impact:${name}`),
};
const creation = read('objects/obj_spells/Create_0.gml');
const init = creation.slice(creation.indexOf('form.on_cast(self);'), creation.indexOf('col = c_white;', creation.indexOf('form.on_cast(self);')));
ctx.instance_create_layer = (_, __, ___, ____, data) => {
    Object.assign(ctx, {self: data, form: data.form, form_mods: data.form_mods, effects: data.effects});
    vm.runInContext(init, ctx);
    return data;
};
const fresh = () => ({name: '', form: 'projectile', form_mods: [], effects: []});
const add = (s, type, id, active = -1) => ctx.spell_add_glyph(s, type, id, active);
let s = fresh();
assert.equal(add(s, 'effect', 'harm'), '');
assert.notEqual(add(s, 'effect', 'harm'), '');
assert.equal(add(s, 'effect', 'fire'), '');
assert.notEqual(add(s, 'effect', 'harm'), '');
assert.equal(add(s, 'modifier', 'delay', 0), '');
assert.equal(add(s, 'effect', 'harm'), '');
assert.equal(ctx.spell_sequence_valid(s), true);
assert.equal(ctx.spell_sequence_valid(s, -1, 0, 0), false);
assert.equal(ctx.spell_sequence_valid(s, 1), true);
assert.equal(ctx.spell_sequence_valid(s, 2), true);
assert.equal(add(s, 'modifier', 'delay', 1), '');
assert.equal(ctx.spell_sequence_valid(s, 1), true); // the earlier boundary still separates Harm
const removal = fresh();
removal.effects = [{effect: 'harm', mods: []}, {effect: 'fire', mods: ['delay']}, {effect: 'harm', mods: []}];
assert.equal(ctx.spell_sequence_valid(removal, 1), false);
assert.equal(add(s, 'modifier', 'delay', 0), ''); // stacked boundary: 2 seconds
assert.equal(ctx.spell_cost(s), 50);
const caster = {mana: 100, mana_exhausted: false, x: 0, y: 0};
const result = ctx.cast_spell(caster, s, 2, 0);
assert.equal(result.cost, ctx.spell_cost(s));
assert.equal(caster.mana, 50);
assert.deepEqual(Array.from(result.spell.effects, fx => fx.delay), [0, 2, 3]);
const target = {is_targetable: true, pending_effects: []};
Object.assign(result.spell, {hit_list: [], x: 0, y: 0});
ctx.spell_hit(result.spell, target);
assert.deepEqual(log, ['harm']);
assert.deepEqual(Array.from(target.pending_effects, p => p.timer), [120, 180]);
ctx.pending_effects = target.pending_effects; ctx.id = target;
const step = read('objects/obj_enemy_parent/Step_0.gml');
const handler = step.slice(step.indexOf('// Delay Handler'), step.indexOf('// Save'));
for (let i = 0; i < 119; i++) vm.runInContext(handler, ctx);
assert.deepEqual(log, ['harm']);
vm.runInContext(handler, ctx); assert.deepEqual(log, ['harm', 'fire']);
for (let i = 0; i < 60; i++) vm.runInContext(handler, ctx);
assert.deepEqual(log, ['harm', 'fire', 'harm']);
// Same-time delayed effects keep their authored order.
s = fresh(); add(s, 'effect', 'harm'); add(s, 'modifier', 'delay');
add(s, 'effect', 'fire'); add(s, 'effect', 'ice');
const second = ctx.cast_spell({...caster, mana: 100}, s, 2, 0).spell;
Object.assign(second, {hit_list: [], x: 0, y: 0});
log.length = 0; target.pending_effects = []; ctx.spell_hit(second, target);
ctx.pending_effects = target.pending_effects;
for (let i = 0; i < 60; i++) vm.runInContext(handler, ctx);
assert.deepEqual(log, ['harm', 'fire', 'ice']);
// Invalid manually edited sequences cannot cast or spend mana.
const bad = fresh(); bad.effects = [{effect: 'harm', mods: []}, {effect: 'harm', mods: []}];
const payer = {...caster, mana: 100};
assert.equal(ctx.cast_spell(payer, bad, 0, 0).spell, null); assert.equal(payer.mana, 100);
// Delayed impact effects survive the projectile and freeze while paused.
log.length = 0; ctx.spell_impact(second, 2, 0);
assert.deepEqual(log, ['impact:harm']);
second.destroyed = true;
ctx.pending_spell_impacts = manager.pending_spell_impacts; ctx.paused = true;
const managerStep = read('objects/obj_gameplay_manager/Step_0.gml');
const impactHandler = managerStep.slice(managerStep.indexOf('if (!paused)'), managerStep.indexOf("// Check if the village"));
vm.runInContext(impactHandler, ctx);
assert.equal(manager.pending_spell_impacts[0].timer, 60);
ctx.paused = false;
for (let i = 0; i < 60; i++) vm.runInContext(impactHandler, ctx);
assert.deepEqual(log, ['impact:harm', 'impact:fire', 'impact:ice']);
assert.equal(manager.pending_spell_impacts.length, 0);
console.log('Delay checks passed: builder rules, boundary removal, cumulative/stacked timing, stable order, mana, invalid casts and delayed impacts.');
