#!/usr/bin/env node
const fs=require('node:fs');
const path=require('node:path');
const solc=require('solc');
const assert=require('node:assert/strict');
const cp=require('node:child_process');
const root=path.resolve(__dirname,'../..');
assert.equal(cp.execFileSync('git',['-C',path.join(root,'lido-core'),'rev-parse','HEAD'],{encoding:'utf8'}).trim(),
  '17005714f151e5502c559932319a3f2f74ac2436');
assert.match(solc.version(),/^0\.8\.25\+/);
const src='pragma solidity 0.8.25; import {RouterState} from "contracts/0.8.25/sr/SRTypes.sol"; contract LayoutWitness { RouterState internal router; }';
const result=JSON.parse(solc.compile(JSON.stringify({language:'Solidity',sources:{'Layout.sol':{content:src}},settings:{outputSelection:{'*':{'*':['storageLayout']}}}}),{
 import:name=>({contents:fs.readFileSync(name.startsWith('@')?require.resolve(name):path.join(root,'lido-core',name),'utf8')})
}));
assert.equal((result.errors||[]).filter(x=>x.severity==='error').length,0);
const layout=result.contracts['Layout.sol'].LayoutWitness.storageLayout;
const type=(id)=>layout.types[id];
const rootType=type(layout.storage[0].type);
const members=t=>t.members.map(m=>[m.label,m.slot,m.offset]);
assert.deepEqual(members(rootType),[
 ['moduleStates','0',0],['moduleIds','1',0],['accounting','3',0],['withdrawalCredentials','4',0],['lastModuleId','5',0],['maxTopUpPerBlockGwei','5',3]]);
const moduleType=type(type(rootType.members[0].type).value);
assert.deepEqual(members(moduleType),[['config','0',0],['deposits','1',0],['accounting','2',0],['name','3',0]]);
const config=type(moduleType.members[0].type);
assert.deepEqual(members(config),[['moduleAddress','0',0],['moduleFee','0',20],['treasuryFee','0',22],['stakeShareLimit','0',24],['priorityExitShareThreshold','0',26],['status','0',28],['withdrawalCredentialsType','0',29]]);
const accounting=type(moduleType.members[2].type);
assert.deepEqual(members(accounting),[['validatorsBalanceGwei','0',0],['exitedValidatorsCount','0',8]]);
const set=type(type(rootType.members[1].type).members[0].type);
assert.deepEqual(members(set),[['_values','0',0],['_positions','1',0]]);
const report={compiler:solc.version(),classification:'PINNED_COMPILER_LAYOUT_PASS',layout};
if(!process.argv[2])throw new Error('output file required');
fs.writeFileSync(process.argv[2],JSON.stringify(report,null,2)+'\n');
console.log('PASS pinned RouterState, EnumerableSet, ModuleState, packed config and accounting layout');
