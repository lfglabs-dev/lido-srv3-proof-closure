#!/usr/bin/env node
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const solc = require('solc');
const ganache = require('ganache');
const {ethers} = require('ethers');
const root = path.resolve(__dirname, '../../..');
const pin = '17005714f151e5502c559932319a3f2f74ac2436';
const {mutations, apply:applyMutation} = require('./mutations.cjs');
const mutantName = process.argv[3]?.startsWith('--mutant=') ? process.argv[3].slice(9) : null;
const mutation = mutantName ? mutations[mutantName] : null;
const frame = process.argv[3] === '--frame' || !!mutation?.frame;
assert.ok(process.argv.length <= 3 || (process.argv.length === 4 && (frame || mutation)), 'unknown runner option');
const output = path.join(root, mutantName ? `audit/trio/alloc2/parent-mutant-${mutantName}.json`
  : frame ? 'audit/trio/alloc2/parent-frame-execution.json' : 'audit/trio/alloc2/parent-execution.json');
const mutatedSources = {};
const sha = value => crypto.createHash('sha256').update(value).digest('hex');
assert.ok(process.argv[2], 'usage: node run.cjs <successful parent Lean receipt>');
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
const vectors=modelReceipt.log_tail.split('\n').map(line=>line.match(/(?:^|: )ALLOC2_PARENT_VECTOR (.+)$/))
  .filter(Boolean).map(match=>JSON.parse(match[1]));
assert.equal(vectors.length,8,'missing or truncated parent execution output');
assert.equal(new Set(vectors.map(v=>v.name)).size,8);
const memoryVectors=modelReceipt.log_tail.split('\n').map(line=>line.match(/(?:^|: )ALLOC2_MEMORY_VECTOR (.+)$/))
  .filter(Boolean).map(match=>JSON.parse(match[1]));
assert.equal(memoryVectors.length,4,'missing allocation-guard executions');
assert.equal(new Set(memoryVectors.map(v=>v.name)).size,4);
assert.match(solc.version(), /^0\.8\.25\+/);
const sources = {};
function imports(name) {
  try {
    const filename = name.startsWith('@') ? require.resolve(name) : path.join(root, 'lido-core', name);
    const data = fs.readFileSync(filename);
    if (!name.startsWith('@')) {
      assert.deepEqual(data, cp.execFileSync('git', ['-C', path.join(root, 'lido-core'), 'show', `${pin}:${name}`]), `dirty pinned source: ${name}`);
    }
    sources[name] = sha(data);
    let contents=data.toString();
    if(mutation?.source==='sr' && name==='contracts/0.8.25/sr/SRLib.sol') {
      contents=applyMutation(contents,mutation);mutatedSources[name]=sha(contents);
    }
    return {contents};
  } catch(e) {return {error:e.message};}
}
const settings = {optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'shanghai',
  outputSelection:{'*':{'*':['abi','evm.bytecode']}}};
const originalHarness = fs.readFileSync(path.join(__dirname, 'Harness.sol'), 'utf8');
const harnessSource = mutation?.source==='harness' ? applyMutation(originalHarness,mutation) : originalHarness;
if(mutation?.source==='harness')mutatedSources['Harness.sol']=sha(harnessSource);
const input = JSON.stringify({language:'Solidity',sources:{'Harness.sol':{content:harnessSource}},settings});
const compilation = JSON.parse(solc.compile(input,{import:imports}));
const errors = (compilation.errors||[]).filter(e=>e.severity==='error');
assert.deepEqual(errors, [], errors.map(e=>e.formattedMessage).join('\n'));
const coder = ethers.AbiCoder.defaultAbiCoder();
const words = (...xs) => coder.encode(xs.map(()=> 'uint256'), xs);
const panic = n => '0x4e487b71'+words(n).slice(2);
const huge = 1n<<240n, unit = 1n<<20n;
const defaults = {count:1,shares:[10000,10000],responses:[words(0,1,1),words(0,1,1)],
  rejects:[false,false],cfg:[32,2048],amount:320};
