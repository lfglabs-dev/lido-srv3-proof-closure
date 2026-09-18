// Standard JSON entry point provided by official solc-js v0.4.24/wrapper.js.
// All imports are materialized first; no callback, network imports or stubs.
const fs = require('fs');
const path = require('path');
const soljson = require(path.resolve(process.argv[2]));
const version = soljson.cwrap('version', 'string', [])();
if (!version.startsWith('0.4.24+commit.e67f0147.')) {
  throw new Error(`wrong solc version: ${version}`);
}
console.log(`soljson compiler: ${version}`);
const remappings = [
  ['@aragon/', 'audit/account-fee-distribution/solidity/vendor/@aragon/'],
  ['openzeppelin-solidity/', 'audit/account-fee-distribution/solidity/vendor/openzeppelin-solidity/'],
  ['contracts/', 'lido-core/contracts/'],
];
const sources = {};
function addSource(name) {
  name = path.posix.normalize(name);
  if (name.startsWith('../') || path.isAbsolute(name)) throw new Error(`outside checkout: ${name}`);
  if (sources[name]) return;
  const content = fs.readFileSync(name, 'utf8');
  sources[name] = {content};
  for (const match of content.matchAll(/\bimport\s+(?:[^;]*?\sfrom\s+)?["']([^"']+)["']\s*;/g)) {
    let imported = match[1];
    if (imported.startsWith('.')) imported = path.posix.join(path.posix.dirname(name), imported);
    else {
      const mapping = remappings.find(([prefix]) => imported.startsWith(prefix));
      if (mapping) imported = mapping[1] + imported.slice(mapping[0].length);
    }
    addSource(imported);
  }
}
const entry = process.argv[3] || 'solidity/reserve/pin/ReserveHarness.sol';
const contractName = process.argv[4] || 'ReserveHarness';
if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(contractName)) throw new Error('invalid contract name');
addSource(entry);
const input = {language: 'Solidity', sources, settings: {
  optimizer: {enabled: true, runs: 200},
  evmVersion: 'constantinople',
  remappings: remappings.map(([prefix, target]) => `${prefix}=${target}`),
  outputSelection: {'*': {'*': ['abi', 'evm.bytecode.object']}},
}};
const out = process.argv[5] || 'solidity/out/reserve-0424';
if (!out.startsWith('solidity/out/') || out.split('/').includes('..')) throw new Error('invalid output directory');
fs.mkdirSync(out, {recursive: true});
fs.writeFileSync(`${out}/standard-input.json`, JSON.stringify(input));
const raw = soljson.cwrap('compileStandard', 'string', ['string', 'number'])(JSON.stringify(input), 0);
fs.writeFileSync(`${out}/standard-output.json`, raw);
const output = JSON.parse(raw);
for (const diagnostic of output.errors || []) console.error(diagnostic.formattedMessage || diagnostic.message);
if ((output.errors || []).some(e => e.severity === 'error')) process.exit(1);
const contract = output.contracts[entry][contractName];
if (!contract.evm.bytecode.object) throw new Error(`${contractName} bytecode missing`);
fs.writeFileSync(`${out}/${contractName}.bin`, contract.evm.bytecode.object);
fs.writeFileSync(`${out}/${contractName}.abi`, JSON.stringify(contract.abi));
console.log(`${contractName} compiled from ${entry} using ${Object.keys(sources).length} source files`);
