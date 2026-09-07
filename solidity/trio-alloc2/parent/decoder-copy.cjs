const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {createHash}=require('node:crypto'),{execFileSync}=require('node:child_process');
const solc=require('solc'),ganache=require('ganache');
const {AbiCoder,BrowserProvider,ContractFactory,Interface}=require('ethers');
const root=path.resolve(__dirname,'../../..'),sha=x=>createHash('sha256').update(x).digest('hex');
assert.ok(process.argv[2],'successful exact-source receipt required');
const receiptPath=path.resolve(process.argv[2]),receipt=JSON.parse(fs.readFileSync(receiptPath));
assert.equal(receipt.state,'succeeded');assert.equal(receipt.exit_code,0);
assert.equal(receipt.validation.toolchain,'leanprover/lean4:v4.31.0');
assert.deepEqual(receipt.validation.command,['lake','build','audit.trio.alloc2.runtime.ByteWordCopyVectors']);
const identity=JSON.parse(fs.readFileSync(path.join(root,'audit/trio/alloc2/byte-abi/source-identity.json')));
assert.equal(identity.verity,'e977aaad6e1a9e92e0132d41b3d33a14135a4d46');
let manifest='sandboxed-source-bundle-v1\n';
for(const p of Object.keys(identity.files).sort()){
 assert.match(p,/^(LidoSRv3\/Audit\/Source\/TrioAlloc[12]\/[^/]+\.lean|audit\/trio\/alloc2\/(composition|runtime|byte-memory|byte-runtime|byte-abi)\/([^/]+\.lean|lake-manifest\.json))$/);
 const bytes=p.includes('/TrioAlloc1/')?execFileSync('git',['-C',root,'show',`${identity.producer}:${p}`]):fs.readFileSync(path.join(root,p));
 assert.equal(sha(bytes),identity.files[p],'stale source '+p);manifest+=`${p}\0${sha(bytes)}\n`;
}
const verified=receipt.log_tail.match(/^source bundle verified sha256=([a-f0-9]{64})(?: operations_sha256=[a-f0-9]{64})? files=(\d+) /m);
assert.ok(verified);assert.equal(verified[1],sha(manifest));assert.equal(+verified[2],Object.keys(identity.files).length);
const vectors=receipt.log_tail.split('\n').map(s=>s.match(/(?:^|: )ALLOC2_WORD_COPY (.+)$/)).filter(Boolean).map(m=>JSON.parse(m[1]));
assert.equal(vectors.length,6);assert.equal(new Set(vectors.map(v=>v.name)).size,6);
assert.ok(identity.files['audit/trio/alloc2/runtime/ByteWordCopyVectors.lean'],'vectors must be source-bound');
for(const v of vectors){
 const bytes=Buffer.from(v.input.slice(2),'hex');
 assert.equal(v.original,v.input,v.name+' Lean source preservation');
 assert.equal(v.copied,'0x'+bytes.subarray(v.offset,v.offset+32*v.count).toString('hex'),v.name+' independent byte slice');
}
const mutant=process.env.ALLOC2_WORD_COPY_MUTANT||'';assert.ok(mutant===''||mutant==='stride');
let source=fs.readFileSync(path.join(__dirname,'DecoderCopy.sol'),'utf8');
if(mutant){const needle='dst := add(dst, 32)';assert.equal(source.split(needle).length,2);source=source.replace(needle,'dst := add(dst, 31)');}
assert.match(solc.version(),/^0\.8\.25\+commit\.b61c2a91\./);
const settings={optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'shanghai',outputSelection:{'*':{'*':['abi','evm.bytecode','evm.deployedBytecode','irOptimized']}}};
const input={language:'Solidity',sources:{'DecoderCopy.sol':{content:source}},settings};
const compiled=JSON.parse(solc.compile(JSON.stringify(input)));
assert.deepEqual((compiled.errors||[]).filter(e=>e.severity==='error'),[]);
const artifact=compiled.contracts['DecoderCopy.sol'].DecoderCopy;
(async()=>{
 const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai'},wallet:{deterministic:true}});
 const provider=new BrowserProvider(rpc);provider.pollingInterval=10;
 const results=[],coder=AbiCoder.defaultAbiCoder();
 try{
  const contract=await new ContractFactory(artifact.abi,artifact.evm.bytecode.object,await provider.getSigner()).deploy();await contract.waitForDeployment();
  const iface=new Interface(artifact.abi);
  for(const v of vectors){
   const calldata=iface.encodeFunctionData('copy',[v.input,v.offset,v.count]);
   const actual=await rpc.request({method:'eth_call',params:[{to:contract.target,data:calldata},'latest']});
   const expected=coder.encode(['bytes','bytes'],[v.original,v.copied]);
   assert.equal(actual.toLowerCase(),expected.toLowerCase(),v.name+' original and copied exact bytes');
   results.push({name:v.name,calldata,returndata:actual});console.log('PASS '+v.name);
  }
  assert.equal(mutant,'','mutant survived');
  fs.writeFileSync(path.join(root,'audit/trio/alloc2/word-copy-execution.json'),JSON.stringify({scope:'Emitted decoder word-copy loop isolated over fresh memory; original and copied bytes; full compiler guard/entry refinement remains required',compiler:solc.version(),settings,runnerSha256:sha(fs.readFileSync(__filename)),lockSha256:sha(fs.readFileSync(path.join(__dirname,'package-lock.json'))),receipt:{job:receipt.job_id,sha256:sha(fs.readFileSync(receiptPath)),sourceOverlay:verified[1]},compilerInput:input,compilerOutput:compiled,deployedHarness:await provider.getCode(contract.target),results},null,2)+'\n');
 }finally{provider.destroy();await rpc.disconnect();}
})().catch(e=>{console.error(e);process.exitCode=1;});
