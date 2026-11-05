const assert=require('node:assert/strict');
const {makeEnemyContext}=require('./enemy-test-context.cjs');
const {load}=require('./gml-test-utils.cjs');
const h=makeEnemyContext(),ctx=h.ctx;
load(ctx,'scripts/MutationScripts/MutationScripts.gml',['enemy_ward_key','enemy_ward_active']);
Object.assign(ctx,{HEX_DAMAGE_PER_STATUS:0.1,obj_mook:'mook',obj_brute:'brute',
 spr_harm:'harm',combat_spawn_vfx:()=>{},enemy_get_leftpoint:target=>({x:target.x,y:target.y,scale:1})});
load(ctx,'scripts/GameplayScripts/GameplayScripts.gml',['deal_damage']);
const e=h.enemy();e.object_index='other';e.dmg_reduction=0;
for(const [ward,status]of [['fire-warded','burn'],['frost-warded','frost'],['lightning-warded','lightning']]){
 ctx.combat_status_initialize(e);e.mutation_keys=[ward];e.hp=1000;
 assert.equal(ctx.enemy_ward_active(e),true);ctx.deal_damage(e,100);assert.equal(e.hp,950);
 ctx.combat_status_apply(e,status,10,0.2);assert.equal(ctx.enemy_ward_active(e),false);
 ctx.deal_damage(e,100);assert.equal(e.hp,850);
 if(status==='lightning'){ctx.enemy_advance_lightning(e,10);assert.equal(ctx.enemy_ward_active(e),false);ctx.enemy_advance_lightning(e,180);}
 else ctx.combat_status_advance(e,10,false);
 assert.equal(ctx.enemy_ward_active(e),true);
}
const fire=h.spell('projectile',[{effect:'fire',mods:[]},{effect:'harm',mods:[]}]);
e.mutation_keys=['fire-warded'];ctx.combat_status_initialize(e);e.hp=1000;
ctx.spell_deliver(fire,e,2,0);assert.equal(e.hp,900); // Fire removes ward before Harm
const originalTune=ctx.tune_params;
for(const permanent of [false,true]){
 ctx.tune_params=(a,b,c,fallback)=>c==='break_permanently'?permanent:originalTune(a,b,c,fallback);
 for(const [ward,status]of [['fire-warded','burn'],['frost-warded','frost'],['lightning-warded','lightning']]){
  const target=h.enemy();target.mutation_keys=[ward];target.ward_broken=false;
  ctx.combat_status_apply(target,status,0,0.2);
  assert.equal(target.ward_broken,false,'Zero-duration applications do not break wards');
  ctx.combat_status_apply(target,'hex',10);
  const other=status==='burn'?'frost':'burn';
  ctx.combat_status_apply(target,other,10,0.2);
  assert.equal(ctx.enemy_ward_active(target),true,'Unrelated statuses leave the ward intact');
  ctx.combat_status_apply(target,status,10,0.2);
  assert.equal(target.ward_broken,permanent);
  assert.equal(ctx.enemy_ward_active(target),false);
  ctx.combat_status_advance(target,200,false);
  assert.equal(ctx.enemy_ward_active(target),!permanent,'Expiry respects the toggle');
  ctx.combat_status_apply(target,status,10,0.2);
  ctx.combat_status_clear(target,status);
  assert.equal(ctx.enemy_ward_active(target),!permanent,'Cleansing respects the toggle');
  target.hp=1000;target.object_index='other';target.dmg_reduction=0;
  ctx.combat_status_clear(target,'hex');
  ctx.deal_damage(target,100);assert.equal(target.hp,permanent?900:950);
  const fresh=h.enemy();fresh.mutation_keys=[ward];fresh.ward_broken=false;
  assert.equal(ctx.enemy_ward_active(fresh),true,'New enemies have intact wards');
 }
 const target=h.enemy();target.mutation_keys=['fire-warded'];target.ward_broken=false;
 target.hp=1000;target.object_index='other';target.dmg_reduction=0;
 ctx.spell_deliver(fire,target,2,0);assert.equal(target.hp,900);
 assert.equal(target.ward_broken,permanent,'Spell delivery latches breakage');
}
console.log('Ward checks passed: temporary/permanent breaks, matching statuses, expiry, cleansing, damage, fresh spawns and effect ordering.');
