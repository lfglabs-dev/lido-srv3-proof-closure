// Pinned Solidity execution probes, not differential or correspondence evidence.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const ganache = require('ganache');
const {ethers} = require('ethers');
const U128 = 1n << 128n;
const slots = {
  locator:'0xd92bc31601d11a10411d08f59b7146d8a5915af253cde25f8e66b67beb4be223',
  buffer:'0x81a11fa1111afa59b50051f60ccf604a39d96acb484dc467ad8eadb4a63f0a5f',
  next:'0x8d3ed945c7718edcdb639b1235f2bbe3fa81f4a6cec7a436d8ea13fbc502d957',
  seed:'0x3f0eaa2c0f16ff9775c078f3df30470d8c042317b24ad1defa240b1c3e10b238',
  reserve:'0xda4fbe3b9cbd98dfae5dff538bbff4ba61f38979d4d7419bcd006f3e6250ec13',
  target:'0x3d3e9bd6e90e5d1f1c6839835bcbe5746a47c9a013d1eae6e80c248264c06a81',
  active:'0x644132c4ddd5bb6f0655d5fe2870dcec7870e6be4758890f366b83441f9fdece',
};
const coder = ethers.AbiCoder.defaultAbiCoder();
const selector = signature => ethers.id(signature).slice(0,10);
const encode = (types, values) => coder.encode(types, values);
const artifacts = name => JSON.parse(fs.readFileSync(path.join(__dirname,'artifacts',name+'.sol.json')));
async function main() {
  const backend = ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai',allowUnlimitedContractSize:true},wallet:{deterministic:true}});
  const provider = new ethers.BrowserProvider(backend);
  provider.pollingInterval = 10;
  const signer = await provider.getSigner();
  async function deploy(file, name) {
    const a = artifacts(file)[name];
    const c = await new ethers.ContractFactory(a.abi,a.evm.bytecode.object,signer).deploy({gasLimit:29000000});
    await c.waitForDeployment(); return c;
  }
  const lido = await deploy('LidoHarness','LidoHarness');
  const queue = await deploy('QueueHarness','QueueHarness');
  const locator = await deploy('LidoHarness','CallFixture');
  const router = await deploy('LidoHarness','CallFixture');
  const oracle = await deploy('LidoHarness','CallFixture');
  const addresses = {lido:await lido.getAddress(),queue:await queue.getAddress(),locator:await locator.getAddress(),router:await router.getAddress(),oracle:await oracle.getAddress()};
  const send = async tx => (await tx).wait();
  const configure = (c, signature, data, reject=false) => send(c.configure(selector(signature),data,reject));
  const store = (name, value) => send(lido.fixtureStore(slots[name],value));
  await configure(locator,'withdrawalQueue()',encode(['address'],[addresses.queue]));
  await configure(locator,'stakingRouter()',encode(['address'],[addresses.router]));
  await configure(locator,'accountingOracle()',encode(['address'],[addresses.oracle]));
  await configure(oracle,'getCurrentFrame()',encode(['uint256','uint256'],[11n,123n]));
  await store('locator',BigInt(addresses.locator));
  await store('active',1n);
  await store('buffer',100n);
  await store('reserve',20n);
  await store('target',20n);
  await store('next',10n * U128 + 9n); // old frame, must reset
  await send(queue.fixtureEnqueue(50n,50n,await signer.getAddress()));
  await backend.request({method:'evm_setAccountBalance',params:[addresses.lido,ethers.toQuantity(100n)]});
  async function observe() {
    const storage = {};
    for (const [key, slot] of Object.entries(slots)) storage[key] = (await lido.fixtureLoad(slot)).toString();
    const balances = {};
    for (const key of ['lido','router','queue']) balances[key] = BigInt(await backend.request({method:'eth_getBalance',params:[addresses[key],'latest']})).toString();
    return {storage,balances};
  }
  const cases = [];
  async function run(name, setup, amount, seeds, expectedSuccess, check=()=>{}, direct=false) {
    const snapshot = await backend.request({method:'evm_snapshot',params:[]});
    try {
      await setup();
      const before = await observe();
      const payload = lido.interface.encodeFunctionData('withdrawDepositableEther',[amount,seeds]);
      let receipt;
      try {
        const tx = direct ? await signer.sendTransaction({to:addresses.lido,data:payload,gasLimit:5000000})
          : await router.forward(addresses.lido,payload,{gasLimit:5000000});
        receipt = await tx.wait();
      } catch (e) { if (!e.receipt) throw e; receipt=e.receipt; }
      const success = receipt.status === 1;
      assert.equal(success,expectedSuccess,name);
      const after = await observe();
      if (!success) { assert.deepEqual(after,before,name+' rollback'); assert.equal(receipt.logs.length,0); }
      await check(after,before);
      const trace = await backend.request({method:'debug_traceTransaction',params:[receipt.hash,{disableMemory:false}]});
      const calls = trace.structLogs.filter(x=>['CALL','STATICCALL','DELEGATECALL'].includes(x.op)).map(x=>{
        const s=x.stack;
        const offset=Number(BigInt('0x'+s[s.length-(x.op==='CALL'?4:3)]));
        const size=Number(BigInt('0x'+s[s.length-(x.op==='CALL'?5:4)]));
        const memory=x.memory.join('');
        return {op:x.op,depth:x.depth,target:'0x'+s[s.length-2].slice(-40),value:x.op==='CALL'?'0x'+s[s.length-3]:'0x0',payload:'0x'+memory.slice(offset*2,(offset+size)*2)};
      });
      cases.push({name,success,before,after,calls,logs:receipt.logs.map(x=>({address:x.address,topics:x.topics,data:x.data}))});
    } finally { await backend.request({method:'evm_revert',params:[snapshot]}); }
  }
  const noop=async()=>{};
  await run('live queue spend and frame reset',noop,30n,2n,true,after=>{
    assert.equal(BigInt(after.storage.buffer),70n+30n*U128);
    assert.equal(BigInt(after.storage.next),30n+11n*U128);
    assert.equal(after.storage.reserve,'0');
    assert.equal(after.balances.lido,'70'); assert.equal(after.balances.router,'30');
  });
  await run('unauthorized caller',noop,30n,0n,false,()=>{},true);
  await run('zero amount',noop,0n,0n,false);
  await run('bunker',()=>send(queue.fixtureBunker(true)),30n,0n,false);
  await run('paused',()=>store('active',0n),30n,0n,false);
  await run('queue grows before spend',()=>send(queue.fixtureEnqueue(40n,40n,signer.address)),30n,0n,false);
  await run('oracle rejection after packed write',()=>configure(oracle,'getCurrentFrame()','0xdeadbeef',true),30n,0n,false);
  await run('short oracle result after packed write',()=>configure(oracle,'getCurrentFrame()','0x01'),30n,0n,false);
  await run('ETH recipient rejection after seed write',()=>configure(router,'receiveDepositableEther()','0xdeadbeef',true),30n,2n,false);
  await run('actual ETH balance insufficient',()=>backend.request({method:'evm_setAccountBalance',params:[addresses.lido,'0x01']}),30n,2n,false);
  await run('post report truncation',()=>store('buffer',(U128-1n)*U128+100n),30n,0n,true,after=>assert.equal(BigInt(after.storage.buffer),29n*U128+70n));
  await run('seed truncation',()=>store('seed',U128-1n),30n,1n,true,after=>assert.equal(after.storage.seed,'0'));
  async function queueAnswer(bytes) {
    await configure(locator,'withdrawalQueue()',encode(['address'],[addresses.oracle]));
    await configure(oracle,'isBunkerModeActive()',encode(['bool'],[false]));
    await configure(oracle,'unfinalizedStETH()',bytes);
  }
  await run('empty live queue result',()=>queueAnswer('0x'),30n,0n,false);
  await run('31 byte live queue result',()=>queueAnswer('0x'+'00'.repeat(31)),30n,0n,false);
  await run('extra live queue return bytes',()=>queueAnswer(encode(['uint256','uint256'],[50n,999n])),30n,0n,true);
  await run('uint256 seed add overflow after effects',()=>store('seed',1n),30n,(1n<<256n)-1n,false);
  await run('current frame nonce truncation',()=>configure(oracle,'getCurrentFrame()',encode(['uint256','uint256'],[U128+11n,123n])),30n,0n,true,after=>assert.equal(BigInt(after.storage.next),30n+11n*U128));
  fs.writeFileSync(path.resolve(__dirname,'../../audit/trio/reserve1/receipts/solidity-execution.json'),JSON.stringify({node:process.version,scope:'Pinned Solidity only; NOT differential/Verity correspondence. Full locator/oracle/router and bunker are fixture boundaries. Gas excluded.',addresses,cases},null,2)+'\n');
  console.log(`${cases.length} pinned Solidity cases executed; reverts checked against physical storage, balances and logs.`);
  await backend.disconnect();
}
main().catch(e=>{console.error(e);process.exitCode=1;});
