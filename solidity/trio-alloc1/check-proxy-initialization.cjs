#!/usr/bin/env node
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const assert=require('node:assert/strict'),solc=require('./compiler-receipt.cjs')(require('solc')),ganache=require('./evm-backend.cjs');
const {ethers}=require('ethers');
const root=path.resolve(__dirname,'../..'),out=process.argv[2],proxyTools=process.argv[3];
assert(out&&proxyTools,'output and exact proxy dependency directory required');fs.mkdirSync(out,{recursive:true});
const proxySolc=require('./compiler-receipt.cjs')(require(path.join(path.resolve(proxyTools),'node_modules/solc')));
assert.match(solc.version(),/^0\.8\.25\+/);assert.match(proxySolc.version(),/^0\.8\.9\+/);
const pin=cp.execFileSync('git',['-C',path.join(root,'lido-core'),'rev-parse','HEAD'],{encoding:'utf8'}).trim();assert.equal(pin,'17005714f151e5502c559932319a3f2f74ac2436');
const routerFile='contracts/0.8.25/sr/StakingRouter.sol',proxyFile='contracts/0.8.9/proxy/OssifiableProxy.sol';
function compile(compiler,file,settings,dependencyRoot){
 const sources={};function read(name){const actual=name.startsWith('@')?require.resolve(name,{paths:[dependencyRoot]}):path.join(root,'lido-core',name);const contents=fs.readFileSync(actual,'utf8');sources[name]=contents;return {contents};}
 const result=JSON.parse(compiler.compile(JSON.stringify({language:'Solidity',sources:{[file]:{content:read(file).contents}},settings}),{import:name=>{try{return read(name);}catch(e){return {error:e.message};}}}));
 const errors=(result.errors||[]).filter(x=>x.severity==='error');assert.equal(errors.length,0,errors.map(x=>x.formattedMessage).join('\n'));
 return {result,sources,compiler:compiler.version(),settings};
}
const outputs={'*':{'*':['abi','evm.bytecode']}};
const routerBuild=compile(solc,routerFile,{optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:process.env.ALLOC1_EVM || 'shanghai',outputSelection:outputs},path.dirname(require.resolve('solc')));
const proxyBuild=compile(proxySolc,proxyFile,{optimizer:{enabled:true,runs:200},evmVersion:process.env.ALLOC1_EVM === 'cancun' ? 'istanbul' : 'london',outputSelection:outputs},path.resolve(proxyTools));
const hash=value=>require('node:crypto').createHash('sha256').update(value).digest('hex');
const identities=build=>({compiler:build.compiler,settings:build.settings,sources:Object.fromEntries(Object.entries(build.sources).map(([name,text])=>[name,hash(text)]))});
const words=(...xs)=>ethers.AbiCoder.defaultAbiCoder().encode(xs.map(()=> 'uint256'),xs);
async function main(){
 const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai',allowUnlimitedContractSize:true},wallet:{deterministic:true}});
 try{
 const provider=new ethers.BrowserProvider(rpc);provider.pollingInterval=10;const signer=await provider.getSigner(),caller=await signer.getAddress(),deployed={};
 async function deploy(build,file,name,args=[]){const key=file+':'+name;if(deployed[key])return deployed[key];const c=build.result.contracts[file][name];let code=c.evm.bytecode.object;
 for(const [lf,libs] of Object.entries(c.evm.bytecode.linkReferences||{}))for(const [ln,refs] of Object.entries(libs)){const address=(await(await deploy(build,lf,ln)).getAddress()).slice(2);for(const ref of refs)code=code.slice(0,ref.start*2)+address+code.slice((ref.start+ref.length)*2);}
 const contract=await new ethers.ContractFactory(c.abi,code,signer).deploy(...args,{gasLimit:29000000});await contract.waitForDeployment();deployed[key]=contract;return contract;}
 const implementation=await deploy(routerBuild,routerFile,'StakingRouter',[ethers.toBeHex(1,20),ethers.toBeHex(2,20),ethers.toBeHex(3,20),32,2048]);
 const initWC=(1n<<248n)|32n,initData=implementation.interface.encodeFunctionData('initialize',[caller,ethers.toBeHex(initWC,32),42]);
 const proxy=await deploy(proxyBuild,proxyFile,'OssifiableProxy',[await implementation.getAddress(),caller,initData]);
 const address=await proxy.getAddress(),router=new ethers.Contract(address,routerBuild.result.contracts[routerFile].StakingRouter.abi,signer);
 const read=async(at,slot)=>{const raw=await rpc.request({method:'eth_getStorageAt',params:[at,ethers.toBeHex(slot),'latest']});return raw==='0x'?0n:BigInt(raw);};
 const base=BigInt(ethers.keccak256(words(BigInt(ethers.id('lido.StakingRouter.routerStorage'))-1n)))&~255n;
 const initSlot=BigInt('0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00');
 const implSlot=BigInt(ethers.id('eip1967.proxy.implementation'))-1n,adminSlot=BigInt(ethers.id('eip1967.proxy.admin'))-1n;
 assert.equal(await read(await implementation.getAddress(),initSlot),(1n<<64n)-1n);
 assert.equal(await read(address,initSlot),4n);assert.equal(await read(address,implSlot),BigInt(await implementation.getAddress()));assert.equal(await read(address,adminSlot),BigInt(caller));
 assert.equal(await read(address,base+1n),0n);assert.equal(await read(address,base+4n),initWC);assert.equal(await read(address,base+5n),42n<<24n);
 assert.equal(await router.hasRole(ethers.ZeroHash,caller),true);
 const initialized=(await proxy.deploymentTransaction().wait()).logs.map(x=>({topics:x.topics,data:x.data}));
 const manage=ethers.id('STAKING_MODULE_MANAGE_ROLE'),share=ethers.id('STAKING_MODULE_SHARE_MANAGE_ROLE');
 await(await router.grantRole(manage,caller,{gasLimit:1000000})).wait();await(await router.grantRole(share,caller,{gasLimit:1000000})).wait();
 const config={stakeShareLimit:5000,priorityExitShareThreshold:7000,stakingModuleFee:0,treasuryFee:0,maxDepositsPerBlock:10,minDepositBlockDistance:1,withdrawalCredentialsType:1};
 for(const id of [1,2])await(await router.addStakingModule('module'+id,ethers.toBeHex(40+id,20),config,{gasLimit:1000000})).wait();
 await(await router.updateModuleShares(1,3000,7000,{gasLimit:1000000})).wait();await(await router.setStakingModuleStatus(1,1,{gasLimit:1000000})).wait();
 assert.equal(await read(address,base+1n),2n);
 const array=BigInt(ethers.keccak256(words(base+1n))),rows=[];
 for(let i=0;i<2;i++){const id=await read(address,array+BigInt(i)),packed=await read(address,BigInt(ethers.keccak256(words(id,base))));assert.equal(id,BigInt(i+1));assert.equal(packed&((1n<<160n)-1n),BigInt(41+i));assert.equal((packed>>192n)&65535n,i===0?3000n:5000n);rows.push({id:id.toString(),packed:ethers.toBeHex(packed,32)});}
 let duplicate;try{await router.addStakingModule.staticCall('duplicate',ethers.toBeHex(41,20),config);assert.fail('expected duplicate rejection');}catch(e){duplicate=e.data;}
 assert.equal(duplicate,ethers.id('StakingModuleAddressExists()').slice(0,10));
 fs.writeFileSync(path.join(out,'proxy-initialization.json'),JSON.stringify({pin,routerBuild:identities(routerBuild),proxyBuild:identities(proxyBuild),scope:'Actual pinned proxy constructor and router initialization, followed only by public role/admission/share/status calls; no test storage seeding',implementation:await implementation.getAddress(),proxy:address,caller,initialized,finalCount:2,rows,duplicateRevert:duplicate},null,2));
 }finally{await rpc.disconnect();}
}
main().catch(e=>{console.error(e);process.exitCode=1;});
