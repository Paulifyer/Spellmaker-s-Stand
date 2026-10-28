const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),zlib=require('node:zlib'),assert=require('node:assert/strict');
const root=path.join(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const parse=p=>JSON.parse(read(p).replace(/,\s*([}\]])/g,'$1'));
const manifest=parse('tools/asset-sources/payoff-glyphs/manifest.json');
const project=parse('Spell.yyp');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex');
assert.equal(manifest.length,3);
for(const item of manifest) {
    const dir='sprites/'+item.name,s=parse(dir+'/'+item.name+'.yy');
    assert.equal(project.resources.filter(r=>r.id.name===item.name&&r.id.path===dir+'/'+item.name+'.yy').length,1);
    assert.equal(s.width,264);assert.equal(s.height,264);assert.equal(s.frames.length,1);
    assert.equal(s.origin,4);assert.equal(s.sequence.xorigin,132);assert.equal(s.sequence.yorigin,132);
    assert.ok(Number.isInteger(s.sequence.xorigin)&&Number.isInteger(s.sequence.yorigin));
    assert.equal(s.parent.path,'folders/Sprites/UI/Glyphs.yy');
    const frame=s.frames[0].name,layer=s.layers[0].name;
    const ref=s.sequence.tracks[0].keyframes.Keyframes[0].Channels['0'].Id;
    assert.equal(ref.name,frame);assert.equal(ref.path,dir+'/'+item.name+'.yy');
    assert.equal(hash(dir+'/'+frame+'.png'),hash(item.path));
    assert.equal(hash(dir+'/layers/'+frame+'/'+layer+'.png'),hash(item.path));
    const png=fs.readFileSync(path.join(root,item.path));assert.equal(png[25],6);
    const idat=[];for(let i=8;i<png.length;){const n=png.readUInt32BE(i);if(png.toString('ascii',i+4,i+8)==='IDAT')idat.push(png.subarray(i+8,i+8+n));i+=n+12;}
    const raw=zlib.inflateSync(Buffer.concat(idat));let previous=Buffer.alloc(264*4),pos=0,transparent=0,opaque=0;
    const paeth=(a,b,c)=>{const p=a+b-c,da=Math.abs(p-a),db=Math.abs(p-b),dc=Math.abs(p-c);return da<=db&&da<=dc?a:db<=dc?b:c;};
    for(let y=0;y<264;y++) {
        const filter=raw[pos++],row=Buffer.alloc(264*4);
        for(let x=0;x<row.length;x++){const a=x>=4?row[x-4]:0,b=previous[x],c=x>=4?previous[x-4]:0;row[x]=(raw[pos++]+[0,a,b,Math.floor((a+b)/2),paeth(a,b,c)][filter])&255;}
        for(let x=0;x<264;x++){const alpha=row[x*4+3];if(alpha===0)transparent++;if(alpha===255)opaque++;}
        previous=row;
    }
    assert.ok(transparent>0&&opaque>0,item.name+': artwork and transparent background both present');
    const title=item.name.slice('spr_glyph_'.length);const constructor=title[0].toUpperCase()+title.slice(1);
    assert.match(read('scripts/EffectGlyphs/EffectGlyphs.gml'),new RegExp(`function Elem_${constructor}\\([^]*?icon = ${item.name};`));
}
console.log('Payoff icon checks passed: project registration, glyph bindings, frame references, integer origins, original pixel hashes and transparency.');
