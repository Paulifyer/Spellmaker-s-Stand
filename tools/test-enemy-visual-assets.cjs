const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const {read}=require('./gml-test-utils.cjs');
const manifest=JSON.parse(read('tools/asset-sources/enemy-modifiers/manifest.json'));
const summary=JSON.parse(read('tools/asset-sources/enemy-modifiers/imported.json'));
const root=path.join(__dirname,'..');const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
for(const s of summary){const dir='sprites/'+s.name;const asset=JSON.parse(read(dir+'/'+s.name+'.yy').replace(/,\s*([}\]])/g,'$1'));
 assert.equal(asset.frames.length,s.frames);assert.equal(asset.sequence.length,s.frames);assert.equal(asset.sequence.playbackSpeed,s.fps);
 for(const axis of ['xorigin','yorigin']) {
  assert.ok(Number.isInteger(asset.sequence[axis]),s.name+': '+axis+' must be an integer for GameMaker');
 }
 const sources=manifest.filter(a=>s.name==='spr_banneret_speed'?a.group==='Banner':s.name==='spr_ward_'+a.group.toLowerCase().replace(' ','_')).filter(a=>a.name.endsWith('.png')).sort((a,b)=>a.name.localeCompare(b.name,undefined,{numeric:true}));
 assert.equal(sources.length,s.frames);
 for(let i=0;i<s.frames;i++){const frame=asset.frames[i].name;assert.equal(hash(dir+'/'+frame+'.png'),hash(sources[i].path));assert.equal(hash(dir+'/layers/'+frame+'/'+asset.layers[0].name+'.png'),hash(sources[i].path));}
}
assert.equal(summary.length,7);console.log('Enemy visual asset checks passed: six ward animations, banner, source hashes, frame order and playback metadata.');
