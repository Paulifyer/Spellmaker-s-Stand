const assert = require('node:assert/strict');
const vm = require('node:vm');
const {load, read} = require('./gml-test-utils.cjs');
let saved = {};
const ctx = vm.createContext({
    clamp:(v,a,b)=>Math.max(a,Math.min(b,v)), floor:Math.floor,
    max:Math.max, array_length:a=>a.length, array_push:(a,v)=>a.push(v),
    room_get_name:r=>r, ini_open:()=>{}, ini_close:()=>{},
    ini_read_real:(s,k,d)=>saved[s]?.[k] ?? d,
    ini_write_real:(s,k,v)=>{ (saved[s] ??= {})[k] = v; }
});
load(ctx, 'scripts/StarRating/StarRating.gml', ['level_select_progress', 'save_level_stars']);
const rooms = ['level1','level2','level3','level4'];
const unlocked = ()=>Array.from(ctx.level_select_progress(rooms), p=>p.unlocked);
assert.deepEqual(unlocked(), [true,false,false,false]);
ctx.save_level_stars('level1', {stars:0,flawless:false});
assert.deepEqual(unlocked(), [true,false,false,false], 'Loss must not unlock');
ctx.save_level_stars('level1', {stars:1,flawless:false});
assert.deepEqual(unlocked(), [true,true,false,false]);
ctx.save_level_stars('level2', {stars:2,flawless:false});
assert.deepEqual(unlocked(), [true,true,true,false]);
ctx.save_level_stars('level1', {stars:0,flawless:false});
assert.deepEqual(unlocked(), [true,true,true,false], 'Replay loss preserves progress');
ctx.save_level_stars('level3', {stars:3,flawless:true});
ctx.save_level_stars('level4', {stars:1,flawless:false});
assert.deepEqual(unlocked(), [true,true,true,true]);
saved = {level3:{stars:3}};
assert.deepEqual(unlocked(), [true,false,false,false], 'Out-of-order debug clears cannot bypass progression');

// Execute the actual selection handler for keyboard and mouse input.
const step = read('objects/ob_level_select/Step_0.gml').replace(/\bexit;/g, 'return;');
let chosenKey, click, visits=[];
Object.assign(ctx, {
    level_rooms:rooms, level_progress:ctx.level_select_progress(rooms),
    level_buttons:rooms.map((_,i)=>({x:i*100,y:0,w:90,h:50})),
    back_button:{x:0,y:200,w:90,h:50},
    global:{level_config:Object.fromEntries(rooms.map(r=>[r,{}]))},
    vk_escape:27, vk_f8:119, debug_unlock_all:false, mb_left:1, cr_none:0, rm_menu:'menu',
    keyboard_check_pressed:k=>k===chosenKey, ord:s=>s.charCodeAt(0), string:String,
    mouse_check_button_pressed:()=>!!click,
    device_mouse_x_to_gui:()=>click?.x, device_mouse_y_to_gui:()=>click?.y,
    level_select_mouse:()=>({x:click?.x,y:click?.y}),
    point_in_rectangle:(x,y,a,b,c,d)=>x>=a&&x<=c&&y>=b&&y<=d,
    variable_struct_exists:(o,k)=>Object.hasOwn(o,k),
    window_set_cursor:()=>{}, room_goto:r=>visits.push(r), show_debug_message:()=>{}
});
const run = ()=>vm.runInContext('(function(){'+step+'})()',ctx);
chosenKey=50; run(); assert.deepEqual(visits,[]);
chosenKey=undefined; click={x:110,y:20}; run(); assert.deepEqual(visits,[]);
click={x:10,y:20}; run(); assert.deepEqual(visits,['level1']);
ctx.save_level_stars('level1',{stars:1,flawless:false});
ctx.level_progress=ctx.level_select_progress(rooms);
click=undefined; chosenKey=50; run(); assert.deepEqual(visits,['level1','level2']);
const beforeDebug = JSON.stringify(saved);
chosenKey=119; run(); assert.equal(ctx.debug_unlock_all,true);
chosenKey=52; run(); assert.equal(visits.at(-1),'level4');
chosenKey=undefined; click={x:310,y:20}; run(); assert.equal(visits.at(-1),'level4');
assert.equal(JSON.stringify(saved),beforeDebug,'Debug override must not change saved progress');
click=undefined; chosenKey=119; run(); assert.equal(ctx.debug_unlock_all,false);
const count=visits.length;
chosenKey=52; run(); assert.equal(visits.length,count,'Turning debug off restores locks');
console.log('Level selection checks passed: saved progression, losses, replays, final level, keyboard and mouse locks.');
