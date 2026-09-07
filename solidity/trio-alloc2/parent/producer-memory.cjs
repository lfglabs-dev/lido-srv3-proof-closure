#!/usr/bin/env node
const fs=require('node:fs'), path=require('node:path'), cp=require('node:child_process');
const crypto=require('node:crypto'), assert=require('node:assert/strict');
const solc=require('solc'), ganache=require('ganache'), {ethers}=require('ethers');
const root=path.resolve(__dirname,'../../..');
const pin='17005714f151e5502c559932319a3f2f74ac2436';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
assert.ok(process.argv[2],'successful composition receipt required');
const modelReceiptPath = path.resolve(process.argv[2]);
const modelReceipt = JSON.parse(fs.readFileSync(modelReceiptPath));
assert.equal(modelReceipt.state, 'succeeded');
assert.equal(modelReceipt.exit_code, 0);
assert.equal(modelReceipt.validation.toolchain, 'leanprover/lean4:v4.31.0');
const identity = JSON.parse(fs.readFileSync(path.join(root,'audit/trio/alloc2/composition/source-identity.json')));
for(const source of ['audit/trio/alloc2/composition/Parent.lean','audit/trio/alloc2/composition/ParentVectors.lean',
  'LidoSRv3/Audit/Source/TrioAlloc2/ParentConversion.lean']) assert.ok(Object.hasOwn(identity.files,source));
assert.match(identity.producer,/^[0-9a-f]{40}$/);
let manifest='sandboxed-source-bundle-v1\n';
for(const source of Object.keys(identity.files).sort()) {
  assert.match(source,/^(LidoSRv3\/Audit\/Source\/TrioAlloc[12]\/[^/]+\.lean|audit\/trio\/alloc2\/composition\/[^/]+\.lean)$/);
  const data=source.startsWith('LidoSRv3/Audit/Source/TrioAlloc1/')
    ? cp.execFileSync('git',['-C',root,'show',`${identity.producer}:${source}`]) : fs.readFileSync(path.join(root,source));
  assert.equal(sha(data),identity.files[source],'stale model source: '+source);
  manifest+=`${source}\0${identity.files[source]}\n`;
}
assert.ok(new RegExp(`^source bundle verified sha256=${sha(manifest)}(?: operations_sha256=[0-9a-f]{64})? files=${Object.keys(identity.files).length} `, 'm').test(modelReceipt.log_tail),
  'model source manifest differs from remote verified overlay');
const vectors=modelReceipt.log_tail.split('\n').map(line=>line.match(/(?:^|: )ALLOC2_PRODUCER_MEMORY_VECTOR (.+)$/))
  .filter(Boolean).map(m=>JSON.parse(m[1]));
