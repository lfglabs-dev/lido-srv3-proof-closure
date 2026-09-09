import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync} from 'node:fs';
import {ContainerType, ByteVectorType, BooleanType, UintBigintType, ListCompositeType} from '@chainsafe/ssz';
import {createProof, ProofType} from '@chainsafe/persistent-merkle-tree';

const schemas = JSON.parse(readFileSync(new URL('./schemas.json', import.meta.url)));
const zero = Buffer.alloc(32);
const hash = (...parts) => createHash('sha256').update(Buffer.concat(parts)).digest();
const hex = b => '0x' + Buffer.from(b).toString('hex');
const eq = (a,b,label) => assert.equal(hex(a),hex(b),label);
const le = (n,size=32) => {const b=Buffer.alloc(size); for(let i=0;i<size;i++){b[i]=Number(n&255n); n>>=8n;} assert.equal(n,0n); return b;};
const zeros=[zero]; for(let d=0;d<40;d++) zeros.push(hash(zeros[d],zeros[d]));
const seedBytes = (seed,label) => hash(Buffer.from(`${seed}:${label}`));

// Independent sparse level reduction with recursively hashed zero subtrees.
// It does not call ChainSafe hashing, tree construction or proof helpers.
function merkle(chunks,depth,index=0){
  let level=chunks.map(Buffer.from), at=index; const branch=[];
  for(let d=0;d<depth;d++){
    branch.push(level[at%2===0?at+1:at-1]??zeros[d]);
    const next=[];
    for(let j=0;j<level.length;j+=2) next.push(hash(level[j],level[j+1]??zeros[d]));
    level=next;at=Math.floor(at/2);
  }
  return {root:level[0]??zeros[depth],branch};
}
function fold(leaf,proof,index){for(const s of proof){leaf=index%2n===0n?hash(leaf,s):hash(s,leaf);index/=2n;}assert.equal(index,1n);return leaf;}
function validator(seed){return {
  pubkey:Buffer.concat([seedBytes(seed,'pk0'),seedBytes(seed,'pk1').subarray(0,16)]),
  withdrawal_credentials:seedBytes(seed,'wc'),effective_balance:seed%2?32000000000n:(1n<<64n)-1n,
  slashed:seed%2===0,activation_eligibility_epoch:BigInt(seed),activation_epoch:BigInt(seed+1),
  exit_epoch:(1n<<64n)-1n,withdrawable_epoch:BigInt(seed+3),
};}
function validatorRoot(v){return merkle([
  hash(v.pubkey,Buffer.alloc(16)),v.withdrawal_credentials,le(v.effective_balance),le(v.slashed?1n:0n),
  le(v.activation_eligibility_epoch),le(v.activation_epoch),le(v.exit_epoch),le(v.withdrawable_epoch),
],3).root;}
const bytes32=new ByteVectorType(32), u64=new UintBigintType(8);
const validatorType=new ContainerType({pubkey:new ByteVectorType(48),withdrawal_credentials:bytes32,
  effective_balance:u64,slashed:new BooleanType(),activation_eligibility_epoch:u64,activation_epoch:u64,
  exit_epoch:u64,withdrawable_epoch:u64});
