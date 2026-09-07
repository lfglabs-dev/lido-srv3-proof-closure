import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import solc from 'solc';
import ganache from 'ganache';
import {AbiCoder, BrowserProvider, ContractFactory, Interface} from 'ethers';

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, '../..');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const pin = '17005714f151e5502c559932319a3f2f74ac2436';
if (!process.argv[2]) throw new Error('usage: node differential.mjs <successful Lean receipt.json>');
const receiptPath = resolve(process.argv[2]);
const receipt = JSON.parse(readFileSync(receiptPath));
assert.equal(receipt.state, 'succeeded');
assert.equal(receipt.exit_code, 0);
assert.equal(receipt.validation.toolchain, 'leanprover/lean4:v4.31.0');
const identityPath = resolve(root, 'audit/trio/alloc2/differential-source-identity.json');
const identity = JSON.parse(readFileSync(identityPath));
let manifest = 'sandboxed-source-bundle-v1\n';
for (const path of Object.keys(identity).sort()) {
  assert.match(path, /^(LidoSRv3\/(Audit\/Source|Tests)\/TrioAlloc2\/[^/]+\.lean|audit\/trio\/alloc2\/lakefile\.lean)$/);
  assert.equal(sha(readFileSync(resolve(root, path))), identity[path], `stale Lean source: ${path}`);
  manifest += `${path}\0${identity[path]}\n`;
}
const manifestHash = sha(manifest);
assert.ok(new RegExp(`^source bundle verified sha256=${manifestHash}(?: operations_sha256=[0-9a-f]{64})? files=${Object.keys(identity).length} `, 'm').test(receipt.log_tail),
  'source identity does not match verified remote overlay');
const vectorLine = /^(?:info: \.\.\/\.\.\/\.\.\/LidoSRv3\/Tests\/TrioAlloc2\/DifferentialVectors\.lean:\d+:\d+: )?ALLOC2_VECTOR (.+)$/;
const vectors = receipt.log_tail.split('\n').map(line => line.match(vectorLine))
  .filter(Boolean).map(match => JSON.parse(match[1]));
assert.equal(vectors.length, 32, 'missing/truncated Lean execution output');
assert.equal(new Set(vectors.map(v => v.name)).size, 32);

let abiEvidence = null;
let abiVectors = [];
if (process.argv[3]) {
  const abiReceiptPath = resolve(process.argv[3]);
  const abiReceipt = JSON.parse(readFileSync(abiReceiptPath));
  assert.equal(abiReceipt.state, 'succeeded');
  assert.equal(abiReceipt.exit_code, 0);
  assert.equal(abiReceipt.validation.toolchain, 'leanprover/lean4:v4.31.0');
  const abiIdentity = JSON.parse(readFileSync(resolve(root, 'audit/trio/alloc2/composition/source-identity.json')));
  for (const path of ['audit/trio/alloc2/composition/LibraryABI.lean',
    'audit/trio/alloc2/composition/LibraryABIVectors.lean', 'LidoSRv3/Audit/Source/TrioAlloc1/Bytes.lean']) {
    assert.ok(Object.hasOwn(abiIdentity.files, path), `missing ABI source: ${path}`);
  }
  assert.match(abiIdentity.producer, /^[0-9a-f]{40}$/);
  let abiManifest = 'sandboxed-source-bundle-v1\n';
  for (const path of Object.keys(abiIdentity.files).sort()) {
    assert.match(path, /^(LidoSRv3\/Audit\/Source\/TrioAlloc[12]\/[^/]+\.lean|audit\/trio\/alloc2\/composition\/[^/]+\.lean)$/);
    const bytes = path.startsWith('LidoSRv3/Audit/Source/TrioAlloc1/')
      ? execFileSync('git', ['-C', root, 'show', `${abiIdentity.producer}:${path}`])
      : readFileSync(resolve(root, path));
    assert.equal(sha(bytes), abiIdentity.files[path], `stale ABI source: ${path}`);
    abiManifest += `${path}\0${abiIdentity.files[path]}\n`;
  }
  const abiManifestHash = sha(abiManifest);
  assert.ok(new RegExp(`^source bundle verified sha256=${abiManifestHash}(?: operations_sha256=[0-9a-f]{64})? files=${Object.keys(abiIdentity.files).length} `, 'm').test(abiReceipt.log_tail),
    'ABI source identity does not match verified remote overlay');
  abiVectors = abiReceipt.log_tail.split('\n').map(line => line.match(/(?:^|: )ALLOC2_ABI_VECTOR (.+)$/))
    .filter(Boolean).map(match => JSON.parse(match[1]));
  assert.equal(abiVectors.length, 11, 'missing/truncated byte-model executions');
  assert.equal(new Set(abiVectors.map(v => v.name)).size, 11);
  abiEvidence = {job: abiReceipt.job_id, producer: abiIdentity.producer, overlay: abiManifestHash,
    receiptSha256: sha(readFileSync(abiReceiptPath)), vectors: abiVectors.length};
}

