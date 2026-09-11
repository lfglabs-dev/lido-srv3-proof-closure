#!/usr/bin/env python3
"""Fresh eight locator runtime tests; materialize retained pinned bodies in isolation."""
from pathlib import Path
import tempfile,json,subprocess,hashlib
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
OLD=ROOT/'audit/topup-credential-call/solidity/input.json'
NEW='audit/topup-entry-admission/solidity/TopupEntryAdmission.t.sol'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
solc=Path.home()/'.svm/0.8.25/solc-0.8.25'
sources=json.loads(OLD.read_text())['sources'];sources[NEW]={'content':(ROOT/NEW).read_text()}
with tempfile.TemporaryDirectory(prefix='lido-locator-forge-') as temp:
 d=Path(temp)
 for name,item in sources.items():
  p=d/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(item['content'])
 settings='[profile.default]\nsrc = "contracts"\ntest = "audit/topup-entry-admission/solidity"\nlibs = []\noptimizer = true\noptimizer_runs = 200\nvia_ir = true\nevm_version = "cancun"\n'
 (d/'foundry.toml').write_text(settings)
 command=['forge','test','--root',str(d),'--use',str(solc),'--offline','--fuzz-runs','1024','--match-contract','TopupEntryAdmissionTest','--match-test','test(?:Fuzz)?_entry_','-vv']
 result=subprocess.run(command,cwd=d,text=True,capture_output=True)
 (OUT/'forge.log').write_text(result.stdout+result.stderr);print(result.stdout+result.stderr,end='');result.check_returncode()
 artifacts={}
 for name in ['GatewayWitnessHarness','TopupEntryAdmissionTest']:
  paths=list((d/'out').glob('*/'+name+'.json'));assert len(paths)==1,paths
  raw=paths[0].read_bytes();(OUT/(name+'.json')).write_bytes(raw)
  artifact=json.loads(raw);metadata=json.loads(artifact['rawMetadata'])
  assert metadata['compiler']['version']=='0.8.25+commit.b61c2a91'
  artifacts[name]=dict(sha256=hashlib.sha256(raw).hexdigest(),metadata_sources=metadata['sources'],settings=metadata['settings'])
 receipt=dict(scope='Fresh8 entry admission cases including1024 arbitrary full-word fuzz runs on actual inherited Gateway, with recorder router and independent SHA roots. Fixture profile viaIR optimizer200 Cancun; not production bytecode identity or a Lean proof.',
  command=command,foundry_config=settings,forge_version=subprocess.check_output(['forge','--version'],text=True),solc_version=subprocess.check_output([str(solc),'--version'],text=True),solc_binary_sha256=sha(solc),
  source_sha256={n:hashlib.sha256(v['content'].encode()).hexdigest() for n,v in sorted(sources.items())},artifacts=artifacts,log_sha256=sha(OUT/'forge.log'))
 (OUT/'receipt.json').write_text(json.dumps(receipt,indent=2,sort_keys=True)+'\n')
