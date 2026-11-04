const assert = require('node:assert/strict');
const vm = require('node:vm');
const {load} = require('./gml-test-utils.cjs');
const calls=[];
const c=vm.createContext({
    global:{spell_glyphs:{form:{projectile:{icon:1}},effect:{fire:{icon:2},ice:{icon:3}}}},
    is_struct:x=>!!x&&typeof x==='object',array_length:a=>a.length,
    min:Math.min,max:Math.max,sin:Math.sin,degtorad:x=>x*Math.PI/180,
    lengthdir_x:(r,a)=>r*Math.cos(a*Math.PI/180),lengthdir_y:(r,a)=>-r*Math.sin(a*Math.PI/180),
    sprite_get_bbox_left:()=>10,sprite_get_bbox_right:()=>89,
    sprite_get_bbox_top:()=>20,sprite_get_bbox_bottom:()=>79,
    sprite_get_xoffset:()=>0,sprite_get_yoffset:()=>0,
    draw_sprite_ext:(...args)=>calls.push(args),c_white:0xffffff
});
load(c,'scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml',['draw_spell_slot_glyph','draw_spell_slot_diagram']);
for(const count of [0,1,2,3,6,12]) {
    calls.length=0;
    c.draw_spell_slot_diagram({form:'projectile',form_mods:['area'],effects:Array.from({length:count},(_,i)=>({effect:i%2?'ice':'fire',mods:['amplify']}))},60,61,82);
    assert.equal(calls.length,count+1,'Draw form/effect occurrences only');
    const centers=calls.map(call=>({x:call[2]+49.5*call[4],y:call[3]+49.5*call[5]}));
    assert.equal(centers[0].x,60);assert.equal(centers[0].y,61);
    for(let i=0;i<calls.length;i++) {
        const call=calls[i];
        assert.equal(call[6],0,'Glyph artwork stays upright');
        assert.ok(call[2]+10*call[4]>=19 && call[2]+89*call[4]<=101);
        assert.ok(call[3]+20*call[5]>=20 && call[3]+79*call[5]<=102);
        if(i) {
            assert.ok(call[4]<calls[0][4]);
            assert.ok(Math.abs(Math.hypot(centers[i].x-60,centers[i].y-61)-82*0.34)<1e-8);
            const expected=90+(i-1)*360/count;
            assert.ok(Math.abs(centers[i].x-(60+82*0.34*Math.cos(expected*Math.PI/180)))<1e-8);
        }
    }
}
console.log('Spell slot diagram checks passed: centered form, evenly spaced upright effects, smaller sizes, slot bounds and omitted modifiers.');
