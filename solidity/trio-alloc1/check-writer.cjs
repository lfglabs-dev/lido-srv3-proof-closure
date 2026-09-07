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
 const write=async(s,v)=>await(await h.writeSlot(s,v)).wait();const read=async s=>BigInt(await rpc.request({method:'eth_getStorageAt',params:[address,ethers.toBeHex(s),'latest']})||'0x0');
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
 }finally{await rpc.disconnect();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
