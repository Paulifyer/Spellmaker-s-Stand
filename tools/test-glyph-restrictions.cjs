const assert=require('node:assert/strict');
const vm=require('node:vm');
const {load,read,extract}=require('./gml-test-utils.cjs');
const {makeContext}=require('./construction-test-context.cjs');
const ctx=makeContext();
const fresh=form=>({form,form_mods:[],effects:[]});
let s=fresh('projectile');
assert.equal(ctx.spell_add_glyph(s,'effect','pull',-1),'');
assert.match(ctx.spell_add_glyph(s,'modifier','area',0),/Effect/);
assert.equal(ctx.spell_add_glyph(s,'modifier','area',-1),'');
assert.equal(ctx.is_spell_usable(s),true); // form AoE plus Pull is legal
assert.equal(ctx.spell_add_glyph(s,'form','beam',-1),'');
assert.equal(s.effects.length,0);assert.deepEqual(Array.from(s.form_mods),['area']);
assert.match(ctx.spell_add_glyph(s,'effect','pull',-1),/Form/);
s=fresh('projectile');ctx.spell_add_glyph(s,'effect','hex',-1);
assert.match(ctx.spell_add_glyph(s,'modifier','amplify',0),/Effect/);
assert.equal(ctx.spell_add_glyph(s,'modifier','extend_time',0),'');
assert.equal(ctx.is_spell_usable(s),true);
s.effects[0].mods.push('amplify');assert.equal(ctx.is_spell_usable(s),false);
Object.assign(ctx,{HEX_DAMAGE_PER_STATUS:0.1,tune_params:(_,__,___,v)=>v,
    obj_mook:'mook',obj_brute:'brute'});
load(ctx,'scripts/GameplayScripts/GameplayScripts.gml',['deal_damage']);
const enemy={hp:1000,hex_timer:100,burn_timer:0,slow_timer:0,stun_timer:0,stun_immune_timer:0,dmg_reduction:0,object_index:'other'};
function damage(){enemy.hp=1000;ctx.deal_damage(enemy,100);return 1000-enemy.hp;}
assert.equal(damage(),110); // Hex counts itself
enemy.burn_timer=60;assert.equal(damage(),120);
enemy.slow_timer=60;assert.equal(damage(),130);
enemy.stun_immune_timer=60;assert.equal(damage(),140);
enemy.stun_timer=60;assert.equal(damage(),140); // Lightning counted once
enemy.burn_timer=0;assert.equal(damage(),130); // no Hex reapplication
enemy.hex_timer=0;assert.equal(damage(),100);
const pullBody=extract(read('scripts/EffectGlyphs/EffectGlyphs.gml'),'Elem_Pull');
const callback=pullBody.slice(pullBody.indexOf('on_impact = function')).replace('function(','function impact(');
const pull=vm.runInContext(`(${extract(callback,'impact')})`,ctx);
const regions=[];
Object.assign(ctx,{GRID_X0:0,TILE_W:100,LANE_H:100,TARGET_ROOM_SPEED:60,pull_sec:0.4,hold_sec:0.2,
    show_debug_message(){},enemies_in_region_list:(...r)=>{regions.push(r);return [];}});
ctx.global.lane_top=[0,100,200];
pull({area:false},{duration:1},3,1);pull({area:true},{duration:1},3,1);
assert.deepEqual(regions,[[2,4,0,2],[2,4,0,2]]);
console.log('Glyph restriction checks passed: Pull/Form AoE, Beam exclusion, Hex modifiers and live status scaling.');
