const assert=require('node:assert/strict');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const h=makeExecutionContext(),c=h.ctx,s=h.spell('projectile',[{effect:'fire',mods:[]},{effect:'ice',mods:[]}],['chain']);
s.col=0x123456;const a=h.enemy(2),b=h.enemy(3,1);
c.spell_deliver(s,a,2,0);const state=c.manager.combat_execution;
assert.equal(state.chain_links.length,1);assert.equal(state.chain_links[0].colour,0x123456);
s.destroyed=true;s.col=0xffffff; // visuals retain the resolved cast colour and endpoints independently
const draws=[];
Object.assign(c,{spr_beam:1,sprite_get_width:()=>554,sprite_get_height:()=>36,sprite_get_xoffset:()=>6,sprite_get_yoffset:()=>20,
    sprite_get_speed:()=>30,sprite_get_speed_type:()=>0,sprite_get_number:()=>4,
    point_direction:(x1,y1,x2,y2)=>Math.atan2(y1-y2,x2-x1)*180/Math.PI,
    point_distance:(x1,y1,x2,y2)=>Math.hypot(x2-x1,y2-y1),draw_sprite_ext:(...args)=>draws.push(args)});
c.spell_chain_draw_links(state);assert.equal(draws.length,1);let d=draws[0];
assert.equal(d[0],1);assert.equal(d[7],0x123456);assert.equal(d[8],0.5);
const angle=d[6]*Math.PI/180,near=(v,w)=>assert.ok(Math.abs(v-w)<1e-8);
const rotate=(x,y)=>[Math.cos(angle)*x+Math.sin(angle)*y,-Math.sin(angle)*x+Math.cos(angle)*y];
const offset=rotate(-6*d[4],(18-20)*d[5]);
near(d[2]+offset[0],a.x);near(d[3]+offset[1],a.y);
const length=rotate(554*d[4],0);near(d[2]+offset[0]+length[0],b.x);near(d[3]+offset[1]+length[1],b.y);
state.clock=4;c.spell_chain_draw_links(state);d=draws.at(-1);assert.equal(d[1],2);assert.ok(d[8]<0.5);
c.spell_chain_draw_links(state);assert.deepEqual(draws.at(-1),d); // paused clock freezes animation/fade
state.clock=9;c.spell_chain_prune_links(state);assert.equal(state.chain_links.length,0);
assert.equal(c.combat_execution_create().chain_links.length,0); // room reset owns cleanup
const zero=makeExecutionContext();zero.ctx.tune_params=(g,id,key,v)=>id==='chain'&&key==='visual_duration'?0:v;
zero.ctx.spell_deliver(zero.spell('projectile',[{effect:'harm',mods:[]}],['chain']),zero.enemy(2),2,0);
assert.equal(zero.ctx.manager.combat_execution.chain_links.length,0);
console.log('Chain visual checks passed: captured spell colour, animated Beam sprite, rotated endpoint/origin alignment, source destruction, paused clock, expiry and room reset.');
