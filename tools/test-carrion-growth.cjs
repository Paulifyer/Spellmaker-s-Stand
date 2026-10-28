const assert = require('node:assert/strict');
const vm = require('node:vm');
const {read, load} = require('./gml-test-utils.cjs');
const {makeEnemyContext} = require('./enemy-test-context.cjs');
const tuning = JSON.parse(read('datafiles/tune.json')).enemies.carrion;
function setup(overrides = {}) {
    // Fixed scenario values keep assertions stable when designers edit the live JSON.
    const h = makeEnemyContext(), ctx = h.ctx, config = {...tuning, hp_gain_per_death_mult: 0.2,
        deaths_to_frenzy: 5, frenzy_speed_mult: 3, screech_duration: 0.5, ...overrides};
    load(ctx, 'scripts/MutationScripts/MutationScripts.gml', ['enemy_is_bonepile']);
    load(ctx, 'scripts/EnemyHelper/EnemyHelper.gml', ['carrion_death_in_range', 'carrion_begin_frenzy',
        'carrion_update_frenzy', 'enemy_update_movement', 'enemy_notify_combat_death', 'enemy_update_pull']);
    Object.assign(ctx, {obj_carrion: 'carrion', obj_siphon: 'siphon', BASE_HP: 150,
        abs: Math.abs, tune_enemy: (_, key, fallback) => config[key] ?? fallback,
        instance_create_depth: () => {}, event_inherited: () => {ctx.max_hp = 150; ctx.base_speed = 1;},
        spr_enemy_carrionscreech: 'screech', spr_enemy_carrionflight: 'flight', snd_carrion_screech: 'screech-sound',
        obj_mook: 'mook', obj_brute: 'brute',
        audio_play_sound: (...args) => h.sounds.push(args),
        point_distance: (x1,y1,x2,y2) => Math.hypot(x2-x1,y2-y1),
        point_direction: (x1,y1,x2,y2) => -Math.atan2(y2-y1,x2-x1)*180/Math.PI,
        lerp: (a,b,t) => a+(b-a)*t});
    h.sounds = [];
    const source = read('objects/obj_carrion/Create_0.gml');
    for (const resource of source.match(/\b(?:spr|obj)_\w+/g) || []) ctx[resource] = resource;
    const number = ctx.instance_number, find = ctx.instance_find;
    const carrions = () => h.enemies.filter(e => !e.destroyed && e.object_index === 'carrion');
    ctx.instance_number = type => type === 'carrion' ? carrions().length : number(type);
    ctx.instance_find = (type, i) => type === 'carrion' ? carrions()[i] : find(type, i);
    h.carrion = (col = 4, lane = 4) => {
        vm.runInContext(source, ctx);
        const state = {};
        for (const key of ['hp', 'max_hp', 'base_speed', 'hp_gain_per_death_mult', 'deaths_to_frenzy',
            'frenzy_speed_mult', 'nearby_deaths', 'frenzied', 'hit_w', 'screech_duration_frames',
            'screech_timer', 'mask_index', 'walk_side_sprite']) state[key] = ctx[key];
        return h.enemy(col, lane, {...state, object_index: 'carrion', image_xscale: 1, image_yscale: 1,
            sprite_index: state.walk_side_sprite, mutation: undefined});
    };
    h.dead = (col = 5, lane = 4) => h.enemy(col, lane, {hp: 0, death_notified: false, depth: 0});
    h.kill = e => ctx.enemy_notify_combat_death(e);
    h.advance = (c, frames = c.screech_timer) => {
        for (let i = 0; i < frames; i++) ctx.carrion_update_frenzy(c);
    };
    return h;
}
const near = (a, b) => assert.ok(Math.abs(a - b) < 1e-9, `${a} != ${b}`);
// Run the real Create event and notification, including wounded HP and death deduplication.
{
    const h = setup(), c = h.carrion();
    assert.equal(c.max_hp, 750); c.hp = 500;
    for (let i = 1; i <= 6; i++) {
        const e = h.dead(); h.kill(e); h.kill(e);
        assert.equal(c.nearby_deaths, i);
        assert.equal(c.max_hp, 750 + i * 30); assert.equal(c.hp, 500 + i * 30);
        if (i === 5) {
            near(c.base_speed, 0.7); assert.equal(c.my_speed, 0);
            assert.equal(c.sprite_index, 'screech'); assert.equal(c.screech_timer, 30);
            h.advance(c);
        }
        near(c.base_speed, i < 5 ? 0.7 : 2.1); assert.equal(c.frenzied, i >= 5);
    }
    near(c.image_xscale, 1.6); assert.equal(c.hit_w, 120);
    const pile = h.dead(); pile.is_bonepile = true; h.kill(pile);
    const living = h.dead(); living.hp = 1; h.kill(living);
    h.kill(h.dead(10)); assert.equal(c.nearby_deaths, 6);
    const skeleton = h.dead(); h.kill(skeleton);
    const revived = h.dead(); revived.combat_lineage = skeleton.combat_lineage; h.kill(revived);
    assert.equal(c.nearby_deaths, 8);
    assert.equal(h.sounds.length, 1); assert.equal(c.sprite_index, 'flight');
    c.hp = 0; h.kill(h.dead()); assert.equal(c.hp, 0); assert.equal(c.nearby_deaths, 8);
}
// Count complete shapes, including the adjacent diagonal cells at radius two.
for (const [radius, expected] of [[0, 1], [1, 9], [2, 13], [3, 29]]) {
    const h = setup({death_radius_tiles: radius}), c = h.carrion();
    let count = 0;
    for (let dx = -4; dx <= 4; dx++) for (let dy = -4; dy <= 4; dy++) {
        const e = h.dead(4 + dx, 4 + dy);
        if (h.ctx.carrion_death_in_range(c, e, radius)) count++;
        h.kill(e);
    }
    assert.equal(count, expected); assert.equal(c.nearby_deaths, expected);
}
// Tunable values, independent observers, simultaneous deaths and movement composition.
{
    const h = setup({hp_gain_per_death_mult: 0.4, deaths_to_frenzy: 2, frenzy_speed_mult: 4, death_radius_tiles: 2});
    const c = h.carrion(), other = h.carrion(6, 4);
    c.slow_timer = 60; c.slow_amt = 0.6;
    h.ctx.enemy_banner_speed = () => 1.3;
    [h.dead(5, 5), h.dead(4, 6), h.dead(5, 4)].forEach(h.kill);
    assert.equal(c.nearby_deaths, 3); assert.equal(other.nearby_deaths, 2);
    assert.equal(c.screech_timer, 30); assert.equal(other.screech_timer, 30);
    h.advance(c); h.advance(other);
    assert.equal(c.max_hp, 930); near(c.base_speed, 2.8);
    near(c.my_speed, 2.8 * 1.3 * 0.4);
    c.stun_timer = 10; h.kill(h.dead()); assert.equal(c.path_speed, 0);
    c.stun_timer = 0; c.pull = {}; h.kill(h.dead()); assert.equal(c.path_speed, 0);
    c.pull = undefined; h.ctx.enemy_update_movement(c); near(c.path_speed, c.my_speed);
    near(c.base_speed, 2.8);
}
// Actual Begin Step gates village attacks, and the unchanged parent Step continues
// advancing Burn, Frost, Charged and Pull while the normal path speed is zero.
{
    const h = setup({deaths_to_frenzy: 1}), c = h.carrion(), ctx = h.ctx;
    c.path_position = 1; c.ready_to_attack = true; c.damage_dealt = 3;
    c.alarm = [0]; c.attack_delay = 1;
    c.pull = {sx:c.x, sy:c.y, tx:c.x-100, ty:c.y, t:0, dur:20, hold:30, xs:1, ys:1};
    c.burn_timer = 40; c.burn_dmg = 1; c.slow_timer = 40; c.slow_amt = 0.2;
    c.stun_immune_timer = 40;
    let attacks = 0;
    ctx.reduce_village_hp = () => attacks++;
    ctx.id = c;
    const begin = read('objects/obj_carrion/Step_1.gml').replace(/\bexit;/g, 'return;');
    ctx.event_inherited = () => vm.runInContext('with (id) {'+read('objects/obj_enemy_parent/Step_1.gml')+'}', ctx);
    const beginStep = () => vm.runInContext('(function(){with(id){'+begin+'}})()', ctx);
    const normalStep = () => vm.runInContext('with (id) {'+read('objects/obj_enemy_parent/Step_0.gml')+'}', ctx);
    h.kill(h.dead());
    assert.deepEqual(h.sounds, [['screech-sound',10,false]]);
    const initialX = c.x;
    beginStep(); normalStep();
    assert.equal(attacks, 0); assert.equal(c.screech_timer, 29); assert.equal(c.path_speed, 0);
    assert.notEqual(c.x, initialX); assert.equal(c.pull.t, 1);
    assert.equal(c.burn_timer, 39); assert.equal(c.slow_timer, 39); assert.equal(c.stun_immune_timer, 39);
    assert.equal(c.sprite_index, 'screech');
    for (let i = 0; i < 28; i++) beginStep();
    assert.equal(c.screech_timer, 1); assert.equal(attacks, 0);
    beginStep();
    assert.equal(c.screech_timer, 0); assert.equal(attacks, 1);
    assert.equal(c.sprite_index, 'flight'); assert.equal(c.walk_side_sprite, 'flight');
    assert.equal(c.walk_up_sprite, 'flight'); assert.equal(c.walk_down_sprite, 'flight');
    assert.equal(c.mask_index, 'spr_enemy_carrionwalk');
    near(c.base_speed, 2.1); assert.equal(c.path_speed, 0); // Pull still active.
    c.pull = undefined; c.stun_timer = 3; ctx.enemy_update_movement(c); assert.equal(c.path_speed, 0);
    c.stun_timer = 0; ctx.enemy_update_movement(c); near(c.path_speed, 2.1*0.8);
    h.kill(h.dead()); assert.equal(c.screech_timer, 0); assert.equal(h.sounds.length, 1);
    h.advance(c,60); near(c.base_speed,2.1);
}
for (const [seconds, frames] of [[0.25,15],[0,1],[-1,1]]) {
    const h = setup({screech_duration:seconds, deaths_to_frenzy:1}), c=h.carrion();
    h.kill(h.dead()); assert.equal(c.screech_timer,frames);
    h.advance(c,frames-1); assert.equal(c.sprite_index,'screech');
    h.advance(c,1); assert.equal(c.sprite_index,'flight');
}
console.log('Carrion checks passed: HP/frenzy tuning, grid shapes, death lifecycle, exact screech timing, attack gating, live Pull/statuses and flight.');
