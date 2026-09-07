// Independent Solidity/byte-slice checks. This does not replace decoder-copy.cjs,
// whose Lean receipt is still mandatory for the Lean/Solidity differential gate.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { createHash } = require('node:crypto');
const solc = require('solc');
const ganache = require('ganache');
const { AbiCoder, BrowserProvider, ContractFactory, Interface } = require('ethers');
const sha = value => createHash('sha256').update(value).digest('hex');
const root = path.resolve(__dirname, '../../..');
const sourcePath = path.join(__dirname, 'DecoderCopy.sol');
const source = fs.readFileSync(sourcePath, 'utf8');
const settings = { optimizer: { enabled: true, runs: 200 }, viaIR: true,
  evmVersion: 'shanghai', outputSelection: { '*': { '*': ['abi', 'evm.bytecode', 'evm.deployedBytecode'] } } };
assert.match(solc.version(), /^0\.8\.25\+commit\.b61c2a91\./);

async function main() {
  const rpc = ganache.provider({ logging: { quiet: true }, chain: { hardfork: 'shanghai' },
    wallet: { deterministic: true } });
  const provider = new BrowserProvider(rpc);
  provider.pollingInterval = 10;
  const evidence = { scope: 'Isolated decoder loop versus independent byte slicing; no Lean validation claimed',
    compiler: solc.version(), settings, sourceSha256: sha(source), runnerSha256: sha(fs.readFileSync(__filename)),
    lockSha256: sha(fs.readFileSync(path.join(__dirname, 'package-lock.json'))), runs: [] };
  try {
    for (const mutant of ['', 'stride']) {
      const needle = 'dst := add(dst, 32)';
      assert.equal(source.split(needle).length, 2);
      const testedSource = mutant ? source.replace(needle, 'dst := add(dst, 31)') : source;
      const input = { language: 'Solidity', sources: { 'DecoderCopy.sol': { content: testedSource } }, settings };
      const output = JSON.parse(solc.compile(JSON.stringify(input)));
      assert.deepEqual((output.errors || []).filter(e => e.severity === 'error'), []);
      const artifact = output.contracts['DecoderCopy.sol'].DecoderCopy;
      const contract = await new ContractFactory(artifact.abi, artifact.evm.bytecode.object,
        await provider.getSigner()).deploy();
      await contract.waitForDeployment();
      const iface = new Interface(artifact.abi);
      const run = { mutant, compilerInputSha256: sha(JSON.stringify(input)),
        deployedCode: await provider.getCode(contract.target), comparisons: [], killedBy: null };
      for (const [name, offset, count] of [['zero', 0, 0], ['one', 0, 1], ['two', 0, 2],
        ['unaligned-one', 1, 2], ['unaligned-last', 31, 3], ['129-words', 0, 129]]) {
        const bytes = Buffer.from(Array.from({ length: offset + 32 * count + 17 }, (_, i) => (17 * i + 3) % 256));
        const calldata = iface.encodeFunctionData('copy', [bytes, offset, count]);
        const actual = await rpc.request({ method: 'eth_call', params: [{ to: contract.target, data: calldata }, 'latest'] });
        const expected = AbiCoder.defaultAbiCoder().encode(['bytes', 'bytes'], [bytes, bytes.subarray(offset, offset + 32 * count)]);
        run.comparisons.push({ name, calldata, actual, expected, equal: actual.toLowerCase() === expected.toLowerCase() });
        if (actual.toLowerCase() !== expected.toLowerCase()) {
          assert.equal(mutant, 'stride', name);
          run.killedBy = name;
          break;
        }
        console.log('PASS ' + (mutant || 'original') + ' ' + name);
      }
      if (mutant) {
        assert.equal(run.killedBy, 'two', 'stride mutant must fail by exact returned bytes');
        console.log('KILLED stride by ' + run.killedBy);
      } else {
        assert.equal(run.comparisons.length, 6);
        run.reverts = [];
        const max = (1n << 256n) - 1n;
        const panic = '0x4e487b71' + AbiCoder.defaultAbiCoder().encode(['uint256'], [0x11]).slice(2);
        for (const [name, calldata, expected] of [
          ['short-source', iface.encodeFunctionData('copy', ['0x', 0, 1]), '0x'],
          ['count-overflow', iface.encodeFunctionData('copy', ['0x', 0, max]), panic],
          ['offset-overflow', iface.encodeFunctionData('copy', ['0x', max, 1]), panic],
          ['truncated-abi', iface.getFunction('copy').selector, '0x'],
        ]) {
          let observed;
          try {
            await rpc.request({ method: 'eth_call', params: [{ to: contract.target, data: calldata }, 'latest'] });
          } catch (error) {
            assert.equal(error.code, -32000, 'must be an EVM execution failure');
            observed = error.data;
          }
          assert.equal(observed, expected, name + ' exact revert bytes');
          run.reverts.push({ name, calldata, expected, actual: observed });
          console.log('PASS original ' + name);
        }
      }
      evidence.runs.push(run);
    }
    fs.writeFileSync(path.join(root, 'audit/trio/alloc2/word-copy-reference.json'), JSON.stringify(evidence, null, 2) + '\n');
  } finally {
    provider.destroy();
    await rpc.disconnect();
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
