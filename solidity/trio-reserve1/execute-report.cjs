// Inherited pinned Lido report body; locator/vault/queue are explicit boundary fixtures.
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const assert=require('node:assert/strict'),crypto=require('node:crypto'),zlib=require('node:zlib');
const {ethers}=require('ethers');
const root=path.resolve(__dirname,'../..'),dir=process.env.RESERVE1_RECEIPT_DIR,lean=process.env.RESERVE1_LEAN;
if(!dir||!lean)throw Error('RESERVE1_RECEIPT_DIR and RESERVE1_LEAN are required');
const sha=b=>crypto.createHash('sha256').update(b).digest('hex');
const word=x=>ethers.zeroPadValue(ethers.toBeHex(x),32),bytes=x=>Array.from(ethers.getBytes(x));
const slots={active:'0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece',locator:'0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223',packed:'0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f',reserve:'0xda4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13',target:'0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81'};
const selectors={accounting:'0x9624e83e',rewardsVault:'0xe441d25f',withdrawalVault:'0x69d42148',queue:'0x37d5fe99',rewards:'0x9342c8f4',withdrawals:'0x3194528a',finalize:'0xb6013cef'};
function terminalData(x){if(!x||x.op==='STOP')return '0x';const off=Number(BigInt('0x'+x.stack.at(-1))),len=Number(BigInt('0x'+x.stack.at(-2)));return '0x'+x.memory.join('').slice(off*2,(off+len)*2);}
async function main(){
 fs.mkdirSync(dir,{recursive:false});
 const pin=cp.execFileSync('git',['-C','lido-core','rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim();
 assert.equal(pin,'17005714f151e5502c559932319a3f2f74ac2436');
 cp.execFileSync('git',['-C','lido-core','diff','--exit-code','HEAD','--','contracts'],{cwd:root});
 const artifactPath=path.join(__dirname,'artifacts/LidoHarness.sol.json'),artifactRaw=fs.readFileSync(artifactPath);
 assert.equal(sha(artifactRaw),'106b8734ed3e3de196820a40a5abbadacd26265767a61b262fbdf0089a876292'); // retained compiled artifact
 const artifacts=JSON.parse(artifactRaw);
 process.env.HARDHAT_CONFIG=path.join(__dirname,'hardhat.config.cjs');
 const backend=require('hardhat').network.provider,provider=new ethers.BrowserProvider(backend);provider.pollingInterval=10;
 const signer=await provider.getSigner();
 async function deploy(name){const a=artifacts[name],c=await new ethers.ContractFactory(a.abi,a.evm.bytecode.object,signer).deploy({gasLimit:29000000});await c.waitForDeployment();return c;}
 const lido=await deploy('LidoHarness'),locator=await deploy('CallFixture'),vault=await deploy('CallFixture'),queue=await deploy('CallFixture');
 const self=await lido.getAddress(),who=await signer.getAddress(),loc=await locator.getAddress(),va=await vault.getAddress(),qa=await queue.getAddress();
 const vectors=[],expected=[],traceIndex=[];
 const max=(1n<<256n)-1n,width=1n<<128n;
 const cases=[{name:'all ordered calls'},{name:'zero amounts',rewards:0n,withdrawals:0n,lock:0n},{name:'stopped',active:0n},{name:'unauthorized',accounting:va},{name:'malformed accounting',accountingReply:'0x01'},{name:'reward rejection',reject:'rewards'},{name:'withdrawal rejection',reject:'withdrawals'},{name:'queue rejection',reject:'finalize'},{name:'checked addition overflow',rewards:max},{name:'checked subtraction underflow',lock:151n},{name:'low128 narrowing and full event',buffer:width-1n,rewards:2n,withdrawals:0n,lock:0n},{name:'reserve above target',reserve:80n},{name:'malformed reward return',rewardReply:'0x'},{name:'trailing reward bytes',rewardReply:word(999n)+'cafe'},{name:'queue no code',noCodeQueue:true},{name:'insufficient queue funds',lock:1001n}];
 for(const c of cases){
  const active=c.active??1n,packed=(c.buffer??100n)+7n*width,reserve=c.reserve??20n,target=50n,balance=1000n;
  const args=[11n,12n,13n,c.withdrawals??30n,c.rewards??20n,14n,15n,c.lock??40n];
  for(const [key,val] of Object.entries({active,locator:BigInt(loc),packed,reserve,target}))await(await lido.fixtureStore(slots[key],val,{gasLimit:1000000})).wait();
  await backend.request({method:'hardhat_setBalance',params:[self,ethers.toBeHex(balance)]});
  await backend.request({method:'hardhat_setBalance',params:[qa,'0x0']});
  const configs=[['accounting',locator,c.accountingReply??word(BigInt(c.accounting??who)),[]],['rewardsVault',locator,word(BigInt(va)),[]],['withdrawalVault',locator,word(BigInt(va)),[]],['queue',locator,word(BigInt(c.noCodeQueue?who:qa)),[]],['rewards',vault,c.rewardReply??word(999n),[args[4]]],['withdrawals',vault,'0x',[args[3]]],['finalize',queue,'0x',[args[5],args[6]]]];
  const replies=[];
  for(const [key,contract,normal,params] of configs){const reject=c.reject===key,data=reject?'0xdeadbeef':normal;await(await contract.configure(selectors[key],data,reject,{gasLimit:1000000})).wait();replies.push({target:String(BigInt(await contract.getAddress())),payload:bytes(selectors[key]+params.map(v=>word(v).slice(2)).join('')),data:bytes(data),reject});}
  const tx=await lido.collectRewardsAndProcessWithdrawals(...args,{gasLimit:5000000});let receipt;try{receipt=await tx.wait();}catch(e){if(!e.receipt)throw e;receipt=e.receipt;}
  const trace=await backend.request({method:'debug_traceTransaction',params:[receipt.hash,{disableMemory:false,disableStorage:true}]});
  const calls=trace.structLogs.flatMap((x,index)=>{
   if(x.depth!==1||!['CALL','STATICCALL'].includes(x.op))return [];
   assert.equal(x.op,'CALL','0.4.24 call opcode');const s=x.stack,off=Number(BigInt('0x'+s.at(-4))),len=Number(BigInt('0x'+s.at(-5)));
   const resume=trace.structLogs.findIndex((y,i)=>i>index&&y.depth===1);assert.ok(resume>index);
   const accepted=BigInt('0x'+trace.structLogs[resume].stack.at(-1))!==0n;
   const term=trace.structLogs.slice(index+1,resume).filter(y=>y.depth===2&&['RETURN','REVERT','STOP'].includes(y.op)).at(-1);
   return [{target:String(BigInt('0x'+s.at(-2))),value:String(BigInt('0x'+s.at(-3))),payload:bytes('0x'+x.memory.join('').slice(off*2,(off+len)*2)),accepted,returned:bytes(terminalData(term))}];
  });
  assert.ok(!trace.structLogs.some(x=>x.depth>2),'fixture boundary has no hidden nested calls');
  const returned=terminalData(trace.structLogs.filter(x=>x.depth===1&&['RETURN','REVERT','STOP'].includes(x.op)).at(-1));
  let fault=receipt.status===1?'ok':returned==='0x'?'empty':returned.startsWith('0x08c379a0')?ethers.AbiCoder.defaultAbiCoder().decode(['string'],'0x'+returned.slice(10))[0]:'bubbled';
  const logs=receipt.logs.map(l=>{assert.equal(l.address.toLowerCase(),self.toLowerCase());const p=lido.interface.parseLog(l);return [p.name,Array.from(p.args,String)];});
  vectors.push({name:c.name,self:String(BigInt(self)),sender:String(BigInt(who)),locator:String(BigInt(loc)),vault:String(BigInt(va)),queue:String(BigInt(qa)),active:String(active),packed:String(packed),reserve:String(reserve),target:String(target),balance:String(balance),queueBalance:'0',args:args.map(String),replies});
  expected.push({name:c.name,fault,bubbled:fault==='bubbled'?bytes(returned):[],packed:String(await lido.fixtureLoad(slots.packed)),reserve:String(await lido.fixtureLoad(slots.reserve)),target:String(await lido.fixtureLoad(slots.target)),balance:String(BigInt(await backend.request({method:'eth_getBalance',params:[self,'latest']}))),queueBalance:String(BigInt(await backend.request({method:'eth_getBalance',params:[qa,'latest']}))),calls,logs});
  const raw=Buffer.from(JSON.stringify({name:c.name,hash:receipt.hash,returned,trace})),compressed=zlib.gzipSync(raw),file=`trace-${vectors.length}.json.gz`;fs.writeFileSync(path.join(dir,file),compressed);traceIndex.push({name:c.name,file,sha256:sha(compressed),decompressed_sha256:sha(raw),bytes:raw.length,transaction:receipt.hash,status:receipt.status});
  fs.writeFileSync(path.join(dir,'input.json'),JSON.stringify(vectors,null,2));fs.writeFileSync(path.join(dir,'solidity.json'),JSON.stringify(expected,null,2));fs.writeFileSync(path.join(dir,'traces.json'),JSON.stringify(traceIndex,null,2));
 }
 const argv=['--run','LidoSRv3/Tests/TrioReserve1/ReportDifferential.lean',path.join(dir,'input.json'),path.join(dir,'lean.json')];
 const p=cp.spawnSync(lean,argv,{cwd:root,encoding:'utf8',env:process.env,maxBuffer:16*1024*1024});fs.writeFileSync(path.join(dir,'lean-run.txt'),(p.stdout??'')+(p.stderr??''));
 const context={source_commit:cp.execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),pin,node:process.version,node_sha256:sha(fs.readFileSync(process.execPath)),ethers:ethers.version,compilation_receipt_sha256:sha(fs.readFileSync(path.join(root,"audit/trio/reserve1/receipts/solidity-compilation-with-oracle.json"))),lean_version:cp.execFileSync(lean,["--version"],{encoding:"utf8"}).trim(),backend:require('hardhat/package.json').version,artifact_sha256:sha(artifactRaw),lean,argv,lean_exit:p.status,lean_sha256:sha(fs.readFileSync(lean)),lean_path:process.env.LEAN_PATH,utc:new Date().toISOString(),scope:'Inherited pinned report body against explicit callee fixtures, not concrete vault/queue implementations',source_hashes:Object.fromEntries(['LidoSRv3/Audit/Source/TrioReserve1/Report.lean','LidoSRv3/Audit/Source/TrioReserve1/CallData.lean','LidoSRv3/Tests/TrioReserve1/ReportDifferential.lean','solidity/trio-reserve1/execute-report.cjs','solidity/trio-reserve1/LidoHarness.sol','lido-core/contracts/0.4.24/Lido.sol'].map(f=>[f,sha(fs.readFileSync(path.join(root,f)))]))};fs.writeFileSync(path.join(dir,'context.json'),JSON.stringify(context,null,2));
 assert.equal(p.status,0,p.stderr);assert.deepEqual(JSON.parse(fs.readFileSync(path.join(dir,'lean.json'))),expected);console.log(`${expected.length} inherited pinned Lido report comparisons matched`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
