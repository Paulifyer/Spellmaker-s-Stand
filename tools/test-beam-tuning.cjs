const assert = require('node:assert/strict');
const {makeExecutionContext} = require('./execution-test-context.cjs');

const h = makeExecutionContext();
const originalTune = h.ctx.tune_params;
h.ctx.tune_params = (group, id, key, fallback) => {
    if (group === 'forms' && id === 'beam' && key === 'ticks_per_second') return 3;
    if (group === 'forms' && id === 'beam' && key === 'damage_multiplier_per_tick') return 0.4;
    return originalTune(group, id, key, fallback);
};
const enemy = h.enemy(2);
const spell = h.spell('beam', [{effect: 'harm', mods: []}]);
Object.assign(spell, {tick: 0, lane: 0, beam_lanes: []});
assert.equal(spell.compiled.beam_ticks_per_second, 3);
assert.equal(spell.compiled.beam_damage_multiplier_per_tick, 0.4);

// Compiled tuning remains fixed for this cast even if the global values change.
h.ctx.tune_params = originalTune;
h.ctx.forms.beam.on_step(spell);
assert.equal(enemy.hp, 99960);
for (let i = 0; i < 18; i++) h.ctx.forms.beam.on_step(spell);
assert.equal(enemy.hp, 99960);
h.ctx.forms.beam.on_step(spell);
assert.equal(enemy.hp, 99920);

const defaultPlan = h.ctx.compile_spell({form: 'beam', form_mods: [], effects: [{effect: 'harm', mods: []}]});
assert.equal(defaultPlan.beam_ticks_per_second, 4);
assert.equal(defaultPlan.beam_damage_multiplier_per_tick, 0.25);
h.ctx.tune_params = (group, id, key, fallback) => key === 'ticks_per_second' ? 0 : originalTune(group, id, key, fallback);
assert.throws(() => h.ctx.compile_spell({form: 'beam', form_mods: [], effects: [{effect: 'harm', mods: []}]}), /ticks_per_second/);
console.log('Beam tuning checks passed: custom timing/damage, captured values, defaults and invalid rate.');
