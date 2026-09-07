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
assert.ok(process.argv[2],'successful current byte-denotation receipt required');
const receiptPath=resolve(process.argv[2]),receipt=JSON.parse(readFileSync(receiptPath));
assert.equal(receipt.state,'succeeded'); assert.equal(receipt.exit_code,0);
assert.equal(receipt.validation.toolchain,'leanprover/lean4:v4.31.0');
const identity=JSON.parse(readFileSync(resolve(root,'audit/trio/alloc2/byte-abi/source-identity.json')));
assert.equal(identity.verity,'e977aaad6e1a9e92e0132d41b3d33a14135a4d46');
let manifest='sandboxed-source-bundle-v1\n';
for(const source of Object.keys(identity.files).sort()){
  assert.match(source,/^(LidoSRv3\/Audit\/Source\/TrioAlloc[12]\/[^/]+\.lean|audit\/trio\/alloc2\/(composition|runtime|byte-memory|byte-runtime|byte-abi)\/([^/]+\.lean|lake-manifest\.json))$/);
  const data=source.includes('/TrioAlloc1/')?execFileSync('git',['-C',root,'show',`${identity.producer}:${source}`]):readFileSync(resolve(root,source));
  assert.equal(sha(data),identity.files[source],'stale source '+source);
  manifest+=`${source}\0${sha(data)}\n`;
}
const verified=receipt.log_tail.match(/^source bundle verified sha256=([a-f0-9]{64})(?: operations_sha256=[a-f0-9]{64})? files=(\d+) /m);
assert.ok(verified,'verified source overlay absent');
assert.equal(verified[1],sha(manifest),'source overlay differs from byte-memory identity');
assert.equal(Number(verified[2]),Object.keys(identity.files).length);
const parse=tag=>receipt.log_tail.split('\n').map(x=>x.match(new RegExp('(?:^|: )'+tag+' (.+)$'))).filter(Boolean).map(x=>JSON.parse(x[1]));
const vectors=parse('ALLOC2_BYTE_COPY');
assert.equal(vectors.length,7);
assert.equal(new Set(vectors.map(v=>v.name)).size,7);
const mutant=process.env.ALLOC2_BYTE_COPY_MUTANT||'';
assert.ok(mutant===''||mutant==='shift');
let source=readFileSync(resolve(here,'ByteCopy.sol'),'utf8');
if(mutant==='shift'){
  const target='calldatacopy(add(out, 32), input.offset, input.length)';
  assert.equal(source.split(target).length,2);
  source=source.replace(target,'calldatacopy(add(out, 32), add(input.offset, 1), input.length)');
}
assert.match(solc.version(),/^0\.8\.9\+commit\.e5eed63a\./);
const settings={optimizer:{enabled:true,runs:200},evmVersion:'istanbul',outputSelection:{'*':{'*':['abi','evm.bytecode','evm.deployedBytecode']}}};
const compilerInput={language:'Solidity',sources:{'ByteCopy.sol':{content:source}},settings};
const compiled=JSON.parse(solc.compile(JSON.stringify(compilerInput)));
assert.deepEqual((compiled.errors??[]).filter(x=>x.severity==='error'),[]);
const artifact=compiled.contracts['ByteCopy.sol'].ByteCopy;
const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'istanbul'},wallet:{deterministic:true}});
const provider=new BrowserProvider(rpc);provider.pollingInterval=10;
const results=[],coder=AbiCoder.defaultAbiCoder();
try{
  const signer=await provider.getSigner();
  const contract=await new ContractFactory(artifact.abi,artifact.evm.bytecode.object,signer).deploy();
  await contract.waitForDeployment();
  const iface=new Interface(artifact.abi);
  for(const v of vectors){
    for(const [method,field] of [['copyCalldata','calldata'],['copyReturn','returndata']]){
      const data=iface.encodeFunctionData(method,[v.input]);
      const actual=await rpc.request({method:'eth_call',params:[{to:contract.target,data},'latest']});
      assert.equal(actual.toLowerCase(),coder.encode(['bytes'],[v[field]]).toLowerCase(),v.name+' '+method+' exact bytes');
      results.push({name:v.name,method,calldata:data,returndata:actual});
      console.log('PASS '+v.name+' '+method);
    }
  }
  assert.equal(mutant,'','mutant survived');
  writeFileSync(resolve(root,'audit/trio/alloc2/byte-copy-execution.json'),JSON.stringify({
    scope:'Explicit Solidity calldata/returndata copy opcodes vs pinned Verity DenoteMemory operations; exact copied byte sequences; not full compiler schedule',
    compiler:solc.version(),settings,runnerSha256:sha(readFileSync(fileURLToPath(import.meta.url))),
    lockSha256:sha(readFileSync(resolve(here,'package-lock.json'))),
    receipt:{job:receipt.job_id,sha256:sha(readFileSync(receiptPath)),sourceOverlay:verified[1]},
    compilerInput,compilerOutput:compiled,deployedHarness:await provider.getCode(contract.target),results
  },null,2)+'\n');
}finally{provider.destroy();await rpc.disconnect();}
