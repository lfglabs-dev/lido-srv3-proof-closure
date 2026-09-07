import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import solc from 'solc';
import ganache from 'ganache';
import {AbiCoder,BrowserProvider,ContractFactory,Interface} from 'ethers';
const here=dirname(fileURLToPath(import.meta.url)),root=resolve(here,'../..');
const sha=x=>createHash('sha256').update(x).digest('hex');
const pin='17005714f151e5502c559932319a3f2f74ac2436';
assert.ok(process.argv[2],'successful current runtime receipt required');
const receiptPath=resolve(process.argv[2]),receipt=JSON.parse(readFileSync(receiptPath));
assert.equal(receipt.state,'succeeded'); assert.equal(receipt.exit_code,0);
assert.equal(receipt.validation.toolchain,'leanprover/lean4:v4.31.0');
const identity=JSON.parse(readFileSync(resolve(root,'audit/trio/alloc2/runtime/source-identity.json')));
assert.equal(identity.verity,'e977aaad6e1a9e92e0132d41b3d33a14135a4d46');
let manifest='sandboxed-source-bundle-v1\n';
for(const source of Object.keys(identity.files).sort()){
  assert.match(source,/^(LidoSRv3\/Audit\/Source\/TrioAlloc[12]\/[^/]+\.lean|audit\/trio\/alloc2\/(composition|runtime)\/([^/]+\.lean|lake-manifest\.json))$/);
  const data=source.includes('/TrioAlloc1/')?execFileSync('git',['-C',root,'show',`${identity.producer}:${source}`]):readFileSync(resolve(root,source));
  assert.equal(sha(data),identity.files[source],'stale source '+source);
  manifest+=`${source}\0${sha(data)}\n`;
}
const verified=receipt.log_tail.match(/^source bundle verified sha256=([a-f0-9]{64})(?: operations_sha256=[a-f0-9]{64})? files=(\d+) /m);
assert.ok(verified,'verified source overlay absent');
assert.equal(verified[1],sha(manifest),'source overlay differs from runtime identity');
assert.equal(Number(verified[2]),Object.keys(identity.files).length);
const parse=tag=>receipt.log_tail.split('\n').map(x=>x.match(new RegExp('(?:^|: )'+tag+' (.+)$'))).filter(Boolean).map(x=>JSON.parse(x[1]));
const vectors=parse('ALLOC2_MEMORY_SEQUENCE'),runtime=parse('ALLOC2_VERITY_MEMORY_SEQUENCE');
assert.equal(vectors.length,5);assert.equal(runtime.length,5);
const rollback=parse('ALLOC2_INDEXED_PREFIX_ROLLBACK');
assert.deepEqual(rollback,[{panic:50,storageRestored:true,balanceRestored:true,memoryRestored:true}]);
assert.equal(new Set(vectors.map(x=>x.name)).size,5);assert.equal(new Set(runtime.map(x=>x.name)).size,5);
for(const v of vectors){const r=runtime.find(x=>x.name===v.name);assert.ok(r);for(const key of ['firstAmount','secondAmount','first','second'])assert.deepEqual(r[key],v[key],v.name+' runtime '+key);}
const sources={};
for(const p of ['contracts/common/lib/MinFirstAllocationStrategy.sol','contracts/common/lib/Math256.sol']){
  const data=execFileSync('git',['-C',resolve(root,'lido-core'),'show',`${pin}:${p}`]);
  assert.deepEqual(data,readFileSync(resolve(root,'lido-core',p)));sources[p]={content:data.toString()};
}
const mutant=process.env.ALLOC2_SEQUENCE_MUTANT||'';
assert.ok(mutant===''||mutant==='reset','unknown mutant');
let harnessSource=readFileSync(resolve(here,'MemorySequence.sol'),'utf8');
if(mutant==='reset'){
  const target='allocate(first, capacities, d2)';
  assert.equal(harnessSource.split(target).length,2);
  harnessSource=harnessSource.replace(target,'allocate(buckets, capacities, d2)');
}
sources['MemorySequence.sol']={content:harnessSource};
assert.match(solc.version(),/^0\.8\.9\+commit\.e5eed63a\./);
const settings={optimizer:{enabled:true,runs:200},evmVersion:'istanbul',outputSelection:{'*':{'*':['abi','evm.bytecode','evm.deployedBytecode']}}};
const compilerInput={language:'Solidity',sources,settings},compiled=JSON.parse(solc.compile(JSON.stringify(compilerInput)));
assert.deepEqual((compiled.errors??[]).filter(x=>x.severity==='error'),[]);
const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'istanbul'},wallet:{deterministic:true},miner:{blockGasLimit:100000000}});
const provider=new BrowserProvider(rpc);provider.pollingInterval=10;
const results=[],coder=AbiCoder.defaultAbiCoder();
try{
  const signer=await provider.getSigner(),lib=compiled.contracts['contracts/common/lib/MinFirstAllocationStrategy.sol'].MinFirstAllocationStrategy;
  const library=await new ContractFactory(lib.abi,lib.evm.bytecode.object,signer).deploy();await library.waitForDeployment();
  const harness=compiled.contracts['MemorySequence.sol'].MemorySequence;
  let bytecode=harness.evm.bytecode.object;
  for(const libs of Object.values(harness.evm.bytecode.linkReferences))for(const refs of Object.values(libs))for(const {start,length} of refs){assert.equal(length,20);bytecode=bytecode.slice(0,start*2)+library.target.slice(2).toLowerCase()+bytecode.slice((start+length)*2);}
  const contract=await new ContractFactory(harness.abi,bytecode,signer).deploy();await contract.waitForDeployment();
  const iface=new Interface(harness.abi);
  for(const v of vectors){
    const data=iface.encodeFunctionData('sequence',[v.buckets,v.capacities,v.d1,v.d2]);
    const actual=await rpc.request({method:'eth_call',params:[{to:contract.target,data,gas:'0x5f5e100'},'latest']});
    const expected=coder.encode(['uint256','uint256','uint256[]','uint256[]','uint256[]','uint256[]'],[v.firstAmount,v.secondAmount,v.first,v.second,v.buckets,v.capacities]);
    assert.equal(actual.toLowerCase(),expected.toLowerCase(),v.name+' exact bytes');
    results.push({name:v.name,calldata:data,returndata:actual}); console.log('PASS memory sequence '+v.name);
  }
  const rollbackData=iface.encodeFunctionData('prefixThenAllocate',[[0],[],1]);
  const expectedPanic='0x4e487b71'+coder.encode(['uint256'],[rollback[0].panic]).slice(2);
  let revertBytes;
  try{await rpc.request({method:'eth_call',params:[{to:contract.target,data:rollbackData,gas:'0x5f5e100'},'latest']});assert.fail('short capacities succeeded');}
  catch(e){revertBytes=typeof e.data==='string'?e.data:e.data?.result;if(typeof revertBytes!=='string')throw e;}
  assert.equal(revertBytes.toLowerCase(),expectedPanic);
  const attempted=await signer.sendTransaction({to:contract.target,data:rollbackData,gasLimit:10000000});
  try{await attempted.wait();assert.fail('prefix transaction succeeded');}catch(e){if(e.code!=='CALL_EXCEPTION')throw e;}
  const txReceipt=await rpc.request({method:'eth_getTransactionReceipt',params:[attempted.hash]});
  assert.equal(BigInt(txReceipt.status),0n);assert.equal(txReceipt.logs.length,0);assert.equal(await contract.marker(),0n);
  results.push({name:'prefix-rollback',calldata:rollbackData,revertdata:revertBytes,status:txReceipt.status,logs:txReceipt.logs,marker:'0'});
  console.log('PASS indexed prefix rollback');
  assert.equal(mutant,'','mutant unexpectedly survived all exact comparisons');
  writeFileSync(resolve(root,'audit/trio/alloc2/memory-sequence-execution.json'),JSON.stringify({
    scope:'Sequential outputs of pinned public Solidity library vs current word-memory and Verity state execution; public ABI copies preserved; not byte-memory/compiler store-trace refinement',
    pin,compiler:solc.version(),settings,sourceHashes:Object.fromEntries(Object.entries(sources).map(([k,v])=>[k,sha(v.content)])),
    runnerSha256:sha(readFileSync(fileURLToPath(import.meta.url))),lockSha256:sha(readFileSync(resolve(here,'package-lock.json'))),
    receipt:{job:receipt.job_id,sha256:sha(readFileSync(receiptPath)),sourceOverlay:verified[1]},results,
    compilerInput,compilerOutput:compiled,linkedBytecode:bytecode,
    deployedLibrary:await provider.getCode(library.target),deployedHarness:await provider.getCode(contract.target)
  },null,2)+'\n');
}finally{provider.destroy();await rpc.disconnect();}
