// Actual inherited ERC721 finalize body, physical storage setup, local EVM only.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const assert=require('node:assert/strict'),crypto=require('node:crypto'),zlib=require('node:zlib');
const {ethers}=require('ethers');
const root=path.resolve(__dirname,'../..'),dir=process.env.RESERVE1_RECEIPT_DIR,lean=process.env.RESERVE1_LEAN,compDir=process.env.RESERVE1_QUEUE_COMPILATION;
if(!dir||!lean||!compDir)throw Error('Receipt, Lean and queue compilation paths required');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex'),word=n=>ethers.zeroPadValue(ethers.toBeHex(n),32),bytes=x=>Array.from(ethers.getBytes(x));
const id=s=>BigInt(ethers.id(s));
const slots={last:id('lido.WithdrawalQueue.lastRequestId'),finalized:id('lido.WithdrawalQueue.lastFinalizedRequestId'),checkpoint:id('lido.WithdrawalQueue.lastCheckpointIndex'),locked:id('lido.WithdrawalQueue.lockedEtherAmount'),resume:id('lido.PausableUntil.resumeSinceTimestamp')};
const queueSlot=id('lido.WithdrawalQueue.queue'),checkpoints=id('lido.WithdrawalQueue.checkpoints'),roles=id('openzeppelin.AccessControl._roles'),role=id('FINALIZE_ROLE');
function terminalData(x){if(!x||x.op==='STOP')return '0x';const off=Number(BigInt('0x'+x.stack.at(-1))),len=Number(BigInt('0x'+x.stack.at(-2)));return '0x'+x.memory.join('').slice(off*2,(off+len)*2);}
async function main(){
 fs.mkdirSync(dir,{recursive:false});
 const pin=cp.execFileSync('git',['-C','lido-core','rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim();assert.equal(pin,'17005714f151e5502c559932319a3f2f74ac2436');cp.execFileSync('git',['-C','lido-core','diff','--exit-code','HEAD','--','contracts'],{cwd:root});
 const compRaw=fs.readFileSync(path.join(compDir,'receipt.json')),comp=JSON.parse(compRaw);assert.equal(comp.pin,pin);assert.equal(comp.errors.length,0);
 for(const record of Object.values(comp.sources))assert.equal(sha(fs.readFileSync(path.join(root,record.resolved_path))),record.sha256);
 const record=comp.artifacts.QueueFinalizeHarness,raw=fs.readFileSync(path.join(compDir,record.file));assert.equal(sha(raw),record.sha256);const artifact=JSON.parse(raw);
 process.env.HARDHAT_CONFIG=path.join(__dirname,'hardhat.config.cjs');const backend=require('hardhat').network.provider,provider=new ethers.BrowserProvider(backend);provider.pollingInterval=10;const signer=await provider.getSigner();
 const queue=await new ethers.ContractFactory(artifact.abi,artifact.evm.bytecode.object,signer).deploy({gasLimit:29000000});await queue.waitForDeployment();const qa=await queue.getAddress(),sender=await signer.getAddress();
 const runtime=await backend.request({method:'eth_getCode',params:[qa,'latest']});fs.writeFileSync(path.join(dir,'deployment.json'),JSON.stringify({address:qa,constructor_arguments:[],runtime_code:runtime,runtime_code_sha256:sha(Buffer.from(ethers.getBytes(runtime)))},null,2));
 const max=(1n<<256n)-1n,width=1n<<128n,mask=max;
 const cases=[{name:'finalization success'},{name:'late shares underflow',shares:8n},{name:'paused',paused:true,last:4n},{name:'role low byte denied',member:256n},{name:'role noncanonical true byte',member:2n},{name:'upper id invalid',last:4n},{name:'already finalized id',last:1n},{name:'too much ether',amount:81n},{name:'entry first id overflow',finalized:max,last:0n},{name:'steth underflow',steth:90n},{name:'checkpoint overflow',checkpoint:max},{name:'locked overflow',locked:max-50n},{name:'zero value finalization',amount:0n},{name:'short calldata before pause',short:true,paused:true},{name:'trailing calldata accepted',trailing:true}];
 const inputs=[],expected=[],traces=[];
 for(const c of cases){
  const hashes=new Map();const hashed=(key,slot)=>{const input=word(key)+word(slot).slice(2),output=ethers.keccak256(input);hashes.set(input,output);return BigInt(output);};
  const roleBase=hashed(role,roles),memberSlot=hashed(BigInt(sender),roleBase);
  const finalized=c.finalized??1n,index=c.checkpoint??2n,last=c.last??3n,amount=c.amount??60n;
  const oldRow=hashed(finalized,queueSlot),newRow=hashed(last,queueSlot),nextSlot=hashed((index+1n)&mask,checkpoints);
  const timestamp=BigInt((await backend.request({method:'eth_getBlockByNumber',params:['latest',false]})).timestamp)+1000n;
  const storage=new Map([[slots.last,3n],[slots.finalized,finalized],[slots.checkpoint,index],[slots.locked,c.locked??5n],[slots.resume,c.paused?timestamp+1n:timestamp],[memberSlot,c.member??257n],[oldRow,100n+10n*width],[nextSlot,0n],[(nextSlot+1n)&mask,0n]]);
  if(newRow!==oldRow)storage.set(newRow,(c.steth??180n)+(c.shares??18n)*width);
  // Reset every observed row, including future checkpoints, between transactions.
  for(const [slot,value] of storage)await(await queue.fixtureStore(word(slot),value,{gasLimit:1000000})).wait();
  await backend.request({method:'hardhat_setBalance',params:[qa,'0x50']});
  await backend.request({method:'evm_setNextBlockTimestamp',params:[Number(timestamp)]});
  const payload=c.short?'0xb6013cef':queue.interface.encodeFunctionData('finalize',[last,123n])+(c.trailing?'cafe':'');
  const senderBefore=BigInt(await backend.request({method:'eth_getBalance',params:[sender,'latest']}));
  const tx=await signer.sendTransaction({to:qa,data:payload,value:amount,gasLimit:5000000});let receipt;try{receipt=await tx.wait();}catch(e){if(!e.receipt)throw e;receipt=e.receipt;}
  const trace=await backend.request({method:'debug_traceTransaction',params:[receipt.hash,{disableMemory:false,disableStorage:true}]});
  const nestedCalls=trace.structLogs.filter(x=>['CALL','STATICCALL','DELEGATECALL','CALLCODE'].includes(x.op)).length;assert.equal(nestedCalls,0);
  // Every executed 64-byte mapping hash must use a recorded Keccak preimage/output.
  for(const x of trace.structLogs.filter(x=>['SHA3','KECCAK256'].includes(x.op))){const off=Number(BigInt('0x'+x.stack.at(-1))),len=Number(BigInt('0x'+x.stack.at(-2)));if(len===64){const data='0x'+x.memory.join('').slice(off*2,(off+len)*2);assert.ok(hashes.has(data),'unrecorded mapping hash '+data);}}
  const returned=terminalData(trace.structLogs.filter(x=>x.depth===1&&['RETURN','REVERT','STOP'].includes(x.op)).at(-1));
  const logs=receipt.logs.map(l=>{assert.equal(l.address.toLowerCase(),qa.toLowerCase());const p=queue.interface.parseLog(l);return[p.name,Array.from(p.args,String)];});
  inputs.push({name:c.name,queue:String(BigInt(qa)),sender:String(BigInt(sender)),timestamp:String(timestamp),balance:'80',amount:String(amount),payload:bytes(payload),storage:Array.from(storage,([slot,value])=>({slot:String(slot),value:String(value)})),hashes:Array.from(hashes,([input,output])=>({input:bytes(input),output:String(BigInt(output))}))});
  const observed=[];for(const slot of storage.keys())observed.push([String(slot),String(await queue.fixtureLoad(word(slot)))]);
  expected.push({name:c.name,success:receipt.status===1,returned:bytes(returned),balance:String(BigInt(await backend.request({method:'eth_getBalance',params:[qa,'latest']}))),senderValueDebit:String(senderBefore-BigInt(await backend.request({method:'eth_getBalance',params:[sender,'latest']}))-receipt.gasUsed*receipt.gasPrice),storage:observed,nestedCalls,logs});
  const full=Buffer.from(JSON.stringify({name:c.name,transaction:receipt.hash,returned,trace})),compressed=zlib.gzipSync(full),file=`trace-${inputs.length}.json.gz`;fs.writeFileSync(path.join(dir,file),compressed);traces.push({name:c.name,file,sha256:sha(compressed),decompressed_sha256:sha(full),bytes:full.length,transaction:receipt.hash,status:receipt.status});
  fs.writeFileSync(path.join(dir,'input.json'),JSON.stringify(inputs,null,2));fs.writeFileSync(path.join(dir,'solidity.json'),JSON.stringify(expected,null,2));fs.writeFileSync(path.join(dir,'traces.json'),JSON.stringify(traces,null,2));
 }
 const argv=['--run','LidoSRv3/Tests/TrioReserve1/QueueFinalizeDifferential.lean',path.join(dir,'input.json'),path.join(dir,'lean.json')];const p=cp.spawnSync(lean,argv,{cwd:root,encoding:'utf8',env:process.env,maxBuffer:16*1024*1024});fs.writeFileSync(path.join(dir,'lean-run.txt'),(p.stdout??'')+(p.stderr??''));
 const sources=['LidoSRv3/Audit/Source/TrioReserve1/QueueFinalize.lean','LidoSRv3/Audit/Source/TrioReserve1/Queue.lean','LidoSRv3/Audit/Source/TrioReserve1/Live.lean','LidoSRv3/Audit/Source/TrioReserve1/CallData.lean','LidoSRv3/Audit/Source/TrioReserve1/ReplyABI.lean','LidoSRv3/Tests/TrioReserve1/QueueFinalizeDifferential.lean','LidoSRv3/Tests/TrioReserve1/ReportDifferential.lean','solidity/trio-reserve1/execute-queue-finalize.cjs','solidity/trio-reserve1/QueueFinalizeHarness.sol'];
 fs.writeFileSync(path.join(dir,'context.json'),JSON.stringify({source_commit:cp.execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),pin,utc:new Date().toISOString(),node:process.version,node_sha256:sha(fs.readFileSync(process.execPath)),ethers:ethers.version,backend:require('hardhat/package.json').version,compilation:compDir,compilation_receipt_sha256:sha(compRaw),artifact_sha256:sha(raw),deployment_sha256:sha(fs.readFileSync(path.join(dir,'deployment.json'))),lean,lean_sha256:sha(fs.readFileSync(lean)),lean_version:cp.execFileSync(lean,['--version'],{encoding:'utf8'}).trim(),lean_path:process.env.LEAN_PATH,argv,lean_exit:p.status,source_hashes:Object.fromEntries(sources.map(f=>[f,sha(fs.readFileSync(path.join(root,f)))])),scope:'Inherited production ERC721 queue finalize, physical setup and recorded Keccak rows; no proxy/resource or all-path claim'},null,2));
 assert.equal(p.status,0,p.stderr);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(dir,'lean.json'))),expected);console.log(`${expected.length} inherited ERC721 queue finalization comparisons matched`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
