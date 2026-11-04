const assert = require('node:assert/strict');
const {makeExecutionContext} = require('./execution-test-context.cjs');
const {load, read} = require('./gml-test-utils.cjs');
const h = makeExecutionContext(), c = h.ctx;
const sprites = {};
for (const name of ['spr_fire_1', 'spr_fire_2', 'spr_stun_1', 'spr_stun_2', 'spr_charged']) {
    sprites[name] = JSON.parse(read(`sprites/${name}/${name}.yy`).replace(/,\s*([}\]])/g, '$1'));
    c[name] = name;
    assert.equal(sprites[name].sequence.playbackSpeedType, 0, 'Draw functions expect FPS sprites');
}
const calls = [];
Object.assign(c, {
    sprite_get_number:s=>sprites[s].frames.length,
    sprite_get_speed:s=>sprites[s].sequence.playbackSpeed,
    sprite_get_bbox_left:s=>sprites[s].bbox_left,
    sprite_get_bbox_right:s=>sprites[s].bbox_right,
    sprite_get_bbox_bottom:s=>sprites[s].bbox_bottom,
    sprite_get_xoffset:s=>sprites[s].sequence.xorigin,
    sprite_get_yoffset:s=>sprites[s].sequence.yorigin,
    enemy_visual_bounds:()=>({x:100, y:100, width:80, height:120}),
    draw_sprite_ext:(...args)=>calls.push(args), c_white:0xffffff
});
load(c, 'scripts/EnemyVisualScripts/EnemyVisualScripts.gml', ['enemy_draw_fire', 'enemy_draw_stun', 'enemy_draw_charged']);
const e = h.enemy(2, 0, {image_alpha:0.75});
function draw(name, clock) {
    c.manager.combat_execution.clock = clock;
    calls.length = 0;
    c[`enemy_draw_${name}`](e);
    for (const call of calls) {
        assert.ok(call.slice(1).every(Number.isFinite), 'Draw arguments must be finite');
        assert.ok(call[1] >= 0 && call[1] < sprites[call[0]].frames.length);
        assert.equal(call[8], 0.75);
    }
    return calls[0];
}
for (const name of ['fire', 'stun', 'charged']) assert.equal(draw(name, 0), undefined);
for (const [name, timer] of [['fire', 'burn_timer'], ['stun', 'stun_timer']]) {
    e[timer] = 180;
    const start = draw(name, 0);
    assert.equal(start[0], `spr_${name}_1`);
    assert.equal(start[1], 0);
    assert.equal(draw(name, 11)[0], `spr_${name}_1`);
    const loop = draw(name, 12);
    assert.equal(loop[0], `spr_${name}_2`);
    assert.equal(loop[1], 0);
    assert.equal(loop[4], start[4], 'Start and loop use the same scale');
    assert.equal(draw(name, 24)[1], 1);
    assert.deepEqual(draw(name, 24), draw(name, 24), 'Paused clock freezes drawing');
    e[timer] = 300;
    assert.equal(draw(name, 36)[1], 2, 'Duration refresh preserves animation');
    const count = sprites[`spr_${name}_2`].frames.length;
    assert.equal(draw(name, 12 + count * 12)[1], 0, 'Loop wraps');
    e[timer] = 0;
    assert.equal(draw(name, 100), undefined);
    assert.equal(e[`${name}_visual`], undefined);
    e[timer] = 180;
    assert.equal(draw(name, 101)[0], `spr_${name}_1`, 'Reapplication restarts');
    e.hp = 0;
    assert.equal(draw(name, 102), undefined);
    e.hp = 1000; e[timer] = 0;
}
e.stun_timer = 10;
e.stun_immune_timer = 20;
assert.equal(draw('charged', 0), undefined, 'Charged must not draw during stun');
e.stun_immune_timer = 0;
c.enemy_advance_lightning(e, 10);
assert.equal(draw('stun', 10), undefined);
assert.equal(draw('charged', 10)[1], 0);
assert.equal(draw('charged', 22)[1], 1);
assert.equal(draw('charged', 94)[1], 0);
c.combat_status_consume_charge(e);
assert.equal(draw('charged', 95), undefined);
assert.equal(e.charged_visual, undefined);
assert.ok(read('objects/obj_enemy_parent/Draw_0.gml').includes('enemy_draw_charged(id)'));
console.log('Status visual checks passed: actual sprite assets, startup, loops, stable scale, pause/refresh, reapplication, death and Stun-to-Charged transition.');