const sources = {};
const sourceHashes = {};
for (const path of ['contracts/common/lib/MinFirstAllocationStrategy.sol', 'contracts/common/lib/Math256.sol']) {
  const content = execFileSync('git', ['-C', resolve(root, 'lido-core'), 'show', `${pin}:${path}`]);
  assert.deepEqual(readFileSync(resolve(root, 'lido-core', path)), content, `dirty pinned source: ${path}`);
  sources[path] = {content: content.toString()};
  sourceHashes[path] = sha(content);
}
sources['Harness.sol'] = {content: readFileSync(resolve(here, 'Harness.sol'), 'utf8')};
sourceHashes['Harness.sol'] = sha(sources['Harness.sol'].content);
assert.match(solc.version(), /^0\.8\.9\+commit\.e5eed63a\./);
const settings = {
  optimizer: {enabled: true, runs: 200}, evmVersion: 'istanbul',
  outputSelection: {'*': {'*': ['abi', 'evm.bytecode', 'evm.deployedBytecode']}}
};
const compilerInput = JSON.stringify({language: 'Solidity', sources, settings});
const compiled = JSON.parse(solc.compile(compilerInput));
assert.deepEqual((compiled.errors ?? []).filter(e => e.severity === 'error'), []);
const library = compiled.contracts['contracts/common/lib/MinFirstAllocationStrategy.sol'].MinFirstAllocationStrategy;
const harness = compiled.contracts['Harness.sol'].Alloc2Harness;
const vm = ganache.provider({logging: {quiet: true}, chain: {hardfork: 'istanbul', chainId: 1337},
  wallet: {deterministic: true, totalAccounts: 1}, miner: {blockGasLimit: 30000000}});
