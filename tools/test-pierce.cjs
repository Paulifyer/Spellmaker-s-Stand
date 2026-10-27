// Exercise the actual GML callbacks with mocked engine calls; no GameMaker runtime required.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../scripts/FormGlyphs/FormGlyphs.gml'), 'utf8');
function callback(form, event) {
    const start = source.indexOf(`function Form_${form}()`);
    const bodyStart = source.indexOf(`${event} = function(spell, target) {`, start);
    const singleStart = source.indexOf(`${event} = function(spell) {`, start);
    const offset = bodyStart >= 0 && (singleStart < 0 || bodyStart < singleStart) ? bodyStart : singleStart;
    assert.ok(offset >= start);
    const open = source.indexOf('{', offset);
    let depth = 1, end = open + 1;
    while (depth) { if (source[end] === '{') depth++; if (source[end] === '}') depth--; end++; }
    return source.slice(source.indexOf('function', offset), end).replace(/\bmod\b/g, '%');
}
let enemies = [], applied = [], impacts = 0;
const ctx = {
    GRID_X0: 0, TILE_W: 100, ROWS_PER_LANE: 1, GRID_COLS: 20,
    LANE_COUNT: 3, TARGET_ROOM_SPEED: 60, obj_enemy_parent: 1,
    global: { lane_top: [0, 100, 200] },
    floor: Math.floor, min: Math.min, max: Math.max,
    array_contains: (a, v) => a.includes(v), array_length: a => a.length,
    array_push: (a, v) => a.push(v), array_sort: (a, f) => a.sort(f),
    instance_exists: e => !!e && !e.destroyed,
    instance_destroy: s => { s.destroyed = true; },
    instance_number: () => enemies.length, instance_find: (_, i) => enemies[i],
    enemy_lane: e => e.lane, world_to_grid: (_, y) => ({lane: Math.floor(y / 100)}),
    spell_impact: () => { impacts++; },
    spell_hit: (s, e) => {
        if (!e.is_targetable || s.hit_list.includes(e)) return false;
        s.hit_list.push(e);
        for (const effect of s.effects) applied.push([e, effect]);
        return true;
    },
};
ctx.spell_hit_area = s => { for (const e of enemies) ctx.spell_hit(s, e); };
vm.createContext(ctx);
const projectile = vm.runInContext(`(${callback('Projectile', 'on_hit')})`, ctx);
const beam = vm.runInContext(`(${callback('Beam', 'on_step')})`, ctx);
const enemy = (x, lane = 0) => ({x, y: lane * 100, lane, is_targetable: true});
const spell = () => ({x: 0, target_row: 0, pierce: 2, hit_list: [], effects: ['fire', 'ice'], area: false});

// The reported combination: slow/burning enemies remain overlapped over many frames.
let s = spell(), a = enemy(100), b = enemy(200), c = enemy(300);
projectile(s, a);
for (let i = 0; i < 20; i++) projectile(s, a);
assert.equal(s.pierce, 1);
assert.equal(s.destroyed, undefined);
assert.equal(applied.length, 2);
projectile(s, b);
assert.equal(s.destroyed, undefined);
projectile(s, c);
assert.equal(s.destroyed, true);
assert.deepEqual(applied.map(v => v[1]), ['fire', 'ice', 'fire', 'ice', 'fire', 'ice']);

// Area victims do not consume additional penetrations when touched later.
s = spell(); s.area = true; enemies = [a, b]; impacts = 0;
projectile(s, a); projectile(s, b);
assert.equal(s.pierce, 1); assert.equal(impacts, 1);
const untargetable = {...enemy(400), is_targetable: false};
projectile(s, untargetable); assert.equal(s.pierce, 1);
s = spell(); s.pierce = 0; projectile(s, a); assert.equal(s.destroyed, true);

// Beam penetration is finite, nearest-first, per lane, and repeats on its damage tick.
enemies = [enemy(400), enemy(100), enemy(300), enemy(200), untargetable, enemy(50, 1)];
s = spell(); Object.assign(s, {lane: 0, tick: 0, beam_lanes: []});
applied = []; beam(s);
assert.deepEqual(applied.filter(v => v[1] === 'fire').map(v => v[0].x), [100, 200, 300]);
assert.equal(s.beam_lanes[0].len, 300);
beam(s); assert.equal(applied.length, 6);
s.tick = 14; beam(s); assert.equal(applied.length, 12);
s = spell(); Object.assign(s, {lane: 0, tick: 0, pierce: 0, area: true, beam_lanes: []});
applied = []; beam(s);
assert.deepEqual(applied.filter(v => v[1] === 'fire').map(v => v[0].x), [100, 50]);
console.log('Pierce regression checks passed: Projectile + Fire + Ice, repeated overlap, Area, zero Pierce, and finite Beam targets.');