const cases = [
  {name:'normal',expected:words(32,96,160,1,32,1,64),calls:['0:9abddf09'],library:true},
  {name:'zero-demand',amount:31,expected:words(0,96,160,1,0,1,32),calls:['0:9abddf09'],library:false},
  {name:'empty-zero-divisor',count:0,cfg:[0,2048],expected:words(0,96,128,0,0),calls:[],library:false},
  {name:'division-before-producer',cfg:[0,2048],expected:panic(18),reverted:true,calls:[],library:false},
  {name:'zero-demand-overflow',cfg:[unit,2048],amount:0,responses:[words(0,huge,0),words(0,1,1)],expected:panic(17),reverted:true,calls:['0:9abddf09'],library:false},
  {name:'late-second-row-overflow',count:2,shares:[0,10000],cfg:[unit,2048],amount:unit,
    responses:[words(0,1,0),words(0,huge,1)],expected:panic(17),reverted:true,calls:['0:9abddf09','1:9abddf09'],library:true},
  {name:'zero-demand-late-rejection',count:2,amount:0,rejects:[false,true],responses:[words(0,1,1),'0xdead'],expected:'0xdead',reverted:true,calls:['0:9abddf09','1:9abddf09'],library:false},
  {name:'malformed-summary',responses:['0xdead',words(0,1,1)],expected:'0x',reverted:true,calls:['0:9abddf09'],library:false},
  ...[
    {name:'memory-max-count',count:(1n<<256n)-1n},
    {name:'memory-length-limit',count:1n<<64n},
    {name:'memory-size-limit',count:1n<<59n}
  ].map(c=>({...c,memory:true,amount:0,expected:panic(65),reverted:true,calls:[],library:false})),
  {name:'division-before-memory-limit',count:1n<<64n,cfg:[0,2048],amount:320,memory:true,
    expected:panic(18),reverted:true,calls:[],library:false}
];
async function main() {
  const rpc = ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai'},wallet:{deterministic:true},miner:{blockGasLimit:100000000}});
  const provider = new ethers.BrowserProvider(rpc); provider.pollingInterval=10;
  const receipts=[], deployed=new Map(), linkedHashes={};
  try {
    const signer=await provider.getSigner();
    const recipient=await (await provider.getSigner(1)).getAddress();
    const marker=0x123456n;
    async function deploy(file,name) {
      const key=file+':'+name;
      if(deployed.has(key)) return deployed.get(key);
      const artifact=compilation.contracts[file][name];
      let bytecode=artifact.evm.bytecode.object;
      for(const [libraryFile,names] of Object.entries(artifact.evm.bytecode.linkReferences)) {
        for(const [libraryName,refs] of Object.entries(names)) {
          const dependency=await deploy(libraryFile,libraryName);
          for(const {start,length} of refs) {
            assert.equal(length,20);
            bytecode=bytecode.slice(0,start*2)+dependency.target.slice(2).toLowerCase()+bytecode.slice((start+length)*2);
          }
        }
      }
      assert.match(bytecode,/^[0-9a-f]+$/i);
      linkedHashes[key]=sha(bytecode);
      const instance=await new ethers.ContractFactory(artifact.abi,bytecode,signer).deploy({gasLimit:90000000});
      await instance.waitForDeployment(); deployed.set(key,instance); return instance;
    }
    const harness=await deploy('Harness.sol','ParentHarness');
    const modules=[];
    for(let i=0;i<2;i++) {
      const c=compilation.contracts['Harness.sol'].RawModule;
      const m=await new ethers.ContractFactory(c.abi,c.evm.bytecode.object,signer).deploy();
      await m.waitForDeployment(); modules.push(m);
    }
    const base=await harness.routerSlot(), lengthSlot=base+1n;
    const idsStart=BigInt(ethers.keccak256(words(lengthSlot))), ids=[7n,9n];
    const moduleSlots=ids.map(id=>BigInt(ethers.keccak256(words(id,base))));
    const write=async(slot,value)=>{await(await harness.writeSlot(slot,value)).wait();};
    for(let i=0;i<2;i++)await write(idsStart+BigInt(i),ids[i]);
    const slots=[...(frame?[marker]:[]),lengthSlot,idsStart,idsStart+1n,...moduleSlots,...moduleSlots.map(x=>x+2n)];
    async function state() {
      return {storage:await Promise.all(slots.map(slot=>rpc.request({method:'eth_getStorageAt',params:[harness.target,ethers.toQuantity(slot),'latest']}))),
        balances:await Promise.all([harness.target,...modules.map(m=>m.target),...(frame?[recipient]:[])].map(address=>rpc.request({method:'eth_getBalance',params:[address,'latest']})))};
    }
    for(const test of cases.filter(c=>!mutation || c.name===mutation.test)) {
      const c={...defaults,...test}; await write(lengthSlot,c.count);
      if(frame) {
        await write(marker,0);
        await rpc.request({method:'evm_setAccountBalance',params:[harness.target,'0x2']});
      }
      const model=(c.memory?memoryVectors:vectors).find(v=>v.name===c.name);assert.ok(model,'missing model '+c.name);
      assert.equal(BigInt(model.count),BigInt(c.count));
      if(!c.memory) assert.deepEqual(model.shares,c.shares);
      else assert.notEqual(BigInt(c.count),0n,'memory-prefix vectors require nonempty parent');
      assert.equal(model.unit,BigInt(c.cfg[0]).toString());assert.equal(model.amount,BigInt(c.amount).toString());
      assert.equal(BigInt(c.cfg[1]),2048n);assert.equal(c.rejects[0],false);
      if(!c.memory) {assert.deepEqual(model.summaries,c.responses);assert.equal(model.reject1,c.rejects[1]);}
      for(let i=0;i<2;i++) {
        await write(moduleSlots[i],BigInt(modules[i].target)+(BigInt(c.shares[i])<<192n)+(1n<<232n));
        await write(moduleSlots[i]+2n,0);
        await(await modules[i].configure(c.responses[i],words(0),c.rejects[i],false)).wait();
      }
      const data=frame
        ? harness.interface.encodeFunctionData('parentWithPriorEffects',[c.cfg,c.amount,false,recipient])
        : harness.interface.encodeFunctionData('parent',[c.cfg,c.amount,false]);
      const before=await state(); let actual,reverted=false;
      try{actual=await rpc.request({method:'eth_call',params:[{to:harness.target,data,gas:'0x989680'},'latest']});}
      catch(e){reverted=true;actual=typeof e.data==='string'?e.data:e.data?.result;if(typeof actual!=='string')throw e;}
      const tx=await signer.sendTransaction({to:harness.target,data,gasLimit:10000000});
      try{await tx.wait();}catch(e){if(e.code!=='CALL_EXCEPTION')throw e;}
      const trace=await rpc.request({method:'debug_traceTransaction',params:[tx.hash,{}]});
      const txReceipt=await rpc.request({method:'eth_getTransactionReceipt',params:[tx.hash]});
      const after=await state();
      const calls=trace.structLogs.filter(x=>x.op==='STATICCALL').map(x=>{
        const target='0x'+x.stack.at(-2).slice(-40), offset=Number(BigInt('0x'+x.stack.at(-3))), length=Number(BigInt('0x'+x.stack.at(-4)));
        const i=modules.findIndex(m=>m.target.toLowerCase()===target.toLowerCase());
        return i+':'+x.memory.join('').slice(offset*2,(offset+length)*2);
      });
      const delegates=trace.structLogs.filter(x=>x.op==='DELEGATECALL').map(x=>{
        const target='0x'+x.stack.at(-2).slice(-40);
        return [...deployed].find(([,m])=>m.target.toLowerCase()===target.toLowerCase())?.[0]||target;
      });
      const record={name:c.name,calldata:data,actual,reverted,calls,delegates,before,after,events:txReceipt.logs,
        storageWrites:trace.structLogs.filter(x=>x.op==='SSTORE').length};
      receipts.push(record);
      fs.writeFileSync(output,JSON.stringify({scope:frame ? 'actual enclosing Solidity transaction: prior storage, event and value transfer commit on success and roll back on parent failure; not a universal frame proof' : 'pinned SRLib parent vs decoded producer/consumer/parent and early allocation-guard Lean executions; not full physical-memory proof',pin,compiler:solc.version(),settings,sources,
        model:{job:modelReceipt.job_id,producer:identity.producer,overlay:sha(manifest),receiptSha256:sha(fs.readFileSync(modelReceiptPath))},
        mutation:mutantName ? {name:mutantName,definition:mutation,mutatedSources} : null,
        originalHarnessSha256:sha(originalHarness),mutationsSha256:sha(fs.readFileSync(path.join(__dirname,'mutations.cjs'))),
        harnessSha256:sha(harnessSource),runnerSha256:sha(fs.readFileSync(__filename)),lockSha256:sha(fs.readFileSync(path.join(__dirname,'package-lock.json'))),
        linkedHashes,receipts},null,2)+'\n');
      assert.equal(actual.toLowerCase(),c.expected.toLowerCase(),c.name+' return/revert bytes');
      assert.equal(reverted,!!c.reverted,c.name+' return/revert kind');
      assert.equal(actual.toLowerCase(),model.actual.toLowerCase(),c.name+' Solidity/Lean return bytes');
      assert.equal(reverted,model.reverted,c.name+' Solidity/Lean outcome kind');
      assert.deepEqual(calls,c.calls,c.name+' static call order');
      assert.deepEqual(calls,model.calls,c.name+' Solidity/Lean static calls');
      assert.equal(delegates.filter(n=>n.endsWith(':MinFirstAllocationStrategy')).length,c.library?1:0,c.name+' allocation library call');
      assert.equal(BigInt(txReceipt.status),reverted?0n:1n,c.name+' transaction status');
      if(frame) {
        assert.equal(record.storageWrites,1,c.name+' prior write executed');
        assert.equal(trace.structLogs.filter(x=>x.op==='LOG1').length,1,c.name+' prior event executed');
        assert.equal(trace.structLogs.filter(x=>x.op==='CALL').length,1,c.name+' prior value call executed');
        if(reverted) {
          assert.deepEqual(after,before,c.name+' enclosing transaction rollback');
          assert.equal(txReceipt.logs.length,0,c.name+' reverted event discarded');
        } else {
          assert.equal(BigInt(after.storage[0]),42n,c.name+' prior storage committed');
          assert.deepEqual(after.storage.slice(1),before.storage.slice(1),c.name+' parent storage unchanged');
          assert.equal(BigInt(after.balances[0]),BigInt(before.balances[0])-1n,c.name+' prior debit committed');
          assert.equal(BigInt(after.balances.at(-1)),BigInt(before.balances.at(-1))+1n,c.name+' prior credit committed');
          assert.deepEqual(after.balances.slice(1,-1),before.balances.slice(1,-1),c.name+' module balances unchanged');
          assert.equal(txReceipt.logs.length,1,c.name+' prior event committed');
          assert.equal(txReceipt.logs[0].topics[0],ethers.id('BeforeParent(uint256)'));
          assert.equal(txReceipt.logs[0].data,words(42));
        }
      } else {
        assert.deepEqual(after,before,c.name+' view state/balances');assert.equal(txReceipt.logs.length,0);assert.equal(record.storageWrites,0);
      }
      console.log('PASS '+c.name);
    }
  } finally {provider.destroy();await rpc.disconnect();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
