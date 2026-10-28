const assert = require('node:assert/strict');
const vm = require('node:vm');
const {read} = require('./gml-test-utils.cjs');
const {makeContext} = require('./construction-test-context.cjs');
const ctx = makeContext(8);
const valid = () => ({form:'projectile',form_mods:[],effects:[{effect:'harm',mods:[]}]});
const formOnly = {form:'projectile',form_mods:[],effects:[]};
ctx.global.spellbook=[undefined,{name:'unused'},formOnly];
assert.match(ctx.spellbook_start_message(100),/Spell 3: Add an Effect/);
ctx.global.spellbook=[valid(),valid(),valid()];
assert.equal(ctx.spellbook_start_message(100),'');
ctx.global.spellbook[2].form_mods=['pierce'];
ctx.global.spellbook[2].form='strike';
assert.match(ctx.spellbook_start_message(100),/Spell 3: Modifier is incompatible/);
ctx.global.spellbook[2]=valid();
ctx.global.spellbook[2].effects[0].mods=Array(7).fill('amplify');
assert.match(ctx.spellbook_start_message(100),/Too many glyphs/);
ctx.global.spellbook[2]=valid();
assert.match(ctx.spellbook_start_message(10),/Spell 3: Spell is too expensive/);

// Draw the real editor with engine/UI calls stubbed; inspect counters and group positions.
const texts=[], groups=[], palette=[];
const noop=()=>{};
const circle=(x,y,r)=>{if(r===55)palette.push({x,y});return {clicked:false,rclicked:false,hover:false};};
Object.assign(ctx, {
    SPELL_SLOTS:4,
    mutation_description:()=>undefined,
    sel:0,active_group:-1,close_requested:false,naming:false,notice:'',notice_timer:0,
    craft_cx:1142,craft_cy:495,enemies_in_level:[],enemy_view:0,
    column_keys:['form','effect','modifier'],glyph_row_y:[265,490,835],
    GLYPH_STATE:{owned:2,locked:1,disabled:0}, glyph_status:()=>2,
    mouse_x:0,mouse_y:0,device_mouse_x_to_gui:()=>0,device_mouse_y_to_gui:()=>0,
    c_black:0,c_red:1,c_white:2,c_aqua:3,Player:1,spr_spell_crafting_gui:1,fnt_Arcane:1,
    instance_find:()=>({max_mana:100}),instance_exists:()=>true,
    draw_sprite:noop,draw_sprite_ext:noop,draw_set_color:noop,draw_set_colour:noop,
    draw_rectangle:noop,draw_set_alpha:noop,draw_set_font:noop,draw_circle:noop,draw_set_halign:noop,draw_set_valign:noop,
    draw_text:(x,y,t)=>texts.push(t),draw_text_ext:noop,
    gui_circle_button:circle, gui_button:()=>false,
    draw_glyph_group:(x,y)=>{groups.push({x,y});return{main:circle(),mod_r:-1,hover:''};},
    spell_prune:i=>ctx.global.spellbook[i],
    max:Math.max,min:Math.min,floor:Math.floor,string_copy:(s,a,n)=>s.slice(a-1,a-1+n),
    lengthdir_x:(r,a)=>r*Math.cos(a*Math.PI/180),lengthdir_y:(r,a)=>-r*Math.sin(a*Math.PI/180),
    mouse_check_button_pressed:()=>false,point_in_rectangle:()=>false,mb_left:1,
    fa_center:1,fa_middle:2,fa_left:3,fa_top:4,current_time:0,
});
ctx.global.glyph_order={form:['projectile','strike','beam','rune'],effect:['harm','fire','ice','lightning','hex','pull','snap','combust','discharge'],modifier:['pierce','area','amplify','extend_time','delay']};
const draw=read('objects/obj_spellbook/Draw_64.gml')
    .replace(/#([0-9A-Fa-f]{6})/g,'0x$1')
    .replace(/\[\$\s*([^\]]+)\]/g,'[$1]').replace(/\bmod\b/g,'%')
    .replace('g div _per_row','Math.floor(g / _per_row)').replace('current_time div 500','Math.floor(current_time / 500)');
ctx.global.spellbook=[{name:'seven effects',form:'projectile',form_mods:[],effects:[
    {effect:'harm',mods:[]},{effect:'fire',mods:[]},{effect:'ice',mods:[]},
    {effect:'lightning',mods:[]},{effect:'hex',mods:[]},{effect:'pull',mods:[]},{effect:'harm',mods:[]}
]},undefined,undefined,undefined];
vm.runInContext(draw,ctx);
assert.ok(texts.includes('Glyphs: 8 / 8'));
assert.equal(groups.length,8); // central Form plus seven Effects, including invalid repeats for repair
assert.ok(groups.every(p=>Number.isFinite(p.x)&&Number.isFinite(p.y)));
assert.equal(new Set(groups.map(p=>`${p.x},${p.y}`)).size,8);
assert.ok(palette.some(p=>p.x===140&&p.y===710)); // ninth Effect fits above the Modifier palette
console.log('Spell editor checks passed: all-slot Start validation, empty slots, counter and seven visible effect groups.');

// A retained high-slot selection is reset before Draw or keyboard naming can edit it.
const retained={name:'Retained fourth',form:'projectile',form_mods:[],effects:[{effect:'harm',mods:[]}]};
ctx.global.spellbook=[valid(),undefined,undefined,retained];
ctx.global.level_config.rm_test.spell_slots=2;
ctx.global.level_array=['rm_test'];
ctx.sel=3;ctx.naming=true;
const buttons=[];
ctx.gui_circle_button=(x,y,r,icon,label,active,enabled=true)=>{
    if(y===990)buttons.push({x,label,enabled});
    return {hover:y===990&&label==='4',clicked:y===990&&label==='4'&&enabled,rclicked:false};
};
vm.runInContext(draw,ctx);
assert.equal(ctx.sel,0);assert.equal(ctx.naming,false);
assert.deepEqual(buttons.map(b=>b.enabled),[true,true,false,false]);
assert.equal(new Set(buttons.map(b=>b.x)).size,4);
assert.ok(texts.includes('Locked'));assert.equal(ctx.hover_text,'Slot locked');
ctx.sel=3;ctx.naming=true;ctx.keyboard_string='Must not overwrite';
vm.runInContext(read('objects/obj_spellbook/Step_0.gml'),ctx);
assert.equal(ctx.sel,0);assert.equal(ctx.naming,false);assert.equal(retained.name,'Retained fourth');
console.log('Spell editor slot checks passed: four distinct buttons, disabled locked slots, stale selection reset and retained naming protection.');
