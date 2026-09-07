const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const solc = require('solc-0825');
const root = path.resolve(__dirname, '../..');
const pin = '17005714f151e5502c559932319a3f2f74ac2436';
if (cp.execFileSync('git', ['-C', path.join(root, 'lido-core'), 'rev-parse', 'HEAD'], {encoding:'utf8'}).trim() !== pin)
  throw Error('Solidity pin mismatch');
cp.execFileSync('git', ['-C', path.join(root, 'lido-core'), 'diff', '--exit-code', 'HEAD', '--', 'contracts'], {stdio:'pipe'});
const sourceHashes = {};
function load(name) {
  const candidate = name.startsWith('contracts/') ? path.join(root, 'lido-core', name)
    : name.startsWith('@') ? path.join(__dirname, 'node_modules', name) : path.join(root, name);
  if (!fs.existsSync(candidate)) return {error:`Unresolved pinned import: ${name}`};
  const contents = fs.readFileSync(candidate, 'utf8');
  sourceHashes[name] = crypto.createHash('sha256').update(contents).digest('hex');
  return {contents};
}
const entry = 'solidity/trio-reserve1/RouterHarness.sol';
const settings = {optimizer:{enabled:true,runs:200},viaIR:true,evmVersion:'cancun',
  outputSelection:{'*':{'*':['abi','evm.bytecode','evm.deployedBytecode']}}};
const output = JSON.parse(solc.compile(JSON.stringify({language:'Solidity',sources:{[entry]:{content:load(entry).contents}},settings}),{import:load}));
const errors = (output.errors || []).filter(x => x.severity === 'error');
if (errors.length) throw Error(errors.map(x => x.formattedMessage).join('\n'));
fs.mkdirSync(path.join(__dirname,'artifacts'),{recursive:true});
fs.writeFileSync(path.join(__dirname,'artifacts','router-linked.json'),JSON.stringify(output.contracts));
fs.writeFileSync(path.join(root,'audit/trio/reserve1/receipts/router-compilation.json'),JSON.stringify({
  pin,node:process.version,compiler:solc.version(),settings,sourceHashes,
  warnings:(output.errors || []).map(x => x.formattedMessage)},null,2)+'\n');
console.log('Compiled inherited pinned StakingRouter receiver with solc 0.8.25, viaIR, Cancun.');
