// Preserve the artist's PNG bytes; clone the existing centered glyph resource format.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.join(__dirname,'..');
const parse=file=>JSON.parse(fs.readFileSync(path.join(root,file),'utf8').replace(/,\s*([}\]])/g,'$1'));
const manifest=parse(process.argv[2]??'tools/asset-sources/payoff-glyphs/manifest.json');
const prototype=parse('sprites/spr_glyph_fire/spr_glyph_fire.yy');
let project=fs.readFileSync(path.join(root,'Spell.yyp'),'utf8');
const resources=JSON.parse(project.replace(/,\s*([}\]])/g,'$1')).resources;
for(const item of manifest) {
    const png=fs.readFileSync(path.join(root,item.path));
    if(png.toString('hex',0,8)!=='89504e470d0a1a0a'||png.readUInt32BE(16)!==264||png.readUInt32BE(20)!==264||png[24]!==8||png[25]!==6)
        throw Error(item.name+': expected a 264x264 RGBA8 PNG');
    const dir=path.join(root,'sprites',item.name),target='sprites/'+item.name+'/'+item.name+'.yy';
    const prior=fs.existsSync(path.join(root,target))?parse(target):undefined;
    const frame=prior?.frames[0].name??crypto.randomUUID();
    const layer=prior?.layers[0].name??crypto.randomUUID();
    const key=prior?.sequence.tracks[0].keyframes.Keyframes[0].id??crypto.randomUUID();
    let source=JSON.stringify(prototype);
    for(const [from,to]of [[prototype.name,item.name],[prototype.frames[0].name,frame],[prototype.layers[0].name,layer],[prototype.sequence.tracks[0].keyframes.Keyframes[0].id,key]])source=source.split(from).join(to);
    const sprite=JSON.parse(source);
    sprite.bboxMode=0;sprite.bbox_left=0;sprite.bbox_top=0;sprite.bbox_right=263;sprite.bbox_bottom=263;
    sprite.origin=4;sprite.sequence.xorigin=132;sprite.sequence.yorigin=132;
    fs.mkdirSync(path.join(dir,'layers',frame),{recursive:true});
    fs.writeFileSync(path.join(dir,frame+'.png'),png);
    fs.writeFileSync(path.join(dir,'layers',frame,layer+'.png'),png);
    fs.writeFileSync(path.join(root,target),JSON.stringify(sprite,null,2)+'\n');
    if(!resources.some(r=>r.id.name===item.name))project=project.replace(/("resources"\s*:\s*\[)/,(_,head)=>head+'\n    '+JSON.stringify({id:{name:item.name,path:target}})+',');
    console.log(item.name+': 264x264, one frame, centered integer origin');
}
fs.writeFileSync(path.join(root,'Spell.yyp'),project);
