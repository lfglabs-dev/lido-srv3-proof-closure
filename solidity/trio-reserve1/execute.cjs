// Pinned Solidity execution and matching-input Lean/Verity differential probes.
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const assert = require('node:assert/strict');
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
const queueSlots = {
  last: ethers.id('lido.WithdrawalQueue.lastRequestId'),
  finalized: ethers.id('lido.WithdrawalQueue.lastFinalizedRequestId'),
  bunker: ethers.id('lido.WithdrawalQueue.bunkerModeSinceTimestamp'),
};
const queueMapping = ethers.id('lido.WithdrawalQueue.queue');
const decimal = x => BigInt(x).toString();
const bytes = x => Array.from(ethers.getBytes(x));
const coder = ethers.AbiCoder.defaultAbiCoder();
const selector = signature => ethers.id(signature).slice(0,10);
const encode = (types, values) => coder.encode(types, values);
const artifacts = name => JSON.parse(fs.readFileSync(path.join(__dirname,'artifacts',name+'.sol.json')));
const receiptDir = path.resolve(__dirname,'../../audit/trio/reserve1/receipts/router-composition');
async function main() {
  fs.mkdirSync(receiptDir,{recursive:true});
  process.env.HARDHAT_CONFIG = path.join(__dirname,'hardhat.config.cjs');
  const backend = require('hardhat').network.provider;
  const provider = new ethers.BrowserProvider(backend);
  provider.pollingInterval = 10;
  const signer = await provider.getSigner();
  async function deploy(file, name, args=[]) {
    const a = artifacts(file)[name];
    const c = await new ethers.ContractFactory(a.abi,a.evm.bytecode.object,signer).deploy(...args,{gasLimit:29000000});
    await c.waitForDeployment(); return c;
  }
  const lido = await deploy('LidoHarness','LidoHarness');
  const queue = await deploy('QueueHarness','QueueHarness');
  const locator = await deploy('LidoHarness','CallFixture');
  const router = await deploy('LidoHarness','CallFixture');
  const oracle = await deploy('LidoHarness','CallFixture');
  const routerArtifacts = JSON.parse(fs.readFileSync(path.join(__dirname,'artifacts','router-linked.json')));
  const libraries = new Map();
  async function deployLinked(file, name, args=[]) {
    const a = routerArtifacts[file][name];
    let bytecode = a.evm.bytecode.object;
    for (const [source, refs] of Object.entries(a.evm.bytecode.linkReferences)) {
      for (const [library, positions] of Object.entries(refs)) {
        const key = source+':'+library;
        if (!libraries.has(key)) libraries.set(key,await deployLinked(source,library));
        const address = (await libraries.get(key).getAddress()).slice(2);
        for (const p of positions) {
          assert.equal(p.length,20);
          bytecode = bytecode.slice(0,p.start*2)+address+bytecode.slice((p.start+p.length)*2);
        }
      }
    }
    const c = await new ethers.ContractFactory(a.abi,bytecode,signer).deploy(...args,{gasLimit:29000000});
    await c.waitForDeployment(); return c;
  }
  const sourceRouter = await deployLinked('solidity/trio-reserve1/RouterHarness.sol','RouterHarness',
    [await lido.getAddress(),await locator.getAddress()]);
  const wrongRouter = await deployLinked('solidity/trio-reserve1/RouterHarness.sol','RouterHarness',
    [await signer.getAddress(),await locator.getAddress()]);
  const addresses = {lido:await lido.getAddress(),queue:await queue.getAddress(),locator:await locator.getAddress(),router:await router.getAddress(),oracle:await oracle.getAddress()};
  addresses.sourceRouter = await sourceRouter.getAddress();
  addresses.wrongRouter = await wrongRouter.getAddress();
  const locatorConfig = Object.fromEntries(artifacts('LocatorHarness').LocatorHarness.abi
    .find(x=>x.type==='constructor').inputs[0].components.map(x=>[x.name,addresses.lido]));
  Object.assign(locatorConfig,{accountingOracle:addresses.oracle,stakingRouter:addresses.sourceRouter,
    withdrawalQueue:addresses.queue});
  const sourceLocator = await deploy('LocatorHarness','LocatorHarness',[locatorConfig]);
  addresses.sourceLocator = await sourceLocator.getAddress();
  const sourceLocators = [{locator:decimal(addresses.sourceLocator),queue:decimal(addresses.queue),
    router:decimal(addresses.sourceRouter),oracle:decimal(addresses.oracle)}];
  const sourceRouters = [
    {router:decimal(addresses.sourceRouter),lido:decimal(addresses.lido)},
    {router:decimal(addresses.wrongRouter),lido:decimal(await signer.getAddress())},
  ];
  const send = async tx => (await tx).wait();
  let fixtureRows = [];
  const configure = async (c, signature, data, reject=false) => {
    await send(c.configure(selector(signature),data,reject));
    const target = decimal(await c.getAddress()), payload = bytes(selector(signature));
    fixtureRows = fixtureRows.filter(f => !(f.target === target && JSON.stringify(f.payload) === JSON.stringify(payload)));
    fixtureRows.push({target,payload,returned:bytes(data),reject});
  };
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
  await backend.request({method:'hardhat_setBalance',params:[addresses.lido,ethers.toQuantity(100n)]});
  async function observe() {
    const storage = {};
    for (const [key, slot] of Object.entries(slots)) storage[key] = (await lido.fixtureLoad(slot)).toString();
    const balances = {};
    for (const key of ['lido','router','queue','sourceRouter','wrongRouter']) balances[key] = BigInt(await backend.request({method:'eth_getBalance',params:[addresses[key],'latest']})).toString();
    return {storage,balances};
  }
  const cases = [], vectors = [], expected = [];
  const rawCell = async (account, slot) => ({account:decimal(account),slot:decimal(slot),
    value:decimal((await backend.request({method:'eth_getStorageAt',params:[account,ethers.toBeHex(BigInt(slot),32),'latest']})).replace(/^0x$/, '0x0'))});
  async function input(name, amount, seeds, direct, forwarder) {
    const storage = [];
    for (const slot of Object.values(slots)) storage.push(await rawCell(addresses.lido,slot));
    for (const slot of Object.values(queueSlots)) storage.push(await rawCell(addresses.queue,slot));
    const hashes = [];
    for (const label of ['last','finalized']) {
      const id = (await rawCell(addresses.queue,queueSlots[label])).value;
      const preimage = encode(['uint256','bytes32'],[id,queueMapping]);
      const hash = ethers.keccak256(preimage);
      hashes.push({input:bytes(preimage),output:decimal(hash)});
      storage.push(await rawCell(addresses.queue,hash));
    }
    const balances = [], code = [];
    for (const account of Object.values(addresses)) {
      balances.push({account:decimal(account),value:decimal(await backend.request({method:'eth_getBalance',params:[account,'latest']}))});
      code.push({account:decimal(account),size:String(ethers.getBytes(await provider.getCode(account)).length)});
    }
    return {name,self:decimal(addresses.lido),sender:decimal(direct ? await signer.getAddress() : await forwarder.getAddress()),sourceRouters,sourceLocators,
      queue:decimal(addresses.queue),storage,balances,code,hashes,fixtures:structuredClone(fixtureRows),
      fixtureTargets:[addresses.locator,addresses.router,addresses.oracle].map(decimal),amount:String(amount),seeds:String(seeds)};
  }
  async function run(name, setup, amount, seeds, expectedSuccess, check=()=>{}, direct=false, forwarder=router) {
    const snapshot = await backend.request({method:'evm_snapshot',params:[]});
    const savedFixtures = structuredClone(fixtureRows);
    try {
      await setup();
      const before = await observe();
      const vector = await input(name,amount,seeds,direct,forwarder);
      vectors.push(vector);
      const payload = lido.interface.encodeFunctionData('withdrawDepositableEther',[amount,seeds]);
      let receipt;
      try {
        const tx = direct ? await signer.sendTransaction({to:addresses.lido,data:payload,gasLimit:5000000})
          : await forwarder.forward(addresses.lido,payload,{gasLimit:5000000});
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
      const lidoDepth = direct ? 1 : 2;
      const final = trace.structLogs.filter(x => x.depth === lidoDepth && ['RETURN','REVERT','STOP'].includes(x.op)).at(-1);
      let returned = [];
      if (final && final.op !== 'STOP') {
        const offset = Number(BigInt('0x'+final.stack.at(-1))), size = Number(BigInt('0x'+final.stack.at(-2)));
        returned = bytes('0x'+final.memory.join('').slice(offset*2,(offset+size)*2));
      }
      const actualStorage = [];
      for (const c of vector.storage) actualStorage.push(await rawCell(ethers.toBeHex(BigInt(c.account),20),c.slot));
      const actualBalances = [];
      for (const c of vector.balances) actualBalances.push({account:c.account,value:decimal(await backend.request({method:'eth_getBalance',params:[ethers.toBeHex(BigInt(c.account),20),'latest']}))});
      expected.push({name,success,returned,storage:actualStorage,balances:actualBalances,
        calls:calls.filter(c=>c.depth===lidoDepth).map(c=>({target:decimal(c.target),value:decimal(c.value),payload:bytes(c.payload)})),
        logs:receipt.logs.map(x=>({emitter:decimal(x.address),topics:x.topics.map(x=>x.toLowerCase()),data:x.data.toLowerCase()}))});
      cases.push({name,success,before,after,calls,logs:receipt.logs.map(x=>({address:x.address,topics:x.topics,data:x.data}))});
    } finally { await backend.request({method:'evm_revert',params:[snapshot]}); fixtureRows = savedFixtures; }
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
  await run('actual ETH balance insufficient',()=>backend.request({method:'hardhat_setBalance',params:[addresses.lido,'0x1']}),30n,2n,false);
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
  await run('reversed physical cumulative rows panic',()=>send(queue.fixtureStore(
    ethers.keccak256(encode(['uint256','bytes32'],[0n,queueMapping])),51n)),30n,0n,false);
  await run('queue finalization releases demand',()=>send(queue.fixtureFinalize(1n,50n,10n**27n)),100n,0n,true);
  await run('uint256 amount rejected',noop,(1n<<256n)-1n,0n,false);
  await run('noncanonical bunker bool is true',async()=>{
    await queueAnswer(encode(['uint256'],[50n]));
    await configure(oracle,'isBunkerModeActive()',encode(['uint256'],[2n]));
  },30n,0n,false);
  await run('paused still decodes bunker result',async()=>{
    await store('active',0n);
    await configure(locator,'withdrawalQueue()',encode(['address'],[addresses.oracle]));
    await configure(oracle,'isBunkerModeActive()','0x01');
  },30n,0n,false);
  await run('queue address has no code',()=>configure(locator,'withdrawalQueue()',encode(['address'],[ethers.ZeroAddress])),30n,0n,false);
  await run('uint256 live demand clamps',()=>queueAnswer(encode(['uint256'],[(1n<<256n)-1n])),20n,0n,true);
  await run('dirty address upper bits truncate',()=>configure(locator,'stakingRouter()',encode(['uint256'],[(1n<<200n)+BigInt(addresses.router)])),30n,0n,true);
  await run('same frame next accounting truncates',()=>store('next',11n*U128+U128-1n),30n,0n,true,
    after=>assert.equal(BigInt(after.storage.next),11n*U128+29n));
  await run('rebalance target above buffer then full spend',async()=>{
    await send(lido.fixtureSetTarget(200n));
    await send(lido.fixtureRebalance());
  },100n,0n,true,after=>{assert.equal(after.storage.reserve,'100');assert.equal(after.balances.lido,'0');});
  await run('lower target releases withdrawal protection',()=>send(lido.fixtureSetTarget(0n)),50n,0n,true);
  await run('second spend uses current queue and accounting',async()=>{
    await send(router.forward(addresses.lido,lido.interface.encodeFunctionData('withdrawDepositableEther',[20n,0n])));
    await send(queue.fixtureEnqueue(10n,10n,signer.address));
  },20n,0n,true,after=>assert.equal(BigInt(after.storage.next),11n*U128+40n));
  await run('source router receives ETH and emits event',
    ()=>configure(locator,'stakingRouter()',encode(['address'],[addresses.sourceRouter])),30n,2n,true,
    after=>{assert.equal(after.balances.lido,'70');assert.equal(after.balances.sourceRouter,'30');},false,sourceRouter);
  await run('source router immutable auth rejects after accounting and seed writes',
    ()=>configure(locator,'stakingRouter()',encode(['address'],[addresses.wrongRouter])),30n,2n,false,
    ()=>{},false,wrongRouter);
  await run('source router Lido admission rejects fixture caller',
    ()=>configure(locator,'stakingRouter()',encode(['address'],[addresses.sourceRouter])),30n,2n,false);
  await run('source locator queue and router compose',()=>store('locator',BigInt(addresses.sourceLocator)),
    30n,2n,true,after=>{assert.equal(after.balances.lido,'70');assert.equal(after.balances.sourceRouter,'30');},false,sourceRouter);
  await run('source locator queue growth blocks overspend',async()=>{
    await store('locator',BigInt(addresses.sourceLocator));
    await send(queue.fixtureEnqueue(40n,40n,signer.address));
  },30n,2n,false,()=>{},false,sourceRouter);
  await run('source locator caller authorization',()=>store('locator',BigInt(addresses.sourceLocator)),
    30n,2n,false);
  fs.writeFileSync(path.join(receiptDir,'solidity-execution.json'),JSON.stringify({node:process.version,backend:'hardhat 2.26.3 in-process Cancun',scope:'Pinned Solidity with matching Lean/Verity execution. Three cases compose source immutable locator, live queue and router. Oracle and adversarial boundaries remain fixtures. Inherited router receiver/auth/event. Gas excluded; tests are not correspondence proofs.',addresses,locatorConfig,libraries:[...libraries.keys()],cases},null,2)+'\n');
  console.log(`${cases.length} pinned Solidity cases executed; reverts checked against physical storage, balances and logs.`);
  fs.writeFileSync(path.join(receiptDir,'differential-input.json'),JSON.stringify(vectors,null,2)+'\n');
  fs.writeFileSync(path.join(receiptDir,'differential-solidity.json'),JSON.stringify(expected,null,2)+'\n');
  cp.execFileSync('lake',['env','lean','--run','LidoSRv3/Tests/TrioReserve1/Differential.lean',
    path.join(receiptDir,'differential-input.json'),path.join(receiptDir,'differential-verity.json')],
    {cwd:path.resolve(__dirname,'../..'),stdio:'inherit'});
  const actual = JSON.parse(fs.readFileSync(path.join(receiptDir,'differential-verity.json')));
  function normalize(r) {
    const f = r.result.fault;
    const returned = !f || f.kind === 'empty' ? [] : f.kind === 'bubbled' ? f.data :
      bytes(ethers.concat(['0x08c379a0',encode(['string'],[f.reason])]));
    return {name:r.name,success:r.result.success,returned,storage:r.storage,balances:r.balances,calls:r.calls,
      logs:r.logs.map(l=> {
        const iface = l.name === 'DepositableEthReceived' ? sourceRouter.interface : lido.interface;
        const event = iface.getEvent(l.name);
        const encoded = iface.encodeEventLog(event,l.values);
        return {emitter:l.emitter,topics:encoded.topics.map(x=>x.toLowerCase()),data:encoded.data.toLowerCase()};
      })};
  }
  const results = actual.map((r,i)=> {
    assert.deepEqual(normalize(r),expected[i],r.name+' Solidity/Verity mismatch');
    return {name:r.name,matched:true};
  });
  fs.writeFileSync(path.join(receiptDir,'differential-comparison.json'),JSON.stringify({
    scope:'Matching finite boundary fixtures; not a universal correspondence proof. Root return/revert bytes, relevant storage/balances, ordered calls and ABI logs.',results},null,2)+'\n');
  const mutationInputs = [
    {...vectors.find(v=>v.name==='queue grows before spend'),mutation:'cached-demand'},
    {...vectors.find(v=>v.name==='oracle rejection after packed write'),mutation:'omit-rollback'},
    {...vectors.find(v=>v.name==='source router immutable auth rejects after accounting and seed writes'),mutation:'receiver-no-auth'},
    {...vectors.find(v=>v.name==='source router receives ETH and emits event'),mutation:'receiver-no-event'},
  ];
  fs.writeFileSync(path.join(receiptDir,'mutation-input.json'),JSON.stringify(mutationInputs,null,2)+'\n');
  cp.execFileSync('lake',['env','lean','--run','LidoSRv3/Tests/TrioReserve1/Differential.lean',
    path.join(receiptDir,'mutation-input.json'),path.join(receiptDir,'mutation-verity.json')],
    {cwd:path.resolve(__dirname,'../..'),stdio:'inherit'});
  const mutants = JSON.parse(fs.readFileSync(path.join(receiptDir,'mutation-verity.json')));
  const kills = mutants.map((r,i)=> {
    const wanted = expected.find(e=>e.name===r.name);
    assert.notDeepEqual(normalize(r),wanted,mutationInputs[i].mutation+' survived');
    return {name:r.name,mutation:mutationInputs[i].mutation,killed:true};
  });
  fs.writeFileSync(path.join(receiptDir,'mutation-comparison.json'),JSON.stringify(kills,null,2)+'\n');
  console.log(`${results.length} matching Solidity/Verity cases passed; ${kills.length} executed mutants rejected.`);
}
main().catch(e=>{console.error(e);process.exitCode=1;});
