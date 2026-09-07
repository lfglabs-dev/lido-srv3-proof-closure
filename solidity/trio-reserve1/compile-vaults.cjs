// Compile the unmodified pinned vault contracts into a new evidence directory.
const fs = require('node:fs'), path = require('node:path');
const cp = require('node:child_process'), crypto = require('node:crypto');
const solc = require('solc-089');
const root = path.resolve(__dirname, '../..');
const dir = process.env.RESERVE1_RECEIPT_DIR;
if (!dir) throw Error('RESERVE1_RECEIPT_DIR is required (must not exist)');
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const pin = cp.execFileSync('git', ['-C', path.join(root,'lido-core'), 'rev-parse','HEAD'], {encoding:'utf8'}).trim();
if (pin !== '17005714f151e5502c559932319a3f2f74ac2436') throw Error('Solidity pin mismatch');
cp.execFileSync('git', ['-C', path.join(root,'lido-core'), 'diff','--exit-code','HEAD','--','contracts']);
fs.mkdirSync(dir, {recursive:false});
const sources = {};
function load(name) {
  for (const candidate of [path.join(root,'lido-core',name),path.join(__dirname,'node_modules',name)]) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) {
      const contents=fs.readFileSync(candidate,'utf8');
      sources[name]={sha256:sha(contents),resolved_path:path.relative(root,candidate)};
      return {contents};
    }
  }
  return {error:`Unresolved import: ${name}`};
}
const entries=['contracts/0.8.9/LidoExecutionLayerRewardsVault.sol','contracts/0.8.9/WithdrawalVault.sol'];
const input={language:'Solidity',sources:Object.fromEntries(entries.map(name=>[name,{content:load(name).contents}])),settings:{optimizer:{enabled:true,runs:200},evmVersion:'istanbul',outputSelection:{'*':{'*':['abi','evm.bytecode.object','evm.deployedBytecode.object','evm.deployedBytecode.immutableReferences','storageLayout']}}}};
const output=JSON.parse(solc.compile(JSON.stringify(input),{import:load}));
fs.writeFileSync(path.join(dir,'compiler-output.json'),JSON.stringify(output));
const errors=(output.errors||[]).filter(x=>x.severity==='error');
const artifacts={};
if (!errors.length) for (const entry of entries) {
  const name=path.basename(entry,'.sol'),file=name+'.json';
  const raw=JSON.stringify(output.contracts[entry][name]);
  fs.writeFileSync(path.join(dir,file),raw);artifacts[name]={file,sha256:sha(raw),entry};
}
const receipt={source_commit:cp.execFileSync('git',['rev-parse','HEAD'],{cwd:root,encoding:'utf8'}).trim(),pin,utc:new Date().toISOString(),node:process.version,node_sha256:sha(fs.readFileSync(process.execPath)),compiler:solc.version(),compiler_sha256:sha(fs.readFileSync(require.resolve('solc-089/soljson.js'))),runner_sha256:sha(fs.readFileSync(__filename)),settings:input.settings,sources,artifacts,errors,output_sha256:sha(fs.readFileSync(path.join(dir,'compiler-output.json'))),scope:'Unmodified pinned vault compilation; no deployment, execution or Lean correspondence claim'};
fs.writeFileSync(path.join(dir,'receipt.json'),JSON.stringify(receipt,null,2)+'\n');
if(errors.length)throw Error(errors.map(x=>x.formattedMessage).join('\n'));
console.log('Compiled both unmodified pinned vaults with solc '+solc.version());
