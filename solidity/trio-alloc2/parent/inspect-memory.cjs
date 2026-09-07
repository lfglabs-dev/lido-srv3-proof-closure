#!/usr/bin/env node
// Inspect exact compiler-generated memory operations; this is evidence, not a proof.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const crypto=require('node:crypto'),assert=require('node:assert/strict'),solc=require('solc');
const root=path.resolve(__dirname,'../../..');
const pin='17005714f151e5502c559932319a3f2f74ac2436';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
assert.match(solc.version(),/^0\.8\.25\+/);
const hashes={};
function imports(name) {
  try {
    const file=name.startsWith('@')?require.resolve(name):path.join(root,'lido-core',name);
    const data=fs.readFileSync(file);
    if(!name.startsWith('@')) assert.deepEqual(data,cp.execFileSync('git',['-C',path.join(root,'lido-core'),'show',`${pin}:${name}`]));
    hashes[name]=sha(data);return {contents:data.toString()};
  } catch(e) {return {error:e.message};}
}
const entry='contracts/0.8.25/sr/SRLib.sol';
const source=imports(entry);assert.ok(source.contents);
const settings={optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'shanghai',outputSelection:{'*':{'*':['irOptimized']}}};
const input=JSON.stringify({language:'Solidity',sources:{[entry]:{content:source.contents}},settings});
const result=JSON.parse(solc.compile(input,{import:imports}));
assert.deepEqual((result.errors||[]).filter(e=>e.severity==='error'),[]);
const ir=result.contracts[entry].SRLib.irOptimized;
const output=path.join(root,'../output/alloc2-parent-memory.yul');fs.writeFileSync(output,ir);
const lines=ir.split('\n');
const selected=[];
for(let i=0;i<lines.length;i++) if(/function (allocate_memory|finalize_allocation|array_allocation_size)|0xffffffffffffffff/.test(lines[i]))
  selected.push({line:i+1,excerpt:lines.slice(i,Math.min(i+18,lines.length)).join('\n')});
const record={pin,compiler:solc.version(),settings,compilerInputSha256:sha(input),sourceHashes:hashes,
  packageLockSha256:sha(fs.readFileSync(path.join(__dirname,'package-lock.json'))),
  runnerSha256:sha(fs.readFileSync(__filename)),irSha256:sha(ir),selected};
fs.writeFileSync(path.join(root,'audit/trio/alloc2/parent-memory-inspection.json'),JSON.stringify(record,null,2)+'\n');
console.log(`Generated exact optimized SRLib IR (${lines.length} lines); retained ${selected.length} memory/size excerpts`);
