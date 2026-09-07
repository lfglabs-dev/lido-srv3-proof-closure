const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const root = path.resolve(__dirname, '../..');
const pin = '17005714f151e5502c559932319a3f2f74ac2436';
if (cp.execFileSync('git', ['-C', path.join(root, 'lido-core'), 'rev-parse', 'HEAD'], {encoding:'utf8'}).trim() !== pin)
  throw Error('Solidity pin mismatch');
cp.execFileSync('git', ['-C', path.join(root, 'lido-core'), 'diff', '--exit-code', 'HEAD', '--', 'contracts'], {stdio:'pipe'});
const sourceHashes = {};
function load(name) {
  for (const candidate of [path.join(root, name), path.join(root, 'lido-core', name), path.join(__dirname, 'node_modules', name)]) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
      const contents = fs.readFileSync(candidate, 'utf8');
      sourceHashes[name] = crypto.createHash('sha256').update(contents).digest('hex');
      return {contents};
    }
  }
  return {error: `Unresolved pinned import: ${name}`};
}
fs.mkdirSync(path.join(__dirname, 'artifacts'), {recursive:true});
const receipts = [];
for (const [entry, compilerName, evmVersion] of [
  ['LidoHarness.sol','solc-0424','constantinople'],
  ['QueueHarness.sol','solc-089','istanbul'],
  ['LocatorHarness.sol','solc-089','istanbul'],
  ['OracleHarness.sol','solc-089','istanbul'],
  ['ConsensusHarness.sol','solc-089','istanbul'],
]) {
  const solc = require(compilerName);
  const name = `solidity/trio-reserve1/${entry}`;
  const input = {language:'Solidity', sources:{[name]:{content:load(name).contents}}, settings:{
    optimizer:{enabled:true,runs:200}, evmVersion,
    outputSelection:{'*':{'*':['abi','evm.bytecode.object','evm.deployedBytecode.object','storageLayout']}}
  }};
  const output = JSON.parse(compilerName === 'solc-0424'
    ? solc.compileStandardWrapper(JSON.stringify(input),load)
    : solc.compile(JSON.stringify(input),{import:load}));
  const errors = (output.errors || []).filter(x => x.severity === 'error');
  if (errors.length) throw Error(errors.map(x=>x.formattedMessage).join('\n'));
  fs.writeFileSync(path.join(__dirname,'artifacts',entry+'.json'),JSON.stringify(output.contracts[name]));
  receipts.push({entry,compiler:solc.version(),evmVersion,optimizer:input.settings.optimizer,
    contracts:Object.keys(output.contracts[name]),warnings:(output.errors||[]).map(x=>x.formattedMessage)});
}
fs.writeFileSync(path.join(root,'audit/trio/reserve1/receipts/solidity-compilation-with-oracle.json'),
  JSON.stringify({pin,node:process.version,receipts,sourceHashes},null,2)+'\n');
console.log('Compiled pinned Lido, queue, locator, AccountingOracle and HashConsensus.');