assert.equal(vectors.length,6);assert.equal(new Set(vectors.map(v=>v.name)).size,6);
assert.match(solc.version(),/^0\.8\.25\+/);
const sources={};
function imports(name){try{
  const data=fs.readFileSync(name.startsWith('@')?require.resolve(name):path.join(root,'lido-core',name));
  if(!name.startsWith('@'))assert.deepEqual(data,cp.execFileSync('git',['-C',path.join(root,'lido-core'),'show',pin+':'+name]));
  sources[name]=sha(data);return {contents:data.toString()};
}catch(e){return {error:e.message};}}
const settings={optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'shanghai',outputSelection:{'*':{'*':['abi','evm.bytecode','irOptimized']}}};
const harness=fs.readFileSync(path.join(__dirname,'Harness.sol'),'utf8');
const compiled=JSON.parse(solc.compile(JSON.stringify({language:'Solidity',sources:{'Harness.sol':{content:harness}},settings}),{import:imports}));
assert.deepEqual((compiled.errors||[]).filter(e=>e.severity==='error'),[]);
fs.writeFileSync(path.join(root,'../output/alloc2-capacity-harness.yul'),compiled.contracts['Harness.sol'].ParentHarness.irOptimized);
const coder=ethers.AbiCoder.defaultAbiCoder(), words=(...v)=>coder.encode(v.map(()=> 'uint256'),v);
const cases=[
 {name:'one-row',count:1,wc:1,status:0,pointer:1536},
 {name:'two-rows',count:2,wc:1,status:0,pointer:2496},
 {name:'type-two',count:1,wc:2,status:0,pointer:1696},
 {name:'short-summary',count:1,wc:1,status:0,pointer:1408,summary:'0xdead'},
 {name:'rejected-summary',count:1,wc:1,status:0,pointer:1376,summary:'0xdead',reject:true},
 {name:'invalid-status',count:1,wc:1,status:3,pointer:1248}
];
async function main(){
 const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai'},wallet:{deterministic:true},miner:{blockGasLimit:100000000}});
 const provider=new ethers.BrowserProvider(rpc);provider.pollingInterval=10;
 const rows=[],linkedHashes={},deployed=new Map();
 try{
  const signer=await provider.getSigner();
  async function deploy(file,name){
   const key=file+':'+name;if(deployed.has(key))return deployed.get(key);
   const a=compiled.contracts[file][name];let code=a.evm.bytecode.object;
   for(const [lf,names] of Object.entries(a.evm.bytecode.linkReferences))for(const [ln,refs] of Object.entries(names)){
    const lib=await deploy(lf,ln);for(const {start,length} of refs){assert.equal(length,20);code=code.slice(0,2*start)+lib.target.slice(2).toLowerCase()+code.slice(2*(start+length));}
   }
   linkedHashes[key]=sha(code);const c=await new ethers.ContractFactory(a.abi,code,signer).deploy({gasLimit:90000000});
   await c.waitForDeployment();deployed.set(key,c);return c;
  }
  const target=await deploy('Harness.sol','ParentHarness'),modules=[];
  for(let i=0;i<2;i++){
   const a=compiled.contracts['Harness.sol'].RawModule,c=await new ethers.ContractFactory(a.abi,a.evm.bytecode.object,signer).deploy();
   await c.waitForDeployment();modules.push(c);
  }
  const base=await target.routerSlot(),countSlot=base+1n,idsStart=BigInt(ethers.keccak256(words(countSlot))),ids=[7n,9n];
  const slots=ids.map(id=>BigInt(ethers.keccak256(words(id,base))));
  const write=async(s,v)=>{await(await target.writeSlot(s,v)).wait();};
  for(let i=0;i<2;i++)await write(idsStart+BigInt(i),ids[i]);
  for(const test of cases){
   const c={summary:words(0,1,1),stake:words(64),reject:false,...test},model=vectors.find(v=>v.name===c.name);
   assert.ok(model);for(const k of ['count','wc','status','summary','stake','reject'])assert.equal(model[k],c[k],c.name+' input '+k);
   assert.equal(model.pointer,String(c.pointer),c.name+' inspected extent');
   await write(countSlot,c.count);
   for(let i=0;i<2;i++){
    await write(slots[i],BigInt(modules[i].target)+(10000n<<192n)+(BigInt(i===0?c.status:0)<<224n)+(BigInt(i===0?c.wc:1)<<232n));
    await write(slots[i]+2n,0);await(await modules[i].configure(c.summary,c.stake,c.reject,false)).wait();
   }
   const data=target.interface.encodeFunctionData('capacity',[[32,2048],10,false]);let actual,reverted=false;
   try{actual=await rpc.request({method:'eth_call',params:[{to:target.target,data,gas:'0x989680'},'latest']});}
   catch(e){reverted=true;actual=typeof e.data==='string'?e.data:e.data?.result;if(typeof actual!=='string')throw e;}
   const tx=await signer.sendTransaction({to:target.target,data,gasLimit:10000000});try{await tx.wait();}catch(e){if(e.code!=='CALL_EXCEPTION')throw e;}
   const trace=await rpc.request({method:'debug_traceTransaction',params:[tx.hash,{}]});
   const receipt=await rpc.request({method:'eth_getTransactionReceipt',params:[tx.hash]});
   const exit=trace.structLogs.filter(x=>x.depth===1&&(x.op==='RETURN'||x.op==='REVERT')).at(-1);assert.ok(exit);
   const pointer=BigInt('0x'+exit.memory[2]).toString();
   const calls=trace.structLogs.filter(x=>x.op==='STATICCALL').map(x=>{
    const target='0x'+x.stack.at(-2).slice(-40),offset=Number(BigInt('0x'+x.stack.at(-3))),len=Number(BigInt('0x'+x.stack.at(-4)));
    return modules.findIndex(m=>m.target.toLowerCase()===target.toLowerCase())+':'+x.memory.join('').slice(offset*2,(offset+len)*2);
   });
   const pointerWrites=trace.structLogs.filter(x=>x.depth===1&&x.op==='MSTORE'&&BigInt('0x'+x.stack.at(-1))===64n).map(x=>BigInt('0x'+x.stack.at(-2)).toString());
   rows.push({name:c.name,actual,reverted,pointer,calls,pointerWrites});
   fs.writeFileSync(path.join(root,'audit/trio/alloc2/producer-memory-observation.json'),JSON.stringify({scope:'diagnostic observations; not a successful validation receipt',rows},null,2)+'\n');
   assert.equal(actual.toLowerCase(),model.actual.toLowerCase(),c.name+' exact outcome bytes');
   assert.equal(reverted,model.reverted,c.name+' outcome kind');assert.equal(pointer,model.pointer,c.name+' free-memory pointer');
   assert.deepEqual(calls,model.calls,c.name+' call sequence');assert.equal(BigInt(receipt.status),reverted?0n:1n);
   assert.equal(receipt.logs.length,0);assert.equal(trace.structLogs.filter(x=>x.op==='SSTORE').length,0);
   console.log('PASS producer memory '+c.name+' pointer='+pointer);
  }
  fs.writeFileSync(path.join(root,'audit/trio/alloc2/producer-memory-execution.json'),JSON.stringify({
   scope:'compiled capacity helper vs interleaved producer allocation guards: exact bytes, call order and final free pointer; finite tests, not full byte-memory/compiler refinement',
   pin,compiler:solc.version(),settings,sources,linkedHashes,model:{job:modelReceipt.job_id,producer:identity.producer,overlay:sha(manifest),receiptSha256:sha(fs.readFileSync(modelReceiptPath))},
   harnessSha256:sha(harness),runnerSha256:sha(fs.readFileSync(__filename)),lockSha256:sha(fs.readFileSync(path.join(__dirname,'package-lock.json'))),rows},null,2)+'\n');
 }finally{provider.destroy();await rpc.disconnect();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