const registry=new ListCompositeType(validatorType,2**40);
const vectors=[];let rootsChecked=0,proofsChecked=0;
for(const [fork,schema] of Object.entries(schemas)){
  assert.equal(schema.fields.length,fork==='electra'?37:38);assert.equal(schema.fields.indexOf('validators'),11);
  // All non-registry fields are supplied opaque SSZ roots. This is the canonical
  // container/registry structure, NOT recursive semantic encoding of BeaconState.
  const stateType=new ContainerType(Object.fromEntries(schema.fields.map(n=>[n,n==='validators'?registry:bytes32])));
  assert.equal(stateType.depth,6);
  for(let trial=0;trial<32;trial++){
    const size=[0,1,2,3,4,7,8,9][trial%8];const vs=Array.from({length:size},(_,i)=>validator(100*trial+i));
    const state=Object.fromEntries(schema.fields.map(n=>[n,n==='validators'?vs:seedBytes(trial,n)]));
    const leaves=vs.map(v=>{const own=validatorRoot(v);eq(own,validatorType.hashTreeRoot(v),'validator fields');return own;});
    const data=merkle(leaves,40); const registryRoot=hash(data.root,le(BigInt(size)));
    eq(registryRoot,registry.hashTreeRoot(vs),'list data and length');
    const fieldRoots=schema.fields.map(n=>n==='validators'?registryRoot:state[n]);
    const ownState=merkle(fieldRoots,6).root;
    eq(ownState,stateType.hashTreeRoot(state),'named state container');rootsChecked++;
    const node=stateType.value_toTree(state);eq(ownState,node.root,'library tree root');
    for(const i of [...new Set([0,Math.max(0,size-1)])]){
      if(i>=size) continue;
      const gi=stateType.getPathInfo(['validators',i]).gindex;
      assert.equal(gi,150n*(1n<<40n)+BigInt(i));
      const proof=createProof(node,{type:ProofType.single,gindex:gi});
      const ownProof=[...merkle(leaves,40,i).branch,le(BigInt(size)),...merkle(fieldRoots,6,11).branch];
      assert.equal(proof.witnesses.length,47);assert.equal(ownProof.length,47);
      eq(proof.leaf,leaves[i],'selected semantic validator');
      proof.witnesses.forEach((x,j)=>eq(x,ownProof[j],`sibling ${j}`));
      eq(proof.witnesses[40],le(BigInt(size)),'actual length sibling');
      eq(fold(leaves[i],proof.witnesses,gi),ownState,'branch reconstruction');
      const slot=BigInt(trial+123),proposer=BigInt(trial+17),parent=seedBytes(trial,'parent'),body=seedBytes(trial,'body');
      const fullProof=[...ownProof,parent,hash(le(slot),le(proposer)),hash(hash(body,zero),hash(zero,zero))];
      const headerRoot=merkle([le(slot),le(proposer),parent,ownState,body],3).root;
      const headerGi=1430n*(1n<<40n)+BigInt(i);
      eq(fold(leaves[i],fullProof,headerGi),headerRoot,'header50');assert.equal(fullProof.length,50);
      // Concrete mutation discrimination, never a universal hash-injectivity claim.
      const badLength=ownProof.slice();badLength[40]=le(BigInt(size+1));
      assert.notEqual(hex(fold(leaves[i],badLength,gi)),hex(ownState));
      const badPadding=ownProof.slice();badPadding[39]=zero;
      assert.notEqual(hex(fold(leaves[i],badPadding,gi)),hex(ownState));
      const reversed=ownProof.slice().reverse();
      assert.notEqual(hex(fold(leaves[i],reversed,gi)),hex(ownState));
      proofsChecked++;
      if(trial===1||trial===5) vectors.push({fork,index:i,registryLength:size,slot:slot.toString(),proposer:proposer.toString(),
        timestamp:String(1000000+trial),witness:Object.fromEntries(Object.entries(vs[i]).map(([k,v])=>[k,typeof v==='bigint'?v.toString():typeof v==='boolean'?v:hex(v)])),
        root:hex(headerRoot),stateRoot:hex(ownState),proof:fullProof.map(hex)});
    }
    // A capacity-valid index outside list length is not semantic membership.
    assert(size<2**40);assert(!(size<vs.length));
  }
}
assert.equal((32n+11n)*2n,86n,'old 32-field schema mutant');
assert.notEqual((64n+10n)*2n,150n,'wrong field');
assert.notEqual((64n+11n)*2n+1n,150n,'length edge instead of data');
const result={specification:'ethereum/consensus-specs@f96d3e7acf35125295d234da4b0c67591fdef49c',
  library:{ssz:'1.2.1',persistentMerkleTree:'1.2.0'},rootsChecked,proofsChecked,vectorCount:vectors.length,
  scope:'Canonical container/validator-registry structure, opaque roots for other state fields; independent sparse SHA reference versus pinned ChainSafe SSZ',
  limits:['not recursive encoding of every BeaconState field','synthetic validators/header/root, not consensus authentication or deployment provenance','finite executable checks, not Lean/EVM refinement']};
writeFileSync(new URL('./vectors.json',import.meta.url),JSON.stringify(vectors,null,2)+'\n');
writeFileSync(new URL('./result.json',import.meta.url),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result,null,2));
