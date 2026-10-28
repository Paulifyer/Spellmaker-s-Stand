// Import the supplied PNG frames byte-for-byte; GIF references determine loop speed.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),zlib=require('node:zlib');
const root=path.join(__dirname,'..');
const parse=p=>JSON.parse(fs.readFileSync(path.join(root,p),'utf8').replace(/,\s*([}\]])/g,'$1'));
const manifest=parse('tools/asset-sources/enemy-modifiers/manifest.json');
function pngBounds(file){
 const b=fs.readFileSync(file),w=b.readUInt32BE(16),h=b.readUInt32BE(20);if(b[24]!==8||b[25]!==6)throw Error('Expected RGBA8');
 let parts=[];for(let i=8;i<b.length;){let n=b.readUInt32BE(i),type=b.toString('ascii',i+4,i+8);if(type==='IDAT')parts.push(b.subarray(i+8,i+8+n));i+=12+n;}
 const raw=zlib.inflateSync(Buffer.concat(parts)),stride=w*4;let previous=Buffer.alloc(stride),pos=0,left=w,right=0,top=h,bottom=0;
 const paeth=(a,b,c)=>{const p=a+b-c,aa=Math.abs(p-a),bb=Math.abs(p-b),cc=Math.abs(p-c);return aa<=bb&&aa<=cc?a:bb<=cc?b:c;};
 for(let y=0;y<h;y++){const filter=raw[pos++],row=Buffer.alloc(stride);for(let x=0;x<stride;x++){const a=x>=4?row[x-4]:0,b=previous[x],c=x>=4?previous[x-4]:0;row[x]=(raw[pos++]+[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)][filter])&255;}
  for(let x=0;x<w;x++)if(row[x*4+3]){left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);}previous=row;}
 return{w,h,left,right,top,bottom};
}
function gifSpeed(file){
 if(!file)return 5;const b=fs.readFileSync(file);let i=13;if(b[10]&128)i+=3*(2**((b[10]&7)+1));const delays=[];
 function skip(){let n;while((n=b[i++]))i+=n;}
 while(i<b.length){const tag=b[i++];if(tag===0x3b)break;if(tag===0x21){const label=b[i++];if(label===0xf9){const n=b[i++];delays.push(b.readUInt16LE(i+1));i+=n+1;}else skip();}
  else if(tag===0x2c){const flags=b[i+8];i+=9;if(flags&128)i+=3*(2**((flags&7)+1));i++;skip();}else throw Error('Invalid GIF');}
 const positive=delays.filter(v=>v>0);return positive.length?100/(positive.reduce((a,b)=>a+b,0)/positive.length):5;
}
const proto=parse('sprites/spr_enemy_mook/spr_enemy_mook.yy'),project=parse('Spell.yyp');
const specs=[];
for(const element of ['fire','frost','lightning'])for(const variant of ['narrow','wide']){
 const group=element[0].toUpperCase()+element.slice(1)+' '+variant[0].toUpperCase()+variant.slice(1);
 const assets=manifest.filter(a=>a.group===group);const pngs=assets.filter(a=>a.name.endsWith('.png')).sort((a,b)=>a.name.localeCompare(b.name,undefined,{numeric:true}));
 specs.push({name:'spr_ward_'+element+'_'+variant,assets:pngs,fps:gifSpeed(assets.find(a=>a.name.endsWith('.gif'))?.path&&path.join(root,assets.find(a=>a.name.endsWith('.gif')).path))});
}
specs.push({name:'spr_banneret_speed',assets:manifest.filter(a=>a.group==='Banner'),fps:1});
const summary=[];
for(const spec of specs){
 const dir=path.join(root,'sprites',spec.name);fs.mkdirSync(dir,{recursive:true});
 const prior=fs.existsSync(path.join(dir,spec.name+'.yy'))?parse('sprites/'+spec.name+'/'+spec.name+'.yy'):null;
 const s=structuredClone(proto),layerId=prior?.layers[0].name||crypto.randomUUID();s.name=spec.name;s['%Name']=spec.name;s.parent={name:'Sprites',path:'folders/Sprites.yy'};
 s.frames=[];s.layers[0].name=layerId;s.layers[0]['%Name']=layerId;s.origin=9;s.bboxMode=2;
 const frames=[];const bounds=pngBounds(path.join(root,spec.assets[0].path));
 Object.assign(s,{width:bounds.w,height:bounds.h,bbox_left:bounds.left,bbox_right:bounds.right,bbox_top:bounds.top,bbox_bottom:bounds.bottom});
 for(const [i,a]of spec.assets.entries()){
  const frame=prior?.frames[i]?.name||crypto.randomUUID(),sub=path.join(dir,'layers',frame);fs.mkdirSync(sub,{recursive:true});
  fs.copyFileSync(path.join(root,a.path),path.join(dir,frame+'.png'));fs.copyFileSync(path.join(root,a.path),path.join(sub,layerId+'.png'));
  s.frames.push({'$GMSpriteFrame':'v1','%Name':frame,name:frame,resourceType:'GMSpriteFrame',resourceVersion:'2.0'});
  frames.push({'$Keyframe<SpriteFrameKeyframe>':'',Channels:{'0':{'$SpriteFrameKeyframe':'',Id:{name:frame,path:'sprites/'+spec.name+'/'+spec.name+'.yy'},resourceType:'SpriteFrameKeyframe',resourceVersion:'2.0'}},Disabled:false,id:crypto.randomUUID(),IsCreationKey:false,Key:i,Length:1,resourceType:'Keyframe<SpriteFrameKeyframe>',resourceVersion:'2.0',Stretch:false});
 }
 const seq=s.sequence;seq.name=spec.name;seq['%Name']=spec.name;seq.length=spec.assets.length;seq.playbackSpeed=spec.fps;
 // GameMaker's sprite schema requires integer origins, even for half-pixel bounds centres.
 seq.xorigin=Math.round((bounds.left+bounds.right)/2);seq.yorigin=Math.round((bounds.top+bounds.bottom)/2);
 seq.tracks[0].keyframes.Keyframes=frames;
 fs.writeFileSync(path.join(dir,spec.name+'.yy'),JSON.stringify(s,null,2)+'\n');
 if(!project.resources.some(r=>r.id.name===spec.name))project.resources.push({id:{name:spec.name,path:'sprites/'+spec.name+'/'+spec.name+'.yy'}});
 summary.push({name:spec.name,frames:spec.assets.length,fps:spec.fps,bounds});
}
// Preserve project formatting and existing order; insert only missing resources.
let source=fs.readFileSync(path.join(root,'Spell.yyp'),'utf8');
for(const spec of specs)if(!source.includes('"name":"'+spec.name+'"'))source=source.replace('  "resources":[','  "resources":[\n    {"id":{"name":"'+spec.name+'","path":"sprites/'+spec.name+'/'+spec.name+'.yy",},},');
fs.writeFileSync(path.join(root,'Spell.yyp'),source);
fs.writeFileSync(path.join(root,'tools/asset-sources/enemy-modifiers/imported.json'),JSON.stringify(summary,null,2)+'\n');
console.log(summary.map(s=>s.name+': '+s.frames+' frames, '+s.fps.toFixed(2)+' fps').join('\n'));
