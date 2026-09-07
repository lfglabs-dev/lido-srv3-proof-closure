#!/usr/bin/env node
const fs=require('node:fs');
const path=require('node:path');
const cp=require('node:child_process');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
const {mutations}=require('./mutations.cjs');
const root=path.resolve(__dirname,'../../..');
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');
assert.ok(process.argv[2],'successful composition receipt required');
const receipt=path.resolve(process.argv[2]);
const results=[];
for(const [name,mutation] of Object.entries(mutations)) {
  const artifact=path.join(root,`audit/trio/alloc2/parent-mutant-${name}.json`);
  fs.rmSync(artifact,{force:true});
  const execution=cp.spawnSync(process.execPath,[path.join(__dirname,'run.cjs'),receipt,'--mutant='+name],
    {cwd:root,encoding:'utf8',maxBuffer:4*1024*1024});
  assert.equal(execution.signal,null,name+' terminated by signal');
  assert.equal(execution.status,1,name+' must be rejected');
  assert.ok(execution.stderr.includes('AssertionError'),name+' must fail a semantic assertion');
  const expected=mutation.test+' return/revert bytes';
  assert.ok(execution.stderr.includes(expected),name+' failed for the wrong reason: '+execution.stderr);
  const data=JSON.parse(fs.readFileSync(artifact));
  assert.equal(data.mutation.name,name);
  assert.equal(data.receipts.length,1);
  assert.equal(data.receipts[0].name,mutation.test);
  assert.equal(Object.keys(data.mutation.mutatedSources).length,1);
  if(mutation.frame) {
    const row=data.receipts[0];
    assert.equal(row.reverted,false,'swallowed failure returned success');
    assert.equal(BigInt(row.after.storage[0]),42n,'swallowed failure committed the prior storage');
    assert.equal(BigInt(row.after.balances[0]),BigInt(row.before.balances[0])-1n);
    assert.equal(BigInt(row.after.balances.at(-1)),BigInt(row.before.balances.at(-1))+1n);
    assert.equal(row.events.length,1,'swallowed failure committed the prior event');
  }
  results.push({name,test:mutation.test,rejection:expected,artifact:path.relative(root,artifact),artifactSha256:sha(fs.readFileSync(artifact))});
  console.log('REJECTED '+name+' by '+expected);
}
fs.writeFileSync(path.join(root,'audit/trio/alloc2/parent-mutation-execution.json'),JSON.stringify({
  scope:'six actual Solidity mutants rejected by the parent differential; finite tests, not universal correctness',
  receiptSha256:sha(fs.readFileSync(receipt)),runnerSha256:sha(fs.readFileSync(__filename)),
  mutationsSha256:sha(fs.readFileSync(path.join(__dirname,'mutations.cjs'))),results},null,2)+'\n');
