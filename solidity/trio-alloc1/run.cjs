#!/usr/bin/env node
// Pinned Solidity execution receipts. Set NODE_PATH to the private dependency install.
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const solc = require('./compiler-receipt.cjs')(require('solc'));
const ganache = require('./evm-backend.cjs');
const { ethers } = require('ethers');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const out = process.argv[2];
const modelFile = process.argv[3];
const model = modelFile ? JSON.parse(fs.readFileSync(modelFile, "utf8")) : null;
if (!out) throw new Error('usage: node run.cjs OUTPUT_DIRECTORY');
fs.mkdirSync(out, {recursive:true});
const pin = cp.execFileSync('git', ['-C',path.join(root,'lido-core'),'rev-parse','HEAD'],{encoding:'utf8'}).trim();
assert.equal(pin,'17005714f151e5502c559932319a3f2f74ac2436');
assert.match(solc.version(),/^0\.8\.25\+/);
const settings = {optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:process.env.ALLOC1_EVM || 'shanghai',
 outputSelection:{'*':{'*':['abi','evm.bytecode.object','storageLayout','irOptimized']}}};
const input = {language:'Solidity',sources:{'Harness.sol':{content:fs.readFileSync(path.join(__dirname,'Harness.sol'),'utf8')}},settings};
const sources = {};
const mutant = process.argv[4] || null;
if (mutant && !['target-only','stake-before-subtraction'].includes(mutant)) throw new Error('unknown mutant');
function imports(name) {
 const filename = name.startsWith('@') ? require.resolve(name) : path.join(root,'lido-core',name);
 try {
   let contents = fs.readFileSync(filename,'utf8');
   if (name === 'contracts/0.8.25/sr/SRLib.sol' && mutant) {
     if (mutant === 'target-only') {
       const needle = 'validatorsCapacity = Math.min(targetValidators, validatorsCapacity);';
       assert.equal(contents.split(needle).length,2,'unique capacity mutation site');
       contents = contents.replace(needle,'validatorsCapacity = targetValidators;');
     } else {
       const needle = 'cache[i].depositableCount = depositableValidatorsCount;';
       assert.equal(contents.split(needle).length,2,'unique prefetch mutation site');
       const call = 'moduleId.getIStakingModuleV2().getTotalModuleStake()';
       const replacement = needle + '\nuint256 prefetchedStake; if (WithdrawalCredentials.isType2(stateConfig.withdrawalCredentialsType)) { prefetchedStake = ' + call + '; }';
       contents = contents.replace('Math.ceilDiv('+call+', maxEBType1)', 'Math.ceilDiv(prefetchedStake, maxEBType1)').replace(needle,replacement);
     }
   }
   sources[name]=crypto.createHash('sha256').update(contents).digest('hex');
   return {contents};
 }
 catch (e) { return {error:e.message}; }
}
const compilation = JSON.parse(solc.compile(JSON.stringify(input),{import:imports}));
const errors = (compilation.errors||[]).filter(x=>x.severity==='error');
if(errors.length) throw new Error(errors.map(x=>x.formattedMessage).join('\n'));
const contracts = compilation.contracts['Harness.sol'];
fs.writeFileSync(path.join(out,'harness.ir'),contracts.CapacityHarness.irOptimized);
fs.writeFileSync(path.join(out,'compiler.json'),JSON.stringify({compiler:solc.version(),pin,mutant,settings,sources},null,2));
const coder = ethers.AbiCoder.defaultAbiCoder();
const words=(...xs)=>coder.encode(xs.map(()=> 'uint256'),xs);
const max=(1n<<256n)-1n;
const panic=n=>'0x4e487b71'+words(n).slice(2);
async function main() {
 const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai'},wallet:{deterministic:true}});
 try {
 const provider=new ethers.BrowserProvider(rpc);
 provider.pollingInterval=10;
 const signer=await provider.getSigner();
 async function deploy(name) { const c=contracts[name]; const result=await new ethers.ContractFactory(c.abi,c.evm.bytecode.object,signer).deploy(); await result.waitForDeployment(); return result; }
 const harness=await deploy('CapacityHarness');
 const modules=[await deploy('RawModule'),await deploy('RawModule')];
 const base=await harness.routerSlot();
 const lengthSlot=base+1n;
 const idsStart=BigInt(ethers.keccak256(words(lengthSlot)));
 const ids=[7n,9n];
 const moduleSlots=ids.map(id=>BigInt(ethers.keccak256(words(id,base))));
 const write=async(slot,value)=>await (await harness.writeSlot(slot,value)).wait();
 for(let i=0;i<2;i++) await write(idsStart+BigInt(i),ids[i]);
 const defaults={count:1,shares:[10000,10000],status:[0,0],wc:[1,1],exited:[0,0],
  responses:[words(0,1,1),words(0,1,1)],stakes:[words(65),words(65)],rejectSummary:[false,false],
  rejectStake:[false,false],cfg:[32,2048],demand:10,topup:false};
 const cases=[
  {name:'mixed',count:2,shares:[5000,5000],status:[0,1],wc:[1,2],responses:[words(1,4,20),words(1,4,20)],expected:[[3,3],[8,3]],calls:['0:9abddf09','1:9abddf09','1:0c852f5c']},
  {name:'underflow-before-stake',wc:[2,1],responses:[words(5,4,20),words(0,1,1)],rejectStake:[true,false],expected:panic(17),calls:['0:9abddf09']},
  {name:'late-rejection',count:2,responses:[words(0,1,1),'0xdead'],rejectSummary:[false,true],expected:'0xdead',calls:['0:9abddf09','1:9abddf09']},
  {name:'short-summary',responses:['0x'+'00'.repeat(95),words(0,1,1)],expected:'0x',calls:['0:9abddf09']},
  {name:'short-stake',wc:[2,1],stakes:['0x'+'00'.repeat(31),words(0)],expected:'0x',calls:['0:9abddf09','0:0c852f5c']},
  {name:'trailing-summary',responses:[words(0,1,1)+'ff',words(0,1,1)],expected:[[1],[2]],calls:['0:9abddf09']},
  {name:'zero-ceil-divisor',wc:[2,1],cfg:[0,2048],stakes:[words(0),words(0)],expected:panic(18),calls:['0:9abddf09','0:0c852f5c']},
  {name:'invalid-enum-before-call',status:[3,0],expected:panic(33),calls:[]},
  {name:'below-allocation',shares:[0,0],expected:[[1],[0]],calls:['0:9abddf09']},
  {name:'topup-product-before-division',wc:[2,1],responses:[words(0,2,0),words(0,1,1)],stakes:[words(0),words(0)],cfg:[1,max],topup:true,expected:panic(17),calls:['0:9abddf09','0:0c852f5c']},
  {name:'empty-zero-divisor',count:0,cfg:[0,0],expected:[[],[]],calls:[]},
  {name:'total-overflow-before-next-row',count:2,demand:max,expected:panic(17),calls:['0:9abddf09']}
 ];
 if(model) assert.equal(model.length,cases.length,'complete paired vector set');
 const receipts=[];
 for(const test of cases) {
  const c={...defaults,...test};
  await write(lengthSlot,c.count);
  for(let i=0;i<2;i++) {
   const packed=BigInt(modules[i].target)+(BigInt(c.shares[i])<<192n)+(BigInt(c.status[i])<<224n)+(BigInt(c.wc[i])<<232n);
   await write(moduleSlots[i],packed);
   await write(moduleSlots[i]+2n,BigInt(c.exited[i])<<64n);
   await (await modules[i].configure(c.responses[i],c.stakes[i],c.rejectSummary[i],c.rejectStake[i])).wait();
  }
  const data=harness.interface.encodeFunctionData('capacity',[c.cfg,c.demand,c.topup]);
  async function observedState() {
    const slots=[lengthSlot,idsStart,idsStart+1n,...moduleSlots,...moduleSlots.map(x=>x+2n)];
    const storage=await Promise.all(slots.map(slot=>rpc.request({method:'eth_getStorageAt',params:[harness.target,ethers.toQuantity(slot),'latest']})));
    const balances=await Promise.all([harness.target,...modules.map(m=>m.target)].map(address=>rpc.request({method:'eth_getBalance',params:[address,'latest']})));
    return {storage,balances};
  }
  const beforeState=await observedState();
  let actual;
  try { const result=await provider.call({to:harness.target,data}); actual=harness.interface.decodeFunctionResult('capacity',result).map(a=>a.map(Number)); }
  catch(e) { if(e.code!=='CALL_EXCEPTION')throw e; actual=e.data; }
  const tx=await signer.sendTransaction({to:harness.target,data,gasLimit:10000000});
  try{await tx.wait();}catch(e){if(e.code!=='CALL_EXCEPTION')throw e;}
  const trace=await rpc.request({method:'debug_traceTransaction',params:[tx.hash,{}]});
  const txReceipt=await rpc.request({method:'eth_getTransactionReceipt',params:[tx.hash]});
  const afterState=await observedState();
  assert.deepEqual(afterState,beforeState,c.name+' view state and balances');
  assert.equal(txReceipt.logs.length,0,c.name+' no committed events');
  assert.equal(trace.structLogs.filter(x=>x.op==='SSTORE').length,0,c.name+' no storage writes');
  const calls=trace.structLogs.filter(x=>x.op==='STATICCALL').map(x=>{
    const stack=x.stack; const target=ethers.getAddress('0x'+stack.at(-2).slice(-40));
    const offset=Number(BigInt('0x'+stack.at(-3))); const length=Number(BigInt('0x'+stack.at(-4)));
    const payload=x.memory.join('').slice(offset*2,(offset+length)*2);
    const index=modules.findIndex(m=>m.target.toLowerCase()===target.toLowerCase());
    return index+':'+payload;
  });
  let memoryArrays=null;
  if (Array.isArray(actual)) {
    const returned=trace.structLogs.findLast(x=>x.depth===1 && x.op==='RETURN');
    assert(returned,c.name+' root return memory');
    const bytes=returned.memory.join('');
    const load=offset=>BigInt('0x'+bytes.slice(offset*2,(offset+32)*2));
    // Exact successful allocation schedule of the pinned via-IR harness:
    // root hash 128; arrays/cache, 160-byte cache rows, 224-byte config;
    // each first-pass row uses 704 bytes, plus 160 for a WC2 stake call.
    const allocationPointer=256;
    const wc2=c.wc.slice(0,c.count).filter(x=>x===2).length;
    const capacityPointer=544+928*c.count+160*wc2;
    const decode=ptr=>{assert.equal(load(ptr),BigInt(c.count));return Array.from({length:c.count},(_,i)=>Number(load(ptr+32*(i+1))));};
    const allocations=decode(allocationPointer),capacities=decode(capacityPointer);
    assert.deepEqual([allocations,capacities],actual,c.name+' internal memory arrays');
    assert(allocationPointer+32*(c.count+1)<=capacityPointer);
    memoryArrays={allocationPointer,capacityPointer,allocations,capacities,freePointer:load(64).toString()};
  }
  const receipt={name:c.name,actual,expected:c.expected,calls,expectedCalls:c.calls,transaction:tx.hash,beforeState,afterState,committedEvents:txReceipt.logs,storageWrites:0,memoryArrays};
  receipts.push(receipt);
  fs.writeFileSync(path.join(out,'executions.json'),JSON.stringify(receipts,null,2));
  assert.deepEqual(actual,c.expected,c.name+' outcome');
  assert.deepEqual(calls,c.calls,c.name+' calls');
  if (model) {
    const counterpart = model.find(x=>x.name===c.name);
    assert.ok(counterpart,c.name+' missing Lean execution');
    assert.deepEqual(actual,counterpart.actual,c.name+' Solidity/Lean outcome');
    assert.deepEqual(calls,counterpart.calls,c.name+' Solidity/Lean calls');
  }
  console.log('PASS '+c.name);
 }
 } finally { await rpc.disconnect(); }
}
main().catch(e=>{console.error(e);process.exitCode=1;});
