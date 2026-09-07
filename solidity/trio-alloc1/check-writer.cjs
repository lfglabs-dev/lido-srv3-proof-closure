#!/usr/bin/env node
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const assert=require('node:assert/strict'), solc=require('solc'),ganache=require('ganache');
const {ethers}=require('ethers');
const root=path.resolve(__dirname,'../..'),out=process.argv[2];
assert(out,'output directory required');fs.mkdirSync(out,{recursive:true});
const pin=cp.execFileSync('git',['-C',path.join(root,'lido-core'),'rev-parse','HEAD'],{encoding:'utf8'}).trim();
assert.equal(pin,'17005714f151e5502c559932319a3f2f74ac2436');assert.match(solc.version(),/^0\.8\.25\+/);
const settings={optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'shanghai',outputSelection:{'*':{'*':['abi','evm.bytecode','irOptimized']}}};
const compilation=JSON.parse(solc.compile(JSON.stringify({language:'Solidity',sources:{'WriterHarness.sol':{content:fs.readFileSync(path.join(__dirname,'WriterHarness.sol'),'utf8')}},settings}),{import:name=>{try{return {contents:fs.readFileSync(name.startsWith('@')?require.resolve(name):path.join(root,'lido-core',name),'utf8')}}catch(e){return {error:e.message}}}}));
const errors=(compilation.errors||[]).filter(x=>x.severity==='error');assert.equal(errors.length,0,errors.map(x=>x.formattedMessage).join('\n'));
fs.writeFileSync(path.join(out,'writer.ir'),compilation.contracts['WriterHarness.sol'].WriterHarness.irOptimized);
fs.writeFileSync(path.join(out,'library.ir'),compilation.contracts['contracts/0.8.25/sr/SRLib.sol'].SRLib.irOptimized);
const words=(...xs)=>ethers.AbiCoder.defaultAbiCoder().encode(xs.map(()=> 'uint256'),xs);
async function main(){
 const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai',allowUnlimitedContractSize:true},wallet:{deterministic:true}});
 try{
 const provider=new ethers.BrowserProvider(rpc);provider.pollingInterval=10;const signer=await provider.getSigner();const deployed={};
 async function deploy(file,name){const key=file+':'+name;if(deployed[key])return deployed[key];const c=compilation.contracts[file][name];let code=c.evm.bytecode.object;
 for(const [lf,libs] of Object.entries(c.evm.bytecode.linkReferences||{}))for(const [ln,refs]of Object.entries(libs)){const addr=(await(await deploy(lf,ln)).getAddress()).slice(2);for(const ref of refs)code=code.slice(0,ref.start*2)+addr+code.slice((ref.start+ref.length)*2);}
 const contract=await new ethers.ContractFactory(c.abi,code,signer).deploy();await contract.waitForDeployment();return deployed[key]=contract;}
 const h=await deploy('WriterHarness.sol','WriterHarness'),address=await h.getAddress(),caller=await signer.getAddress();
 const base=BigInt(ethers.keccak256(words(BigInt(ethers.id('lido.StakingRouter.routerStorage'))-1n)))&~255n;
 const role=ethers.id('STAKING_MODULE_SHARE_MANAGE_ROLE');
 const acl=BigInt('0x02dd7bc7dec4dceedda775e58dd541e08a116c6c53815c0bd028192f7b626800');
 const member=BigInt(ethers.keccak256(words(BigInt(caller),BigInt(ethers.keccak256(words(BigInt(role),acl))))));
 const slot=BigInt(ethers.keccak256(words(7n,base))),position=BigInt(ethers.keccak256(words(7n,base+2n)));
 const write=async(s,v)=>await(await h.writeSlot(s,v,{gasLimit:1000000})).wait();const read=async s=>{const raw=await rpc.request({method:'eth_getStorageAt',params:[address,ethers.toBeHex(s),'latest']});return raw==='0x'?0n:BigInt(raw||'0x0');};
 const original=(0xabcdefn<<232n)|(2n<<224n)|(9999n<<208n)|(9000n<<192n)|(0x12345678n<<160n)|21n;
 await write(slot,original);await write(position,1n);await write(member,1n);
 const tx=await h.updateModuleShares(7,5000,7000),receipt=await tx.wait();const actual=await read(slot);
 const expected=(original&~(((1n<<32n)-1n)<<192n))|(5000n<<192n)|(7000n<<208n);
 fs.writeFileSync(path.join(out,'writer.json'),JSON.stringify({pin,compiler:solc.version(),settings,original:ethers.toBeHex(original,32),actual:ethers.toBeHex(actual,32),expected:ethers.toBeHex(expected,32),events:receipt.logs.map(x=>({topics:x.topics,data:x.data})),matches:actual===expected},null,2));
 assert.equal(actual,expected,'packed writer preserves every other bit');
 assert.equal(receipt.logs.length,1);assert.deepEqual([...receipt.logs[0].topics],[ethers.id('StakingModuleShareLimitSet(uint256,uint256,uint256,address)'),ethers.toBeHex(7n,32)]);
 assert.equal(receipt.logs[0].data,words(5000,7000,BigInt(caller)));
 const selector=sig=>ethers.id(sig).slice(0,10);
 const cases=[
  {name:'role-before-membership-and-share',role:0n,position:0n,share:65535,threshold:0,packed:original,error:selector('AccessControlUnauthorizedAccount(address,bytes32)')+words(BigInt(caller),BigInt(role)).slice(2)},
  {name:'membership-before-share',role:1n,position:0n,share:65535,threshold:0,packed:original,error:selector('StakingModuleUnregistered()')},
  {name:'share-before-threshold-and-enum',role:1n,position:1n,share:10001,threshold:10001,packed:original|(255n<<224n),error:selector('InvalidStakeShareLimit()')},
  {name:'threshold-before-enum',role:1n,position:1n,share:1,threshold:10001,packed:original|(255n<<224n),error:selector('InvalidPriorityExitShareThreshold()')},
  {name:'share-exceeds-threshold',role:1n,position:1n,share:2,threshold:1,packed:original,error:selector('InvalidPriorityExitShareThreshold()')},
  {name:'enum-after-validation',role:1n,position:1n,share:1,threshold:2,packed:original|(255n<<224n),error:'0x4e487b71'+words(33).slice(2)}
 ];
 const checks=[];
 for(const test of cases){
  await write(member,test.role);await write(position,test.position);await write(slot,test.packed);
  let data;try{await h.updateModuleShares.staticCall(7,test.share,test.threshold);assert.fail('expected revert');}catch(e){data=e.data;}
  assert.equal(data,test.error,test.name+' raw revert');
  let failed;try{await(await h.updateModuleShares(7,test.share,test.threshold,{gasLimit:1000000})).wait();assert.fail('expected failed transaction');}catch(e){failed=e.receipt;}
  assert(failed);assert.equal(failed.status,0);assert.equal(failed.logs.length,0);assert.equal(await read(slot),test.packed);
  checks.push({name:test.name,revert:data,status:failed.status,events:failed.logs.length,storageUnchanged:true});
 }
 fs.writeFileSync(path.join(out,'writer-errors.json'),JSON.stringify({pin,compiler:solc.version(),checks},null,2));
 const manageRole=ethers.id('STAKING_MODULE_MANAGE_ROLE');
 const manageMember=BigInt(ethers.keccak256(words(BigInt(caller),BigInt(ethers.keccak256(words(BigInt(manageRole),acl))))));
 const arrayBase=BigInt(ethers.keccak256(words(base+1n)));
 const config={stakeShareLimit:5000,priorityExitShareThreshold:7000,stakingModuleFee:0,treasuryFee:0,maxDepositsPerBlock:10,minDepositBlockDistance:1,withdrawalCredentialsType:1};
 const moduleAddress=ethers.getAddress(ethers.toBeHex(41,20));
 const admissionCases=[
  {name:'admission-role-first',role:0n,address:ethers.ZeroAddress,nameValue:'',error:selector('AccessControlUnauthorizedAccount(address,bytes32)')+words(BigInt(caller),BigInt(manageRole)).slice(2)},
  {name:'address-before-name',address:ethers.ZeroAddress,nameValue:'',error:selector('ZeroAddress()')},
  {name:'name-before-count',nameValue:'',count:32n,error:selector('StakingModuleWrongName()')},
  {name:'long-name',nameValue:'x'.repeat(32),error:selector('StakingModuleWrongName()')},
  {name:'count-before-wc',count:32n,config:{withdrawalCredentialsType:3},error:selector('StakingModulesLimitExceeded()')},
  {name:'wc-before-duplicate',duplicate:true,config:{withdrawalCredentialsType:3},error:selector('WrongWithdrawalCredentialsType()')},
  {name:'duplicate-before-params',duplicate:true,config:{stakeShareLimit:10001},error:selector('StakingModuleAddressExists()')},
  {name:'last-id-uint24-overflow',lastId:(1n<<24n)-1n,error:'0x4e487b71'+words(17).slice(2)},
  {name:'late-share-rollback',config:{stakeShareLimit:10001},late:true,error:selector('InvalidStakeShareLimit()')},
  {name:'late-threshold-rollback',config:{priorityExitShareThreshold:10001},late:true,error:selector('InvalidPriorityExitShareThreshold()')},
  {name:'late-fee-overflow-rollback',config:{stakingModuleFee:ethers.MaxUint256,treasuryFee:1},late:true,error:'0x4e487b71'+words(17).slice(2)},
  {name:'late-fee-sum-rollback',config:{stakingModuleFee:10001},late:true,error:selector('InvalidFeeSum()')},
  {name:'late-min-distance-rollback',config:{minDepositBlockDistance:0},late:true,error:selector('InvalidMinDepositBlockDistance()')},
  {name:'late-max-deposits-rollback',config:{maxDepositsPerBlock:0},late:true,error:selector('InvalidMaxDepositPerBlockValue()')}
 ];
 const admissionChecks=[];
 for(const test of admissionCases){
  await write(manageMember,test.role??1n);await write(base+1n,test.count??(test.duplicate?1n:0n));await write(base+5n,test.lastId??0n);
  await write(arrayBase,7n);await write(slot,BigInt(moduleAddress));
  const args=[test.nameValue??'module',test.address??moduleAddress,{...config,...test.config}];
  let data;try{await h.addStakingModule.staticCall(...args);assert.fail('expected admission revert');}catch(e){data=e.data;}
  assert.equal(data,test.error,test.name+' raw revert');
  let failed;try{await(await h.addStakingModule(...args,{gasLimit:2000000})).wait();assert.fail('expected admission transaction revert');}catch(e){failed=e.receipt;}
  assert(failed);assert.equal(failed.status,0);assert.equal(failed.logs.length,0);
  const trace=await rpc.request({method:'debug_traceTransaction',params:[failed.hash,{disableMemory:true,disableStorage:true}]});
  const touched=[...new Set(trace.structLogs.filter(x=>x.op==='SSTORE').map(x=>ethers.toBeHex(BigInt('0x'+x.stack.at(-1)))))];
  if(test.late)assert(touched.length>0,test.name+' must execute writes before revert');
  for(const key of touched){
   const before=await rpc.request({method:'eth_getStorageAt',params:[address,key,ethers.toQuantity(failed.blockNumber-1)]});
   const after=await rpc.request({method:'eth_getStorageAt',params:[address,key,ethers.toQuantity(failed.blockNumber)]});
   assert.equal(after,before,test.name+' rollback at '+key);
  }
  admissionChecks.push({name:test.name,revert:data,status:failed.status,events:0,attemptedStorageSlots:touched,allAttemptedSlotsRestored:true});
 }
 await write(manageMember,1n);await write(base+1n,0n);await write(base+5n,0n);
 const admitted=await(await h.addStakingModule('module',moduleAddress,config)).wait();
 const newSlot=BigInt(ethers.keccak256(words(1n,base))),newPosition=BigInt(ethers.keccak256(words(1n,base+2n)));
 assert.equal(await read(base+1n),1n);assert.equal(await read(arrayBase),1n);assert.equal(await read(newPosition),1n);
 assert.equal((await read(base+5n))&((1n<<24n)-1n),1n);
 assert.equal(await read(newSlot),BigInt(moduleAddress)|(5000n<<192n)|(7000n<<208n)|(1n<<232n));
 admissionChecks.push({name:'successful-first-admission',status:admitted.status,count:1,id:1,position:1,packedConfig:ethers.toBeHex(await read(newSlot),32),events:admitted.logs.map(x=>({topics:x.topics,data:x.data}))});
 fs.writeFileSync(path.join(out,'admission.json'),JSON.stringify({pin,compiler:solc.version(),checks:admissionChecks},null,2));
 const parameterChecks=[];
 const parameterCases=[
  {name:'parameter-role-first',role:0n,position:0n,args:[10001,0,0,0,0,0],error:selector('AccessControlUnauthorizedAccount(address,bytes32)')+words(BigInt(caller),BigInt(manageRole)).slice(2)},
  {name:'parameter-membership-first',position:0n,args:[10001,0,0,0,0,0],error:selector('StakingModuleUnregistered()')},
  {name:'parameter-share-before-fees',args:[10001,0,ethers.MaxUint256,1,0,0],error:selector('InvalidStakeShareLimit()')},
  {name:'parameter-fees-before-distance',args:[1,2,1,0,1,0],error:selector('InconsistentFeeSum()')},
  {name:'parameter-other-enum-before-fees',other:255n<<224n,args:[1,2,1,0,1,0],error:'0x4e487b71'+words(33).slice(2)},
  {name:'parameter-distance-before-target-enum',target:255n<<224n,args:[1,2,0,0,1,0],error:selector('InvalidMinDepositBlockDistance()')},
  {name:'parameter-target-enum-last',target:255n<<224n,args:[1,2,0,0,1,1],error:'0x4e487b71'+words(33).slice(2)}
 ];
 for(const test of parameterCases){
  await write(manageMember,test.role??1n);await write(newPosition,test.position??1n);
  await write(base+1n,2n);await write(arrayBase,1n);await write(arrayBase+1n,7n);
  await write(slot,test.other??0n);await write(newSlot,test.target??BigInt(moduleAddress));
  let data;try{await h.updateStakingModule.staticCall(1,...test.args);assert.fail('expected parameter revert');}catch(e){data=e.data;}
  assert.equal(data,test.error,test.name);
  const before=await read(newSlot);let failed;
  try{await(await h.updateStakingModule(1,...test.args,{gasLimit:1000000})).wait();assert.fail('expected parameter transaction revert');}catch(e){failed=e.receipt;}
  assert(failed);assert.equal(failed.status,0);assert.equal(failed.logs.length,0);assert.equal(await read(newSlot),before);
  const trace=await rpc.request({method:'debug_traceTransaction',params:[failed.hash,{disableMemory:true,disableStorage:true}]});
  assert.equal(trace.structLogs.filter(x=>x.op==='SSTORE').length,0,test.name+' validation precedes writes');
  parameterChecks.push({name:test.name,revert:data,status:0,events:0,attemptedWrites:0});
 }
 await write(manageMember,1n);await write(newPosition,1n);await write(base+1n,1n);
 const configBefore=(0xabcdn<<240n)|BigInt(moduleAddress),depositsBefore=0x123456789abcdef123456789abcdefn;
 await write(newSlot,configBefore);await write(newSlot+1n,depositsBefore);
 const updated=await(await h.updateStakingModule(1,4000,6000,100,200,11,3)).wait();
 const configAfter=configBefore|(100n<<160n)|(200n<<176n)|(4000n<<192n)|(6000n<<208n);
 const depositsAfter=depositsBefore|(11n<<128n)|(3n<<192n);
 assert.equal(await read(newSlot),configAfter);assert.equal(await read(newSlot+1n),depositsAfter);
 const expectedEvents=[['StakingModuleShareLimitSet(uint256,uint256,uint256,address)',[4000,6000]],['StakingModuleFeesSet(uint256,uint256,uint256,address)',[100,200]],['StakingModuleMaxDepositsPerBlockSet(uint256,uint256,address)',[11]],['StakingModuleMinDepositBlockDistanceSet(uint256,uint256,address)',[3]]];
 assert.equal(updated.logs.length,4);
 updated.logs.forEach((log,i)=>{assert.deepEqual([...log.topics],[ethers.id(expectedEvents[i][0]),ethers.toBeHex(1,32)]);assert.equal(log.data,words(...expectedEvents[i][1],BigInt(caller)));});
 parameterChecks.push({name:'parameter-success-packed-storage-and-events',status:1,config:ethers.toBeHex(configAfter,32),deposits:ethers.toBeHex(depositsAfter,32),events:updated.logs.map(x=>({topics:x.topics,data:x.data}))});
 fs.writeFileSync(path.join(out,'parameters.json'),JSON.stringify({pin,compiler:solc.version(),checks:parameterChecks},null,2));
 const nameSlot=newSlot+3n,nameData=BigInt(ethers.keccak256(words(nameSlot)));
 await write(base+1n,0n);await write(base+5n,0n);await write(newPosition,0n);await write(nameSlot,64n);
 let malformed;try{await h.addStakingModule.staticCall('module',moduleAddress,config);assert.fail('expected malformed storage name');}catch(e){malformed=e.data;}
 assert.equal(malformed,'0x4e487b71'+words(34).slice(2));
 await write(nameSlot,65n);await write(nameData,0xdeadn);
 const renamed=await(await h.addStakingModule('module',moduleAddress,config)).wait();
 const nameWord=BigInt(ethers.hexlify(ethers.toUtf8Bytes('module')))<<208n|12n;
 assert.equal(await read(nameSlot),nameWord);assert.equal(await read(nameData),0n);
 const block=await provider.getBlock(renamed.blockNumber),depositWord=await read(newSlot+1n);
 assert.equal(depositWord&((1n<<64n)-1n),BigInt(block.timestamp));
 assert.equal((depositWord>>64n)&((1n<<64n)-1n),BigInt(renamed.blockNumber));
 assert.equal(renamed.logs.length,6);
 assert.equal(renamed.logs[0].data,ethers.AbiCoder.defaultAbiCoder().encode(['address','string','address'],[moduleAddress,'module',caller]));
 assert.deepEqual([...renamed.logs[5].topics],[ethers.id('StakingRouterETHDeposited(uint256,uint256)'),ethers.toBeHex(1,32)]);
 assert.equal(renamed.logs[5].data,words(0));
 fs.writeFileSync(path.join(out,'admission-name.json'),JSON.stringify({pin,compiler:solc.version(),malformedOldNameRevert:malformed,longNameDataCleared:true,shortNameWord:ethers.toBeHex(nameWord,32),depositWord:ethers.toBeHex(depositWord,32),timestamp:block.timestamp,blockNumber:renamed.blockNumber,events:renamed.logs.map(x=>({topics:x.topics,data:x.data}))},null,2));
 const boundary=1n<<64n,insertId=19n,insertPosition=BigInt(ethers.keccak256(words(insertId,base+2n)));
 await write(base+1n,boundary);await write(insertPosition,0n);
 let oversized;try{await h.insertModuleId.staticCall(insertId);assert.fail('expected storage array push limit');}catch(e){oversized=e.data;}
 assert.equal(oversized,'0x4e487b71'+words(65).slice(2));
 await write(insertPosition,1n);await(await h.insertModuleId(insertId,{gasLimit:1000000})).wait();
 assert.equal(await read(base+1n),boundary);assert.equal(await read(insertPosition),1n);
 await write(insertPosition,0n);await write(base+1n,boundary-1n);
 await h.insertModuleId.staticCall(insertId);
 await(await h.insertModuleId(insertId,{gasLimit:1000000})).wait();
 assert.equal(await read(base+1n),boundary);assert.equal(await read(insertPosition),boundary);
 assert.equal(await read((arrayBase+boundary-1n)&ethers.MaxUint256),insertId);
 fs.writeFileSync(path.join(out,'enumeration-boundary.json'),JSON.stringify({pin,compiler:solc.version(),oversizedRevert:oversized,existingIdNoop:true,lastPermittedLength:(boundary-1n).toString(),resultingLength:boundary.toString(),elementAndPositionMatch:true},null,2));
 const statusCases=[
  {name:'status-role-before-member-and-enum',role:0n,position:0n,packed:original|(255n<<224n),error:selector('AccessControlUnauthorizedAccount(address,bytes32)')+words(BigInt(caller),BigInt(manageRole)).slice(2)},
  {name:'status-member-before-enum',role:1n,position:0n,packed:original|(255n<<224n),error:selector('StakingModuleUnregistered()')},
  {name:'status-invalid-stored-enum',role:1n,position:1n,packed:original|(255n<<224n),error:'0x4e487b71'+words(33).slice(2)},
  {name:'status-unchanged-rejects',role:1n,position:1n,packed:original,error:selector('StakingModuleStatusTheSame()')}
 ];
 const statusChecks=[];
 for(const test of statusCases){
  await write(manageMember,test.role);await write(position,test.position);await write(slot,test.packed);
  let raw;try{await h.setStakingModuleStatus.staticCall(7,2);assert.fail('expected status rejection');}catch(e){raw=e.data;}
  assert.equal(raw,test.error,test.name);
  let failed;try{await(await h.setStakingModuleStatus(7,2,{gasLimit:1000000})).wait();assert.fail('expected failed status transaction');}catch(e){failed=e.receipt;}
  assert(failed);assert.equal(failed.status,0);assert.equal(failed.logs.length,0);assert.equal(await read(slot),test.packed);
  statusChecks.push({name:test.name,revert:raw,storageUnchanged:true,events:0});
 }
 await write(manageMember,1n);await write(position,1n);await write(slot,original);
 const statusReceipt=await(await h.setStakingModuleStatus(7,1,{gasLimit:1000000})).wait();
 const statusExpected=(original&~(255n<<224n))|(1n<<224n);
 assert.equal(await read(slot),statusExpected);assert.equal(statusReceipt.logs.length,1);
 assert.deepEqual([...statusReceipt.logs[0].topics],[ethers.id('StakingModuleStatusSet(uint256,uint8,address)'),ethers.toBeHex(7,32)]);
 assert.equal(statusReceipt.logs[0].data,words(1,BigInt(caller)));
 fs.writeFileSync(path.join(out,'status.json'),JSON.stringify({pin,compiler:solc.version(),checks:statusChecks,original:ethers.toBeHex(original,32),expected:ethers.toBeHex(statusExpected,32),actual:ethers.toBeHex(await read(slot),32),events:statusReceipt.logs.map(x=>({topics:x.topics,data:x.data}))},null,2));
 const grantRole=ethers.id('ALLOC1_TEST_ROLE'),grantAccount=ethers.getAddress(ethers.toBeHex(23n,20));
 const grantRoot=BigInt(ethers.keccak256(words(BigInt(grantRole),acl)));
 const grantMember=BigInt(ethers.keccak256(words(23n,grantRoot)));
 const adminMember=BigInt(ethers.keccak256(words(BigInt(caller),BigInt(ethers.keccak256(words(0n,acl))))));
 const enumerableRoot=BigInt('0xc1f6fe24621ce81ec5827caf0253cadb74709b061630e6b55e82371705932000');
 const grantSet=BigInt(ethers.keccak256(words(BigInt(grantRole),enumerableRoot)));
 const grantPosition=BigInt(ethers.keccak256(words(23n,grantSet+1n))),grantArray=BigInt(ethers.keccak256(words(grantSet)));
 await write(grantRoot+1n,0n);await write(adminMember,0n);await write(grantMember,0n);
 let unauthorizedGrant;try{await h.grantRole.staticCall(grantRole,grantAccount);assert.fail('expected missing role admin');}catch(e){unauthorizedGrant=e.data;}
 assert.equal(unauthorizedGrant,selector('AccessControlUnauthorizedAccount(address,bytes32)')+words(BigInt(caller),0n).slice(2));
 await write(adminMember,1n);await write(grantSet,1n<<64n);await write(grantPosition,0n);
 let oversizedGrant;try{await h.grantRole.staticCall(grantRole,grantAccount);assert.fail('expected ACL array push panic');}catch(e){oversizedGrant=e.data;}
 assert.equal(oversizedGrant,'0x4e487b71'+words(65).slice(2));
 let failedGrant;try{await(await h.grantRole(grantRole,grantAccount,{gasLimit:1000000})).wait();assert.fail('expected ACL transaction failure');}catch(e){failedGrant=e.receipt;}
 assert(failedGrant);assert.equal(failedGrant.logs.length,0);assert.equal(await read(grantMember),0n);assert.equal(await read(grantSet),1n<<64n);
 const grantTrace=await rpc.request({method:'debug_traceTransaction',params:[failedGrant.hash,{}]});
 assert(grantTrace.structLogs.some(x=>x.op==='SSTORE'),'bool write precedes set insertion failure');
 await write(grantMember,1n);const noopGrant=await(await h.grantRole(grantRole,grantAccount,{gasLimit:1000000})).wait();
 assert.equal(noopGrant.logs.length,0);assert.equal(await read(grantSet),1n<<64n);
 await write(grantMember,0xabcdef00n);await write(grantPosition,1n);
 const presentPositionGrant=await(await h.grantRole(grantRole,grantAccount,{gasLimit:1000000})).wait();
 assert.equal(await read(grantMember),0xabcdef01n);assert.equal(await read(grantSet),1n<<64n);assert.equal(presentPositionGrant.logs.length,1);
 await write(grantMember,0xabcdef00n);await write(grantPosition,0n);await write(grantSet,0n);
 const addedGrant=await(await h.grantRole(grantRole,grantAccount,{gasLimit:1000000})).wait();
 assert.equal(await read(grantMember),0xabcdef01n);assert.equal(await read(grantSet),1n);assert.equal(await read(grantPosition),1n);assert.equal(await read(grantArray),23n);
 assert.equal(addedGrant.logs.length,1);assert.deepEqual([...addedGrant.logs[0].topics],[ethers.id('RoleGranted(bytes32,address,address)'),grantRole,ethers.toBeHex(23n,32),ethers.toBeHex(BigInt(caller),32)]);assert.equal(addedGrant.logs[0].data,'0x');
 fs.writeFileSync(path.join(out,'acl.json'),JSON.stringify({pin,compiler:solc.version(),unauthorizedGrant,oversizedGrant,boolWriteAttemptedBeforePanic:true,panicRestoresBoolAndEvents:true,presentBoolNoop:true,presentPositionNoopAfterBoolWrite:true,successfulPackedBool:ethers.toBeHex(await read(grantMember),32),count:1,position:1,element:23,events:addedGrant.logs.map(x=>({topics:x.topics,data:x.data}))},null,2));
 const initSlot=BigInt('0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00');
 const initAdmin=ethers.getAddress(ethers.toBeHex(29n,20)),initWC=(1n<<248n)|32n;
 const initMember=BigInt(ethers.keccak256(words(29n,BigInt(ethers.keccak256(words(0n,acl))))));
 const initSet=BigInt(ethers.keccak256(words(0n,enumerableRoot))),initPosition=BigInt(ethers.keccak256(words(29n,initSet+1n)));
 const initArray=BigInt(ethers.keccak256(words(initSet))),initReserved=0xabcdefn<<72n;
 const initCases=[
  {name:'initializing-before-zero-admin',versionWord:initReserved|(1n<<64n),admin:ethers.ZeroAddress,wc:initWC,cap:42n,error:selector('InvalidInitialization()')},
  {name:'version-four-before-zero-admin',versionWord:initReserved|4n,admin:ethers.ZeroAddress,wc:initWC,cap:42n,error:selector('InvalidInitialization()')},
  {name:'zero-admin',versionWord:initReserved,admin:ethers.ZeroAddress,wc:initWC,cap:42n,error:selector('ZeroAddress()')},
  {name:'zero-wc-address-after-grant',versionWord:initReserved,admin:initAdmin,wc:1n<<248n,cap:42n,error:selector('ZeroAddress()')},
  {name:'invalid-wc-type-after-grant',versionWord:initReserved,admin:initAdmin,wc:32n,cap:42n,error:selector('WrongWithdrawalCredentialsType()')},
  {name:'invalid-cap-after-credentials',versionWord:initReserved,admin:initAdmin,wc:initWC,cap:0n,error:selector('InvalidMaxTopUpPerBlockGwei()')}
 ];
 const initChecks=[];
 for(const test of initCases){
  await write(initSlot,test.versionWord);await write(base+1n,0n);await write(initMember,0n);await write(initSet,0n);await write(initPosition,0n);await write(initArray,0n);await write(base+4n,0n);await write(base+5n,0n);
  let raw;try{await h.initialize.staticCall(test.admin,ethers.toBeHex(test.wc,32),test.cap);assert.fail('expected initialization rejection');}catch(e){raw=e.data;}
  assert.equal(raw,test.error,test.name);
  let failed;try{await(await h.initialize(test.admin,ethers.toBeHex(test.wc,32),test.cap,{gasLimit:1000000})).wait();assert.fail('expected initialization failure');}catch(e){failed=e.receipt;}
  assert(failed);assert.equal(failed.logs.length,0);assert.equal(await read(initSlot),test.versionWord);
  for(const target of [initMember,initSet,initPosition,initArray,base+4n,base+5n])assert.equal(await read(target),0n,test.name+' rollback');
  const trace=await rpc.request({method:'debug_traceTransaction',params:[failed.hash,{}]});
  initChecks.push({name:test.name,revert:raw,attemptedWrites:trace.structLogs.filter(x=>x.op==='SSTORE').length,storageRestored:true,events:0});
 }
 await write(initSlot,initReserved);
 const initialized=await(await h.initialize(initAdmin,ethers.toBeHex(initWC,32),42,{gasLimit:1000000})).wait();
 assert.equal(await read(initSlot),initReserved|4n);assert.equal(await read(initMember),1n);assert.equal(await read(initSet),1n);assert.equal(await read(initPosition),1n);assert.equal(await read(initArray),29n);assert.equal(await read(base+4n),initWC);assert.equal(await read(base+5n),42n<<24n);
 assert.equal(initialized.logs.length,4);
 assert.deepEqual(initialized.logs.map(x=>x.topics[0]),['RoleGranted(bytes32,address,address)','WithdrawalCredentialsSet(bytes32,address)','MaxTopUpPerBlockGweiSet(uint256,address)','Initialized(uint64)'].map(ethers.id));
 assert.equal(initialized.logs[3].data,words(4));
 fs.writeFileSync(path.join(out,'initialization.json'),JSON.stringify({pin,compiler:solc.version(),scope:'Actual inherited initialize from adversarial test-written storage, not proxy deployment',checks:initChecks,initializedWord:ethers.toBeHex(await read(initSlot),32),adminGranted:true,zeroModuleCount:true,credentials:ethers.toBeHex(initWC,32),capWord:ethers.toBeHex(await read(base+5n),32),events:initialized.logs.map(x=>({topics:x.topics,data:x.data}))},null,2));
 }finally{await rpc.disconnect();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
