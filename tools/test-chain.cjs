const assert=require('node:assert/strict');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const fx=(effect='harm',mods=[])=>({effect,mods});
let h=makeExecutionContext(),c=h.ctx,s=h.spell('projectile',[fx()],['chain']);
const a=h.enemy(2),b=h.enemy(3),d=h.enemy(4),far=h.enemy(8);
c.spell_deliver(s,a,2,0);assert.equal(a.hp,99900);assert.equal(b.hp,99900);assert.equal(d.hp,99900);assert.equal(far.hp,100000);
assert.deepEqual(Array.from(c.manager.combat_execution.chain_links,x=>[x.x1,x.x2]),[[250,350],[350,450]]);
// Closest Euclidean target, deterministic lineage tie break and square range boundaries.
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx()],['chain']);
let root=h.enemy(3,1),older=h.enemy(2,1),newer=h.enemy(4,1),outside=h.enemy(7,1);
c.spell_deliver(s,root,3,1);assert.equal(c.manager.combat_execution.chain_links[0].x2,older.x);assert.equal(outside.hp,100000);
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx()],['chain']);root=h.enemy(2);let edge=h.enemy(4),beyond=h.enemy(7);
c.spell_deliver(s,root,2,0);assert.equal(edge.hp,99900);assert.equal(beyond.hp,100000);
// Every physical Pierce hit receives a fresh sequential allowance, but previous victims stay excluded.
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx()],['pierce','chain']);
const group1=[h.enemy(2),h.enemy(3),h.enemy(4)],group2=[h.enemy(9),h.enemy(10),h.enemy(11)];
c.forms.projectile.on_hit(s,group1[0]);c.forms.projectile.on_hit(s,group2[0]);
assert.ok([...group1,...group2].every(e=>e.hp===99900));assert.equal(s.pierce,0);
// Area splash victims are reserved and do not become extra roots or receive overlapping payloads.
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx()],['area','chain']);
root=h.enemy(2);const splash=h.enemy(3),next=h.enemy(4),nextSplash=h.enemy(5);
c.spell_deliver(s,root,2,0,1);assert.ok([root,splash,next,nextSplash].every(e=>e.hp===99900));
assert.equal(c.manager.combat_execution.chain_links.length,1);assert.equal(c.manager.combat_execution.chain_links[0].x2,next.x);
// Location-only payloads may reserve splash victims without a targeted contact record.
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx('pull')],['area','pierce','chain']);
root=h.enemy(2);const pullSplash=h.enemy(3);h.enemy(4);
c.forms.projectile.on_hit(s,root);const remaining=s.pierce;
c.forms.projectile.on_hit(s,pullSplash);assert.equal(s.pierce,remaining);
// Lethal roots keep their recorded position; hidden enemies cannot intercept hops.
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx()],['chain']);root=h.enemy(2,0,{hp:50});const hidden=h.enemy(3,0,{is_targetable:false}),valid=h.enemy(4);
c.spell_deliver(s,root,2,0);assert.equal(root.hp,-50);assert.equal(hidden.hp,100000);assert.equal(valid.hp,99900);
// Reusing a lineage for a skeletal replacement cannot give it a second same-cast hit.
const pile=h.enemy(3);c.enemy_bind_lineage(pile,root.combat_lineage);assert.equal(c.spell_chain_fresh(s,pile),false);
// Rune roots and hops keep their Swarmer immunity.
h=makeExecutionContext();c=h.ctx;s=h.spell('rune',[fx()],['chain']);root=h.enemy(2);const swarmer=h.enemy(3,0,{object_index:'swarmer'}),eligible=h.enemy(4);
c.spell_deliver(s,null,2,0);assert.equal(swarmer.hp,100000);assert.equal(eligible.hp,99900);
// Delayed payloads use the existing scheduler and one application per occurrence/lineage.
h=makeExecutionContext();c=h.ctx;s=h.spell('projectile',[fx('fire',['delay']),fx()],['chain']);root=h.enemy(2);const delayedVictim=h.enemy(3);
c.spell_deliver(s,root,2,0);assert.equal(delayedVictim.burn_timer,180);assert.equal(delayedVictim.hp,100000);
h.tick(60);assert.equal(delayedVictim.hp,99900);
// Each reserved Beam primary gets fresh hops; a later tick may hit those lineages again.
h=makeExecutionContext();c=h.ctx;s=h.spell('beam',[fx()],['pierce','chain']);
Object.assign(s,{tick:0,lane:0,beam_lanes:[]});const primaries=[h.enemy(2),h.enemy(5),h.enemy(8)];
const side=[h.enemy(2,1),h.enemy(3,1),h.enemy(5,1),h.enemy(6,1),h.enemy(8,1),h.enemy(9,1)];
c.forms.beam.on_step(s);assert.ok([...primaries,...side].every(e=>e.hp===99975));
s.tick=14;c.forms.beam.on_step(s);assert.ok([...primaries,...side].every(e=>e.hp===99950));
console.log('Chain checks passed: sequential nearest hops, square range, ties, fresh Pierce/Beam budgets, AoE overlap, deaths, lineage, immunity and Delay.');
