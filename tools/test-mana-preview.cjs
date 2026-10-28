const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const read = p => fs.readFileSync(path.join(__dirname, '..', p), 'utf8');
function extract(source, name) {
    const start = source.indexOf(`function ${name}(`);
    assert.ok(start >= 0);
    let end = source.indexOf('{', start) + 1, depth = 1;
    while (depth) { if (source[end] === '{') depth++; if (source[end] === '}') depth--; end++; }
    return source.slice(start, end).replace(/\[\$\s*([^\]]+)\]/g, '[$1]');
}
const amplify = {cost: 15, amplify: true};
const ctx = {
    global: {spellbook: [], spell_glyphs: {
        form: {projectile: {cost: 5}}, effect: {harm: {cost: 10}},
        modifier: {amplify, delay: {cost: 5}, pierce: {cost: 15}}
    }},
    array_length: a => a.length,
    array_push:(a,v)=>a.push(v),is_struct:x=>!!x&&typeof x==='object',
    clamp: (v, a, b) => Math.max(a, Math.min(b, v)),
    string: String, is_instanceof: m => !!m.amplify, Mod_Amplify: function(){},
    tune_params: (_, __, ___, fallback) => fallback,
};
vm.createContext(ctx);
const source = read('scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml');
vm.runInContext(extract(read('scripts/SpellCatalogScripts/SpellCatalogScripts.gml'),'compile_spell'),ctx);
for (const name of ['spell_cost', 'spell_mana_preview', 'spellbook_expensive_slots'])
    vm.runInContext(extract(source, name), ctx);
const spell = (mods = []) => ({form: 'projectile', form_mods: [], effects: [{effect: 'harm', mods}]});
assert.equal(ctx.spell_mana_preview(undefined, 100).fill, 0);
assert.equal(ctx.spell_mana_preview({name: 'empty'}, 100).cost, 0);
assert.equal(ctx.spell_mana_preview(spell(), 100).fill, 0.15);
assert.equal(ctx.spell_mana_preview(spell(), 125).fill, 0.12);
assert.equal(ctx.spell_mana_preview(spell(), 15).fill, 1);
assert.equal(ctx.spell_mana_preview(spell(), 15).too_expensive, false);
assert.equal(ctx.spell_mana_preview(spell(), 10).fill, 1);
assert.equal(ctx.spell_mana_preview(spell(), 10).too_expensive, true);
assert.equal(ctx.spell_mana_preview(undefined, 0).fill, 0);
assert.equal(ctx.spell_mana_preview(spell(), 0).too_expensive, true);
assert.equal(ctx.spell_cost(spell(['amplify', 'amplify', 'delay'])), 55);
ctx.global.spellbook = [undefined, spell(), spell(['pierce'])];
assert.equal(ctx.spellbook_expensive_slots(20), '3');
assert.equal(ctx.spellbook_expensive_slots(10), '2, 3');
assert.equal(ctx.spellbook_expensive_slots(30), '');

// Run the real Start handling block and verify that blocked clicks have no side effects.
const draw = read('objects/obj_spellbook/Draw_64.gml');
const start = draw.slice(draw.indexOf('// ---- Start ----'), draw.indexOf('draw_set_color(c_white);', draw.indexOf('// ---- Start ----')));
let starts = 0, sounds = 0;
Object.assign(ctx, {
    c_red: 1, c_black: 0, snd_button_click: 1,
    draw_set_color() {}, draw_text() {}, draw_set_alpha() {}, gui_button: () => true,
    start_next_wave: () => starts++, audio_play_sound: () => sounds++,
    close_requested: false, naming: false, alarm: [], _start_message: 'Too expensive: slots 2, 3',
});
vm.runInContext(start, ctx);
assert.equal(starts, 0); assert.equal(sounds, 0);
assert.equal(ctx.close_requested, false); assert.equal(ctx.alarm[0], undefined);
assert.match(ctx.notice, /2, 3/);
ctx._start_message = ''; vm.runInContext(start, ctx);
assert.equal(starts, 1); assert.equal(sounds, 1);
assert.equal(ctx.close_requested, true); assert.equal(ctx.alarm[0], 1);
vm.runInContext(start, ctx); assert.equal(starts, 1);
console.log('Mana preview checks passed: proportional fill, level capacity, empty/full/over-limit, all slots, stacked costs and Start gating.');
