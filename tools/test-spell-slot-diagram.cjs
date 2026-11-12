const assert = require('node:assert/strict');
const vm = require('node:vm');
const {load} = require('./gml-test-utils.cjs');
const calls=[];
const c=vm.createContext({
    global:{spell_glyphs:{form:{projectile:{icon:1}},effect:{fire:{icon:2},ice:{icon:3}},modifier:{area:{icon:4},amplify:{icon:5}}}},
    array_push:(a,x)=>a.push(x),
    shader_set:()=>{},shader_reset:()=>{},sh_spell_recolour:1,c_gray:0x808080,
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
    assert.equal(calls.length,1+count,'Draw only form and effects, omitting modifiers');
    assert.deepEqual(calls.map(call=>call[0]),[1,...Array.from({length:count},(_,i)=>i%2?3:2)],'Preserve effect order');
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
        for(const x of [call[2]+10*call[4],call[2]+89*call[4]])
            for(const y of [call[3]+20*call[5],call[3]+79*call[5]])
                assert.ok(Math.hypot(x-60,y-61)<=41,'Visible artwork fits the circular slot');
    }
}
calls.length=0;
c.draw_spell_slot_diagram({form:'projectile',form_mods:['area'],effects:[{effect:'fire',mods:['amplify']}]},60,61,108,true);
assert.ok(calls.every(call=>call[7]===0x808080),'All glyphs receive neutral grey');
let usable=true,focused=true,menu=false,compiled={form:{name:'Projectile'},cost:20},runes=[];
Object.assign(c,{
    noone:null,Form_Beam:'beam',ROWS_PER_LANE:3,obj_spells:2,obj_spellbook:3,
    spell_slot_unlocked:i=>i<2,is_spell_usable:()=>usable,
    compile_spell:()=>compiled,is_instanceof:f=>f.name==='Beam',
    instance_exists:()=>menu,window_has_focus:()=>focused,
    floor:Math.floor,tune_params:()=>6,instance_number:()=>runes.length,instance_find:(_,i)=>runes[i]
});
c.global.menu_lock=false;
load(c,'scripts/SpellbookHelperScripts/SpellbookHelperScripts.gml',['spell_slot_can_cast']);
const player={spell_cooldowns:[0,0,0],mana_exhausted:false,channel:null,mana:20};
const spell={form:'projectile'},target={col:1,row:4};
const ready=(slot=0,t=target)=>c.spell_slot_can_cast(player,spell,slot,t);
assert.equal(ready(),true);
for(const [key,value] of [['mana_exhausted',true],['mana',19],['channel',{}]]) {
    const old=player[key];player[key]=value;assert.equal(ready(),false,key);player[key]=old;
}
player.spell_cooldowns[0]=1;assert.equal(ready(),false);player.spell_cooldowns[0]=0;
assert.equal(ready(2),false);assert.equal(c.spell_slot_can_cast(player,spell,0,undefined),false);
usable=false;assert.equal(ready(),false);usable=true;
focused=false;assert.equal(ready(),false);focused=true;
menu=true;assert.equal(ready(),false);menu=false;
c.global.menu_lock=true;assert.equal(ready(),false);c.global.menu_lock=false;
compiled={form:{name:'Beam'},cost:100};assert.equal(ready(),true,'Beam uses its drain rules rather than upfront cost');
compiled={form:{name:'Rune'},cost:20};runes=[{form:{name:'Rune'},target_col:1,lane:1}];
assert.equal(ready(),false,'Occupied rune target');runes=[];assert.equal(ready(),true);
console.log('Spell slot diagram checks passed: centered form, ordered effects, omitted modifiers, circular bounds and disabled colour.');
console.log('Spell slot readiness checks passed: cooldown, mana, channel, locks, targeting and rune occupancy.');
