const assert=require('node:assert/strict');
const vm=require('node:vm');
const {read}=require('./gml-test-utils.cjs');
const {makeExecutionContext}=require('./execution-test-context.cjs');
const effect={effect:'harm',mods:[]};
for(const seconds of [0.0001,0.1,0.23,0.5,1,3]) {
    const h=makeExecutionContext(),c=h.ctx;
    const original=c.tune_params;
    c.tune_params=(group,id,key,fallback)=>group==='forms'&&id==='strike'&&key==='cast_time'?seconds:original(group,id,key,fallback);
    const e=h.enemy(),s=h.spell('strike',[effect]);
    const frames=Math.max(1,Math.round(seconds*60));assert.equal(s.compiled.strike_cast_frames,frames);
    // Animation and tuning changes do not change the captured impact deadline.
    c.tune_params=original;c.forms.strike.on_cast(s);
    assert.equal(s.spd,400/frames);assert.ok(s.lifetime>frames);
    c.self=s;c.form=c.forms.strike;
    c.instance_destroy=target=>{(target??s).destroyed=true;};
    const step=read('objects/obj_spells/Step_0.gml').replace(/\bexit;/g,'return;');
    function tick(){vm.runInContext(`(function(){with(self){${step}}})()`,c);}
    for(let i=1;i<frames;i++){tick();assert.equal(s.landed,false);assert.equal(s.destroyed,undefined);assert.equal(e.hp,100000);}
    tick();assert.equal(s.destroyed,undefined);assert.equal(s.landed,true);assert.equal(s.y,s.target_y);assert.equal(e.hp,99900);
    for(let i=0;i<3;i++)tick();assert.equal(e.hp,99900); // impact applies once during its ending animation
}
const h=makeExecutionContext(),c=h.ctx;
assert.equal(h.spell('strike',[effect]).compiled.strike_cast_frames,14);
for(const value of [0,-0.1,'0.5',null]) {
    c.tune_params=(group,id,key,fallback)=>group==='forms'&&id==='strike'&&key==='cast_time'?value:fallback;
    assert.throws(()=>h.spell('strike',[effect]),e=>String(e).includes('forms.strike.cast_time'));
}
const configuredTime=JSON.parse(read('datafiles/tune.json')).forms.strike.cast_time;
assert.ok(Number.isFinite(configuredTime)&&configuredTime>0);
console.log('Strike tuning checks passed: captured positive cast times, frame rounding, one-frame minimum, exact impact, long-cast lifetime and single delivery.');
