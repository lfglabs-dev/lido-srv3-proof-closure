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
  const self=await lido.getAddress(), who=await signer.getAddress(), linked=await kernel.getAddress();
  const selector='0xfdef9106', role=await lido.BUFFER_RESERVE_MANAGER_ROLE();
  const payload=selector+ethers.AbiCoder.defaultAbiCoder().encode(['address','address','bytes32','bytes'],[who,self,role,'0x']).slice(2);
  const vectors=[],expected=[],traces=[];
  const cases=[
    ['uninitialized',0n,linked,word(1n),false],
    ['future initialization',(1n<<256n)-1n,linked,word(1n),false],
    ['zero kernel',1n,ethers.ZeroAddress,word(1n),false],
    ['kernel has no code',1n,who,word(1n),false],
    ['kernel denies',1n,linked,word(0n),false],
    ['kernel allows',1n,linked,word(1n),false],
    ['noncanonical nonzero bool',1n,linked,word(2n),false],
    ['short kernel reply',1n,linked,'0x01',false],
    ['kernel reverts',1n,linked,'0xdeadbeef',true],
    ['trailing kernel bytes',1n,linked,word(1n)+'cafe',false],
  ];
  for (const [name,initialization,k,reply,reject] of cases) {
    for (const [slot,value] of Object.entries({initialization,kernel:BigInt(k),reserve:80n,target:90n}))
      await (await lido.fixtureStore(slots[slot],value,{gasLimit:1000000})).wait();
    await (await kernel.configure(selector,reply,reject,{gasLimit:1000000})).wait();
    const tx=await lido.setDepositsReserveTarget(20n,{gasLimit:2000000});
    let receipt;try {receipt=await tx.wait();}catch(e){if(!e.receipt)throw e;receipt=e.receipt;}
    const trace=await backend.request({method:'debug_traceTransaction',params:[receipt.hash,{disableMemory:false}]});
    const calls=trace.structLogs.filter(x=>x.depth===1&&['CALL','STATICCALL'].includes(x.op)).map(x=>{
      const s=x.stack,off=Number(BigInt('0x'+s.at(x.op==='CALL'?-4:-3))),len=Number(BigInt('0x'+s.at(x.op==='CALL'?-5:-4)));
      assert.equal(x.op,'CALL','0.4.24 view call opcode');
      const data='0x'+x.memory.join('').slice(off*2,(off+len)*2);assert.equal(data,payload);
      assert.equal(BigInt('0x'+s.at(-2)),BigInt(k));
      assert.equal(BigInt('0x'+s.at(-3)),0n);return bytes(data);
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
    vectors.push({name,self:String(BigInt(self)),sender:String(BigInt(who)),kernel:String(BigInt(k)),initialization:String(initialization),blockNumber:String(receipt.blockNumber),code:String((await provider.getCode(k)).slice(2).length/2),reserve:'80',target:'90',requested:'20',reply:bytes(reply),reject});
    expected.push(actual);traces.push({name,hash:receipt.hash,returned,trace});
    fs.writeFileSync(path.join(dir,'input.json'),JSON.stringify(vectors,null,2));
    fs.writeFileSync(path.join(dir,'solidity.json'),JSON.stringify(expected,null,2));
    fs.writeFileSync(path.join(dir,'traces.json'),JSON.stringify(traces));
  }
  fs.writeFileSync(path.join(dir,'input.json'),JSON.stringify(vectors,null,2));
  fs.writeFileSync(path.join(dir,'solidity.json'),JSON.stringify(expected,null,2));
  fs.writeFileSync(path.join(dir,'traces.json'),JSON.stringify(traces));
  cp.execFileSync('lake',['env','lean','--run','LidoSRv3/Tests/TrioReserve1/AragonDifferential.lean',path.join(dir,'input.json'),path.join(dir,'lean.json')],{cwd:root,stdio:'pipe'});
  const actual=JSON.parse(fs.readFileSync(path.join(dir,'lean.json')));
  assert.deepEqual(actual,expected);
  console.log(`${expected.length} pinned Aragon/Lido admission comparisons matched`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
