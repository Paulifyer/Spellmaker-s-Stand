const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const {read, load, extract} = require('./gml-test-utils.cjs');
const tuning = JSON.parse(read('datafiles/tune.json'));
let saved = {};
let section;
const ctx = vm.createContext({
    is_struct: x => x !== null && typeof x === 'object',
    is_real: x => typeof x === 'number',
    clamp: (x,a,b) => Math.max(a,Math.min(b,x)), max: Math.max,
    tune_value: (g,k,d) => tuning[g]?.[k] ?? d,
    show_debug_message: () => {},
    ini_open: () => {}, ini_close: () => {},
    ini_read_real: (s,k,d) => saved[s]?.[k] ?? d,
    ini_write_real: (s,k,v) => { (saved[s] ??= {})[k] = v; }
});
load(ctx,'scripts/StarRating/StarRating.gml',['level_star_thresholds','level_star_result','save_level_stars']);
const thresholds = ctx.level_star_thresholds();
for (const [hp, expected] of [[1,1],[33,1],[33.001,2],[66,2],[66.001,3],[100,3]]) {
    assert.equal(ctx.level_star_result(true,hp,100,true,thresholds).stars,expected);
}
for (const [complete,hp,maxHp] of [[false,100,100],[true,0,100],[true,-1,100],[true,1,0]]) {
    const r=ctx.level_star_result(complete,hp,maxHp,false,thresholds);
    assert.equal(r.stars,0); assert.equal(r.flawless,false);
}
assert.equal(ctx.level_star_result(true,100,100,true,thresholds).flawless,false,'Healing does not erase damage');
const flawless=ctx.level_star_result(true,100,100,false,thresholds);
assert.equal(flawless.flawless,true); assert.equal(flawless.stars,3);
const override=ctx.level_star_thresholds({two_star_wall_hp_percent:40,three_star_wall_hp_percent:80});
assert.equal(ctx.level_star_result(true,70,100,true,override).stars,2);
for(const override of [{two_star_wall_hp_percent:90},{two_star_wall_hp_percent:-1},{three_star_wall_hp_percent:101}]) {
    assert.equal(ctx.level_star_thresholds(override).two,33);
    assert.equal(ctx.level_star_thresholds(override).three,66);
}
ctx.save_level_stars('rm_level_1',flawless);
ctx.save_level_stars('rm_level_1',ctx.level_star_result(true,1,100,true,thresholds));
assert.deepEqual(saved.rm_level_1,{stars:3,flawless:1});
ctx.save_level_stars('rm_level_2',ctx.level_star_result(true,34,100,true,thresholds));
assert.deepEqual(saved.rm_level_2,{stars:2,flawless:0});
ctx.save_level_stars('rm_level_2',ctx.level_star_result(false,100,100,false,thresholds));
assert.deepEqual(saved.rm_level_2,{stars:2,flawless:0});
// Exercise the production damage entry point, using a block for its single manager instance.
Object.assign(ctx,{village_hp:50,game_over:false,tower_damage_taken:false,village_flash_alpha:0,
    audio_play_sound:()=>{},choose:()=>0});
for(let n=1;n<=6;n++)ctx[`snd_villager_death_0${n}`]=n;
vm.runInContext(extract(read('scripts/GameplayScripts/GameplayScripts.gml'),'reduce_village_hp').replace('with (obj_gameplay_manager)',''),ctx);
ctx.reduce_village_hp(0); assert.equal(ctx.tower_damage_taken,false);
ctx.reduce_village_hp(1); assert.equal(ctx.tower_damage_taken,true);
ctx.game_over=true; ctx.reduce_village_hp(10); assert.equal(ctx.village_hp,49);
const parse=p=>JSON.parse(read(p).replace(/,\s*([}\]])/g,'$1'));
const project=parse('Spell.yyp');
for(const name of ['spr_star_earned','spr_star_empty','spr_star_flawless']) {
    assert.ok(project.resources.some(r=>r.id.name===name));
    const sprite=parse(`sprites/${name}/${name}.yy`);
    assert.equal(sprite.width,128); assert.equal(sprite.height,128);
    assert.equal(sprite.sequence.xorigin,64); assert.equal(sprite.sequence.yorigin,64);
    for(const frame of sprite.frames) {
        const file=path.join(__dirname,'..',`sprites/${name}/${frame.name}.png`);
        const png=fs.readFileSync(file);
        assert.equal(png.readUInt32BE(16),128); assert.equal(png.readUInt32BE(20),128);
        assert.ok(fs.existsSync(path.join(__dirname,'..',`sprites/${name}/layers/${frame.name}/${sprite.layers[0].name}.png`)));
    }
}
console.log('Star checks passed: strict boundaries, overrides, flawless damage history, best-result persistence, and registered sprites.');
