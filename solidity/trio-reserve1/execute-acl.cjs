// Pinned inherited Lido/Aragon admission against explicit kernel-boundary fixtures.
const fs = require('node:fs'), path = require('node:path'), cp = require('node:child_process');
const assert = require('node:assert/strict');
const {ethers} = require('ethers');
const root = path.resolve(__dirname,'../..');
const dir = process.env.RESERVE1_RECEIPT_DIR;
if (!dir) throw Error('RESERVE1_RECEIPT_DIR is required');
const slots = {
  initialization:'0xebb05b386a8d34882b8711d156f463690983dc47815980fb82aeeff1aa43579e',
  kernel:'0x4172f0f7d2289153072b0a6ca36959e0cbe2efc3afe50fc81636caa96338137b',
  reserve:'0xda4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13',
  target:'0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81',
};
const bytes = x => Array.from(ethers.getBytes(x));
const word = x => ethers.zeroPadValue(ethers.toBeHex(x),32);
async function main() {
  fs.mkdirSync(dir,{recursive:false});
  process.env.HARDHAT_CONFIG = path.join(__dirname,'hardhat.config.cjs');
  const backend = require('hardhat').network.provider;
  const provider = new ethers.BrowserProvider(backend);provider.pollingInterval=10;
  const signer = await provider.getSigner();
  const artifacts = JSON.parse(fs.readFileSync(path.join(__dirname,'artifacts/LidoHarness.sol.json')));
  async function deploy(name) {
    const a=artifacts[name];const c=await new ethers.ContractFactory(a.abi,a.evm.bytecode.object,signer).deploy({gasLimit:29000000});
    await c.waitForDeployment();return c;
  }
  const lido=await deploy('LidoHarness'), kernel=await deploy('CallFixture');
  const ka=JSON.parse(fs.readFileSync(path.join(__dirname,'artifacts/KernelHarness.sol.json'))).KernelHarness;
  const sourceKernel=await new ethers.ContractFactory(ka.abi,ka.evm.bytecode.object,signer).deploy({gasLimit:29000000});
  await sourceKernel.waitForDeployment();const sourceAddress=await sourceKernel.getAddress();
  const middle=ethers.keccak256(ethers.concat([word(BigInt(ethers.id('app'))),word(0n)]));
  const aclCell=ethers.keccak256(ethers.concat([word(0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6an),middle]));
  const self=await lido.getAddress(), who=await signer.getAddress(), linked=await kernel.getAddress();
  const selector='0xfdef9106', role=await lido.BUFFER_RESERVE_MANAGER_ROLE();
  const payload=selector+ethers.AbiCoder.defaultAbiCoder().encode(['address','address','bytes32','bytes'],[who,self,role,'0x']).slice(2);
  const aa=JSON.parse(fs.readFileSync(path.join(__dirname,'artifacts/ACLHarness.sol.json')));
  async function deployACL(name){const a=aa[name];const c=await new ethers.ContractFactory(a.abi,a.evm.bytecode.object,signer).deploy({gasLimit:29000000});await c.waitForDeployment();return c;}
  const sourceACL=await deployACL('ACLHarness'),writingOracle=await deployACL('ACLWritingOracle');
  const aclAddress=await sourceACL.getAddress(),writingAddress=await writingOracle.getAddress();
  const ANY=ethers.getAddress('0x'+'ff'.repeat(20)),EMPTY=BigInt(ethers.keccak256(word(0n)));
  const P=(id,op,value)=> (BigInt(id)<<248n)|(BigInt(op)<<240n)|BigInt(value);
  const yes=P(205,7,1),no=P(205,7,0),oracle=P(203,7,BigInt(linked));
  const vectors=[],expected=[],traces=[];
  const cases=[
    {name:'no permissions'},
    {name:'unconditional specific',params:[]},
    {name:'unconditional wildcard',wild:[]},
    {name:'constant true',params:[yes]},
    {name:'constant false',params:[no]},
    {name:'missing how parameter',params:[P(0,7,1)]},
    {name:'constant equality',params:[P(205,1,7)]},
    {name:'constant inequality false',params:[P(205,2,7)]},
    {name:'block comparison',params:[P(200,3,1)]},
    {name:'timestamp comparison',params:[P(201,3,1)]},
    {name:'block comparison false',params:[P(200,4,1)]},
    {name:'NONE comparator denies',params:[P(205,0,1)]},
    {name:'NOT false',params:[P(204,8,1),no]},
    {name:'AND short circuit',params:[P(204,9,1n|(2n<<32n)),no,oracle]},
    {name:'OR short circuit',params:[P(204,10,1n|(2n<<32n)),yes,oracle]},
    {name:'XOR true false',params:[P(204,11,1n|(2n<<32n)),yes,no]},
    {name:'IF true chooses false branch',params:[P(204,12,1n|(2n<<32n)|(3n<<64n)),yes,no,oracle]},
    {name:'IF false chooses oracle',params:[P(204,12,1n|(2n<<32n)|(3n<<64n)),no,no,oracle]},
    {name:'oracle true',params:[oracle]},
    {name:'oracle false',params:[oracle],reply:word(0n)},
    {name:'oracle short reply',params:[oracle],reply:'0x01'},
    {name:'oracle long reply',params:[oracle],reply:word(1n)+'00'},
    {name:'oracle reverts',params:[oracle],reply:'0xdeadbeef',reject:true},
    {name:'oracle attempts write',params:[P(203,7,BigInt(writingAddress))],mode:'write',oracleTarget:writingAddress},
    {name:'oracle has no code',params:[P(203,7,BigInt(who))],mode:'no-code',oracleTarget:who},
    {name:'specific false falls back to wildcard oracle',params:[no],wild:[oracle]},
    {name:'invalid enum',params:[P(205,13,1)]},
    {name:'invalid enum after oracle',params:[P(203,13,BigInt(linked))]},
  ];
  for (const c of cases) {
    const {name}=c,initialization=1n,k=aclAddress,reply=c.reply??word(1n),reject=c.reject??false;
    for (const [slot,value] of Object.entries({initialization,kernel:BigInt(sourceAddress),reserve:80n,target:90n}))
      await (await lido.fixtureStore(slots[slot],value,{gasLimit:1000000})).wait();
    await (await sourceKernel.fixtureStore(aclCell,BigInt(k),{gasLimit:1000000})).wait();
    assert.equal(await sourceKernel.acl(),k,'physical nested ACL mapping');
    for(const [entity,params] of [[who,c.params],[ANY,c.wild]]){
      if(params===undefined)await(await sourceACL.fixtureRevoke(entity,self,role,{gasLimit:1000000})).wait();
      else await(await sourceACL.fixtureGrant(entity,self,role,params,{gasLimit:3000000})).wait();
    }
    await (await kernel.configure('0x2a151090',reply,reject,{gasLimit:1000000})).wait();
    const hashes=new Map(),storage=[];
    function hash(input){const output=ethers.keccak256(input);hashes.set(input,{input:bytes(input),output:String(BigInt(output))});return output;}
    hash(ethers.concat([word(BigInt(ethers.id('app'))),word(0n)]));
    hash(ethers.concat([word(0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6an),middle]));
    async function cell(slot,expected){const value=BigInt(await backend.request({method:'eth_getStorageAt',params:[aclAddress,ethers.toBeHex(slot,32),'latest']}));if(expected!==undefined)assert.equal(value,expected,'physical ACL layout');storage.push({slot:String(slot),value:String(value)});}
    for(const [entity,params] of [[who,c.params],[ANY,c.wild]]){
      const key=hash(ethers.concat([ethers.toUtf8Bytes('PERMISSION'),entity,self,role]));
      const slot=hash(ethers.concat([key,word(0n)]));
      const ph=params===undefined?0n:params.length===0?EMPTY:BigInt(ethers.keccak256(ethers.concat(params.map(word))));
      await cell(BigInt(slot),ph);
      if(params&&params.length){
        const lengthSlot=hash(ethers.concat([word(ph),word(1n)]));await cell(BigInt(lengthSlot),BigInt(params.length));
        const base=hash(lengthSlot);
        for(let i=0;i<params.length;i++){
          const encoded=params[i],packed=(encoded>>248n)|(((encoded>>240n)&255n)<<8n)|((encoded&((1n<<240n)-1n))<<16n);
          await cell((BigInt(base)+BigInt(i))% (1n<<256n),packed);
        }
      }
    }
    const tx=await lido.setDepositsReserveTarget(20n,{gasLimit:2000000});
    let receipt;try {receipt=await tx.wait();}catch(e){if(!e.receipt)throw e;receipt=e.receipt;}
    const trace=await backend.request({method:'debug_traceTransaction',params:[receipt.hash,{disableMemory:false}]});
    const calls=trace.structLogs.flatMap((x,index)=>{
      if (![1,2,3].includes(x.depth)||!['CALL','STATICCALL'].includes(x.op)) return [];
      const s=x.stack,off=Number(BigInt('0x'+s.at(x.op==='CALL'?-4:-3))),len=Number(BigInt('0x'+s.at(x.op==='CALL'?-5:-4)));
      assert.equal(x.op,x.depth===3?'STATICCALL':'CALL','source call opcode');
      const data='0x'+x.memory.join('').slice(off*2,(off+len)*2);if(x.depth<3)assert.equal(data,payload);
      assert.equal(BigInt('0x'+s.at(-2)),BigInt(x.depth===1?sourceAddress:x.depth===2?k:(c.oracleTarget??linked)));
      if(x.op==='CALL')assert.equal(BigInt('0x'+s.at(-3)),0n);
      const resume=trace.structLogs.findIndex((y,i)=>i>index&&y.depth===x.depth);
      assert.ok(resume>index);const accepted=BigInt('0x'+trace.structLogs[resume].stack.at(-1))!==0n;
      const terminal=trace.structLogs.slice(index+1,resume).filter(y=>y.depth===x.depth+1&&['RETURN','REVERT','STOP'].includes(y.op)).at(-1);
      let returned=[];if(terminal&&terminal.op!=='STOP'){
        const start=Number(BigInt('0x'+terminal.stack.at(-1))),length=Number(BigInt('0x'+terminal.stack.at(-2)));
        returned=bytes('0x'+terminal.memory.join('').slice(start*2,(start+length)*2));
      }
      return [{target:String(BigInt('0x'+s.at(-2))),value:'0',payload:bytes(data),accepted,returned,depth:x.depth-1,isStatic:x.op==='STATICCALL'}];
    });
    const terminal=trace.structLogs.filter(x=>x.depth===1&&['RETURN','REVERT','STOP'].includes(x.op)).at(-1);
    let returned='0x';if(terminal&&terminal.op!=='STOP'){
      const off=Number(BigInt('0x'+terminal.stack.at(-1))),len=Number(BigInt('0x'+terminal.stack.at(-2)));
      returned='0x'+terminal.memory.join('').slice(off*2,(off+len)*2);
    }
    let fault=receipt.status===1?'ok':returned==='0x'?'empty':returned.startsWith('0x08c379a0')?'APP_AUTH_FAILED':'bubbled';
    if(fault==='APP_AUTH_FAILED')assert.equal(ethers.AbiCoder.defaultAbiCoder().decode(['string'],'0x'+returned.slice(10))[0],fault);
    if(fault==='bubbled')assert.equal(returned,reply);
    const logs=receipt.logs.map(l=>{const p=lido.interface.parseLog(l);return [p.name,Array.from(p.args,String)];});
    const actual={name,fault,reserve:String(await lido.fixtureLoad(slots.reserve)),target:String(await lido.fixtureLoad(slots.target)),calls,logs};
    const block=await backend.request({method:'eth_getBlockByHash',params:[receipt.blockHash,false]});
    assert.equal(await writingOracle.written(),0n);
    vectors.push({name,storage,hashes:Array.from(hashes.values()),timestamp:String(BigInt(block.timestamp)),oracleMode:c.mode??'reply',oracleTarget:String(BigInt(c.oracleTarget??linked)),self:String(BigInt(self)),sender:String(BigInt(who)),kernel:String(BigInt(sourceAddress)),acl:String(BigInt(k)),aclCode:String((await provider.getCode(k)).slice(2).length/2),middle:String(BigInt(middle)),aclCell:String(BigInt(aclCell)),initialization:String(initialization),blockNumber:String(receipt.blockNumber),code:String((await provider.getCode(sourceAddress)).slice(2).length/2),reserve:'80',target:'90',requested:'20',reply:bytes(reply),reject});
    expected.push(actual);traces.push({name,hash:receipt.hash,returned,trace});
    fs.writeFileSync(path.join(dir,'input.json'),JSON.stringify(vectors,null,2));
    fs.writeFileSync(path.join(dir,'solidity.json'),JSON.stringify(expected,null,2));
    fs.writeFileSync(path.join(dir,'traces.json'),JSON.stringify(traces));
  }
  fs.writeFileSync(path.join(dir,'input.json'),JSON.stringify(vectors,null,2));
  fs.writeFileSync(path.join(dir,'solidity.json'),JSON.stringify(expected,null,2));
  fs.writeFileSync(path.join(dir,'traces.json'),JSON.stringify(traces));
  cp.execFileSync('lake',['env','lean','--run','LidoSRv3/Tests/TrioReserve1/ACLDifferential.lean',path.join(dir,'input.json'),path.join(dir,'lean.json')],{cwd:root,stdio:'pipe'});
  const actual=JSON.parse(fs.readFileSync(path.join(dir,'lean.json')));
  assert.deepEqual(actual,expected);
  console.log(`${expected.length} pinned ACL/Kernel/Aragon/Lido admission comparisons matched`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