const provider = new BrowserProvider(vm);
const signer = await provider.getSigner();
const coder = AbiCoder.defaultAbiCoder();
const panic = code => '0x4e487b71' + coder.encode(['uint256'], [code]).slice(2);
const results = [];
try {
  const libraryContract = await new ContractFactory(library.abi, library.evm.bytecode.object, signer).deploy();
  await libraryContract.waitForDeployment();
  const libraryAddress = await libraryContract.getAddress();
  let linked = harness.evm.bytecode.object;
  for (const [file, libraries] of Object.entries(harness.evm.bytecode.linkReferences)) {
    for (const [name, refs] of Object.entries(libraries)) {
      assert.equal(file, 'contracts/common/lib/MinFirstAllocationStrategy.sol');
      assert.equal(name, 'MinFirstAllocationStrategy');
      for (const {start, length} of refs) {
        assert.equal(length, 20);
        linked = linked.slice(0, start * 2) + libraryAddress.slice(2).toLowerCase() + linked.slice((start + length) * 2);
      }
    }
  }
  assert.match(linked, /^[0-9a-f]+$/i);
  const instance = await new ContractFactory(harness.abi, linked, signer).deploy();
  await instance.waitForDeployment();
  const target = await instance.getAddress();
  const iface = new Interface(harness.abi);
  const libraryIface = new Interface(library.abi);
  async function call(name, data, expected, to = target, expectRevert = false) {
    let actual, reverted = false;
    try { actual = await vm.request({method: 'eth_call', params: [{to, data, gas: '0x1c9c380'}, 'latest']}); }
    catch (error) {
      reverted = true;
      actual = typeof error.data === 'string' ? error.data : error.data?.result;
      if (typeof actual !== 'string') throw error;
    }
    assert.equal(reverted, expectRevert, `${name}: return/revert mismatch`);
    assert.equal(actual.toLowerCase(), expected.toLowerCase(), `${name}: exact ABI bytes differ`);
    results.push({name, calldata: data, reverted, returndata: actual});
  }
  for (const vector of vectors) {
    const args = [vector.buckets, vector.capacities, vector.demand];
    for (const entry of ['step', 'run']) {
      const out = vector[entry];
      const failed = Object.hasOwn(out, 'panic');
      const expected = failed ? panic(out.panic) : entry === 'step'
        ? coder.encode(['uint256', 'uint256[]'], [out.amount, out.buckets])
        : coder.encode(['uint256', 'uint256[]', 'uint256[]'], [out.amount, out.buckets, vector.buckets]);
      await call(`${vector.name}:${entry}`, iface.encodeFunctionData(entry, args), expected, target, failed);
    }
    const out = vector.run;
    const failed = Object.hasOwn(out, 'panic');
    await call(`${vector.name}:direct-library`, libraryIface.encodeFunctionData('allocate', args),
      failed ? panic(out.panic) : coder.encode(['uint256', 'uint256[]'], [out.amount, out.buckets]), libraryAddress, failed);
  }
  for (const vector of abiVectors) {
    assert.match(vector.arguments, /^0x(?:[0-9a-f]{2})*$/);
    assert.match(vector.data, /^0x(?:[0-9a-f]{2})*$/);
    assert.equal(typeof vector.reverted, 'boolean');
    await call(`byte-model:${vector.name}`, libraryIface.getFunction('allocate').selector + vector.arguments.slice(2),
      vector.data, libraryAddress, vector.reverted);
  }
  const max = (1n << 256n) - 1n;
  for (const [a, b, expected] of [[0n, 0n, 0n], [1n, 0n, null], [max, 1n, max], [max, max, 1n], [31n, 2n, 16n]]) {
    await call(`ceil:${a}:${b}`, iface.encodeFunctionData('ceil', [a, b]),
      expected === null ? panic(18) : coder.encode(['uint256'], [expected]), target, expected === null);
  }
  const encoded = iface.encodeFunctionData('run', [[7], [], 0]);
  await call('malformed:selector-only-zero-demand', encoded.slice(0, 10), '0x', target, true);
  await call('malformed:truncated-row-zero-demand', encoded.slice(0, -64), '0x', target, true);
  const hugeOffset = encoded.slice(0, 10) + max.toString(16).padStart(64, '0') + encoded.slice(74);
  await call('malformed:offset-overflow-zero-demand', hugeOffset, '0x', target, true);
  await call('malformed:unknown-selector', '0xffffffff', '0x', target, true);
  const record = {
    scope: 'pinned Solidity EVM vs executed decoded Lean; not Verity runtime or full parent correspondence',
    leanJob: receipt.job_id, leanOverlay: manifestHash, leanReceiptSha256: sha(readFileSync(receiptPath)),
    abiEvidence,
    compiler: solc.version(), compilerInputSha256: sha(compilerInput), settings, solidityPin: pin, sourceHashes,
    runnerSha256: sha(readFileSync(fileURLToPath(import.meta.url))),
    packageLockSha256: sha(readFileSync(resolve(here, 'package-lock.json'))),
    libraryCreationBytecodeSha256: sha(library.evm.bytecode.object), linkedHarnessBytecodeSha256: sha(linked),
    tests: results.length, results
  };
  writeFileSync(resolve(root, 'audit/trio/alloc2/solidity-execution.json'), JSON.stringify(record, null, 2) + '\n');
  console.log(`PASS: ${results.length} exact return/revert byte comparisons; 32 decoded and ${abiVectors.length} byte-model Lean vectors; caller-copy boundary checked`);
} finally {
  provider.destroy();
  await vm.disconnect();
}
