const assert = require('node:assert/strict');
const {makeExecutionContext, callback} = require('./execution-test-context.cjs');
const {load, read} = require('./gml-test-utils.cjs');
const h = makeExecutionContext(), c = h.ctx, sprites = {}, calls = [];
for (const name of ['spr_snap_1', 'spr_snap_2', 'spr_snap_3']) {
    c[name] = name;
    sprites[name] = JSON.parse(read(`sprites/${name}/${name}.yy`).replace(/,\s*([}\]])/g, '$1'));
}
Object.assign(c, {
    effect_sprites:['spr_snap_1','spr_snap_2','spr_snap_3'],
    sprite_get_number:s=>sprites[s].frames.length,
    sprite_get_speed:s=>sprites[s].sequence.playbackSpeed,
    sprite_get_bbox_left:s=>sprites[s].bbox_left,
    sprite_get_bbox_right:s=>sprites[s].bbox_right,
    sprite_get_bbox_top:s=>sprites[s].bbox_top,
    sprite_get_bbox_bottom:s=>sprites[s].bbox_bottom,
    sprite_get_xoffset:s=>sprites[s].sequence.xorigin,
    sprite_get_yoffset:s=>sprites[s].sequence.yorigin,
    enemy_visual_bounds:()=>({x:250,y:120,width:80,height:100}),
    draw_sprite_ext:(...args)=>calls.push(args),
    array_delete:(a,i,n)=>a.splice(i,n), c_white:0xffffff
});
c.sprite_get_name=s=>s;
load(c,'scripts/GlyphVisualScripts/GlyphVisualScripts.gml',['combat_spawn_vfx','combat_draw_vfx']);
load(c,'scripts/EnemyVisualScripts/EnemyVisualScripts.gml',['enemy_get_leftpoint']);
const snap = callback(c,'scripts/EffectGlyphs/EffectGlyphs.gml','Elem_Snap','on_hit');
const state = c.manager.combat_execution;
for (let stacks=0; stacks<=3; stacks++) {
    state.visuals=[];state.clock=0;
    const enemy=h.enemy();
    for(let i=0;i<stacks;i++) c.combat_status_apply(enemy,'frost',180,0.2);
    const spell=h.spell('projectile',[{effect:'snap',mods:[]}]);
    spell.effects[0].effect.effect_sprites=c.effect_sprites;
    snap(spell,enemy,spell.effects[0]);
    assert.equal(state.visuals.length,stacks?1:0);
    if(!stacks) continue;
    const v=state.visuals[0], data=sprites[v.sprite];
    assert.ok(Number.isFinite(v.xs) && v.xs >= 0.9, 'Automatic scale must be visible');
    assert.equal(v.ys,v.xs);
    assert.equal(v.sprite,`spr_snap_${stacks}`);
    assert.ok(Math.abs(v.x+(data.bbox_left+data.bbox_right)/2*v.xs-250)<1e-8);
    assert.ok(Math.abs(v.y+(data.bbox_top+data.bbox_bottom)/2*v.ys-120)<1e-8);
    const lifetime=data.frames.length*12;
    for(let t=0;t<lifetime;t++) {
        state.clock=t;calls.length=0;c.combat_draw_vfx();
        assert.equal(calls.length,1);
        assert.equal(calls[0][1],Math.floor(t/12));
    }
    state.clock=lifetime;c.combat_draw_vfx();
    assert.equal(state.visuals.length,0,'Expired index zero must be removed');
}
state.visuals=[];state.clock=0;
c.combat_spawn_vfx('spr_snap_2',0,0,1,1);
c.combat_spawn_vfx('spr_snap_1',0,0,1,1);
c.combat_spawn_vfx('spr_snap_1',0,0,1,1);
state.clock=40;c.combat_spawn_vfx('spr_snap_3',0,0,1,1);
const survivor=state.visuals[3];
state.clock=50;c.combat_draw_vfx();
assert.equal(state.visuals.length,2);
assert.equal(state.visuals[1],survivor,'Expiry must preserve newer effects');
console.log('Snap visual checks passed: 0-3 stacks, centering, all animation frames, completion and overlapping VFX cleanup.');
