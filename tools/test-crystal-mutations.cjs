const assert=require('node:assert/strict');
const vm=require('node:vm');
const {load}=require('./gml-test-utils.cjs');
const calls=[];
const c=vm.createContext({
    normalize_mutation_keys:x=>x===undefined?[]:Array.isArray(x)?x:[x],
    array_contains:(a,x)=>a.includes(x),min:Math.min,max:Math.max,floor:Math.floor,sin:Math.sin,
    obj_siege_beast:10,obj_carrion:11,c_gray:123,c_white:456,TARGET_ROOM_SPEED:60,
    spritespeed_framespergameframe:1,sprite_get_speed_type:()=>0,
    sprite_get_speed:()=>5,sprite_get_number:()=>8,
    sprite_get_bbox_left:()=>20,sprite_get_bbox_right:()=>119,
    sprite_get_bbox_top:()=>30,sprite_get_bbox_bottom:()=>149,
    sprite_get_xoffset:()=>0,sprite_get_yoffset:()=>0,
    spr_ward_fire_wide:1,spr_ward_fire_narrow:2,spr_ward_frost_wide:3,spr_ward_frost_narrow:4,
    spr_ward_lightning_wide:5,spr_ward_lightning_narrow:6,spr_banneret_speed:7,
    draw_sprite_ext:(...args)=>calls.push(args)
});
load(c,'scripts/EnemyVisualScripts/EnemyVisualScripts.gml',['draw_enemy_mutation_preview']);
for(const [key,narrow,wide]of [['fire-warded',2,1],['frost-warded',4,3],['lightning-warded',6,5]]) {
    for(const enemy of [0,10,11]) {
        calls.length=0;
        const entry={enemy,mutation:[key,'skeletal','banneret']};
        c.draw_enemy_mutation_preview(entry,99,500,300,0);
        assert.equal(calls.length,3);
        assert.equal(calls[0][7],123,'Skeletal tint survives combined mutations');
        assert.equal(calls[1][0],enemy===0?narrow:wide);
        assert.equal(calls[1][1],0);
        assert.equal(calls[1][2]+69.5*calls[1][4],500);
        assert.equal(calls[1][3]+89.5*calls[1][5],300);
        const bannerY=calls[2][3];calls.length=0;
        c.draw_enemy_mutation_preview(entry,99,500,300,0.4);
        assert.equal(calls[1][1],2,'Ward progresses using menu time');
        assert.notEqual(calls[2][3],bannerY,'Banner animates');
        calls.length=0;c.draw_enemy_mutation_preview(entry,99,500,300,1.6);
        assert.equal(calls[1][1],1,'Ward loops without replaying its appearance');
    }
}
calls.length=0;c.draw_enemy_mutation_preview({enemy:0},99,500,300,1);
assert.equal(calls.length,1,'Ordinary enemies have no mutation overlays');
console.log('Crystal ball checks passed: three animated wards, wide variants, combined mutations, Skeletal tint and Banneret movement.');
