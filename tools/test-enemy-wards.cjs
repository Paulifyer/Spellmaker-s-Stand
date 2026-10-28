const assert=require('node:assert/strict');
const {makeEnemyContext}=require('./enemy-test-context.cjs');
const {load}=require('./gml-test-utils.cjs');
const h=makeEnemyContext(),ctx=h.ctx;
load(ctx,'scripts/MutationScripts/MutationScripts.gml',['enemy_ward_key','enemy_ward_active']);
Object.assign(ctx,{HEX_DAMAGE_PER_STATUS:0.1,obj_mook:'mook',obj_brute:'brute'});
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
console.log('Ward checks passed: live damage protection, matching statuses, charged Lightning and effect ordering.');
