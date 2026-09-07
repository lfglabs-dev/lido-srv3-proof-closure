#!/usr/bin/env node
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process'),assert=require('node:assert/strict');
const solc=require('solc'),ganache=require('ganache'),{ethers}=require('ethers');
const root=path.resolve(__dirname,'../..'),out=process.argv[2];assert(out);fs.mkdirSync(out,{recursive:true});
const pin=cp.execFileSync('git',['-C',path.join(root,'lido-core'),'rev-parse','HEAD'],{encoding:'utf8'}).trim();assert.equal(pin,'17005714f151e5502c559932319a3f2f74ac2436');assert.match(solc.version(),/^0\.8\.25\+/);
const sources=Object.fromEntries(['Harness.sol','CallbackHarness.sol'].map(name=>[name,{content:fs.readFileSync(path.join(__dirname,name),'utf8')}]));
const settings={optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'shanghai',outputSelection:{'*':{'*':['abi','evm.bytecode.object']}}};
const compilation=JSON.parse(solc.compile(JSON.stringify({language:'Solidity',sources,settings}),{import:name=>{try{return {contents:fs.readFileSync(name.startsWith('@')?require.resolve(name):path.join(root,'lido-core',name),'utf8')}}catch(e){return {error:e.message}}}}));
const errors=(compilation.errors||[]).filter(x=>x.severity==='error');assert.equal(errors.length,0,errors.map(x=>x.formattedMessage).join('\n'));
const words=(...xs)=>ethers.AbiCoder.defaultAbiCoder().encode(xs.map(()=> 'uint256'),xs);
async function main(){const rpc=ganache.provider({logging:{quiet:true},chain:{hardfork:'shanghai'},wallet:{deterministic:true}});try{
 const provider=new ethers.BrowserProvider(rpc);provider.pollingInterval=10;const signer=await provider.getSigner();
 async function deploy(file,name,args=[]){const c=compilation.contracts[file][name];const h=await new ethers.ContractFactory(c.abi,c.evm.bytecode.object,signer).deploy(...args);await h.waitForDeployment();return h;}
 const h=await deploy('Harness.sol','CapacityHarness'),base=await h.routerSlot(),slot=BigInt(ethers.keccak256(words(7n,base)));
 const m=await deploy('CallbackHarness.sol','CallbackModule',[h.target,slot,base]);
 const packed=BigInt(m.target)+(10000n<<192n)+(1n<<232n);
 const write=async(s,v)=>await(await h.writeSlot(s,v)).wait();await write(base+1n,1n);await write(BigInt(ethers.keccak256(words(base+1n))),7n);await write(slot,packed);
 const read=async()=>rpc.request({method:'eth_getStorageAt',params:[h.target,ethers.toQuantity(slot),'latest']});const before=await read();
 const data=h.interface.encodeFunctionData('capacity',[[32,2048],10,false]);const result=h.interface.decodeFunctionResult('capacity',await provider.call({to:h.target,data})).map(x=>x.map(Number));assert.deepEqual(result,[[1],[3]]);
 const tx=await signer.sendTransaction({to:h.target,data,gasLimit:1000000});const receipt=await tx.wait();assert.equal(receipt.status,1);assert.equal(receipt.logs.length,0);const after=await read();assert.equal(after,before);
 const trace=await rpc.request({method:'debug_traceTransaction',params:[tx.hash,{}]});
 const calls=trace.structLogs.filter(x=>['CALL','STATICCALL'].includes(x.op)).map(x=>{const st=x.stack,offset=Number(BigInt('0x'+st.at(x.op==='CALL'?-4:-3))),length=Number(BigInt('0x'+st.at(x.op==='CALL'?-5:-4)));return {kind:x.op,depth:x.depth,target:'0x'+st.at(-2).slice(-40),payload:'0x'+x.memory.join('').slice(offset*2,(offset+length)*2)};});
 assert.deepEqual(calls.map(x=>x.kind),['STATICCALL','STATICCALL','CALL']);assert.equal(calls[0].target.toLowerCase(),m.target.toLowerCase());assert.equal(calls[1].target.toLowerCase(),h.target.toLowerCase());assert.equal(calls[2].target.toLowerCase(),h.target.toLowerCase());
 assert.equal(calls[0].payload,'0x9abddf09');assert.equal(calls[1].payload,h.interface.encodeFunctionData('routerSlot'));assert.equal(calls[2].payload,h.interface.encodeFunctionData('writeSlot',[slot,99]));
 fs.writeFileSync(path.join(out,'callback.json'),JSON.stringify({pin,compiler:solc.version(),settings,result,calls,before,after,events:receipt.logs,transaction:tx.hash,status:receipt.status,attemptedSstores:trace.structLogs.filter(x=>x.op==='SSTORE').length},null,2));
}finally{await rpc.disconnect();}}
main().catch(e=>{console.error(e);process.exitCode=1;});
