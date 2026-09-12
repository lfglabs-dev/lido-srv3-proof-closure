#!/usr/bin/env python3
"""Fresh full pinned router runtime checks; isolate all writes in a temporary Forge project."""
from pathlib import Path
import json,hashlib,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
NEW='audit/topup-router-admission-call/solidity/TopupRouterAdmissionCall.t.sol'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=json.loads((OUT/'input.json').read_text())['sources']
sources={}
for name,entry in source.items():
 if name.startswith('/tmp/lido-ssz-proof-committed/lido-core/'):name=name.split('/lido-core/',1)[1]
 elif name.startswith('/tmp/lido-topup-wei-deps/package/'):name='@openzeppelin/contracts-v5.2/'+name.split('/package/',1)[1]
 assert not name.startswith('/') and '..' not in Path(name).parts,name
 sources[name]=entry
sources[NEW]={'content':(ROOT/NEW).read_text()}
solc=Path.home()/'.svm/0.8.25/solc-0.8.25'
with tempfile.TemporaryDirectory(prefix='lido-router-admission-forge-') as tmp:
 d=Path(tmp)
 for name,entry in sources.items():
  p=d/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(entry['content'])
 settings='[profile.default]\nsrc = "contracts"\ntest = "audit/topup-router-admission-call/solidity"\nlibs = []\noptimizer = true\noptimizer_runs = 200\nvia_ir = true\nevm_version = "cancun"\nextra_output = ["irOptimized"]\n'
 (d/'foundry.toml').write_text(settings)
 command=['forge','test','--root',str(d),'--use',str(solc),'--offline','--fuzz-runs','256','--match-contract','TopupRouterAdmissionCallTest','-vv']
 result=subprocess.run(command,cwd=d,text=True,capture_output=True)
 log=result.stdout+result.stderr;(OUT/'forge.log').write_text(log);print(log,end='')
 if result.returncode:
  import time
  (OUT/('failed-forge-'+str(time.time_ns())+'.log')).write_text(log)
  result.check_returncode()
 artifacts={}
 for name in ['BatchRouter','StakingRouter','TopupRouterAdmissionCallTest','AdmissionEndpoint','BatchModule']:
  paths=list((d/'out').glob('*/'+name+'.json'));assert len(paths)==1,paths
  body=paths[0].read_bytes();(OUT/(name+'.json')).write_bytes(body)
  artifact=json.loads(body);meta=json.loads(artifact['rawMetadata'])
  assert meta['compiler']['version']=='0.8.25+commit.b61c2a91'
  artifacts[name]={'sha256':hashlib.sha256(body).hexdigest(),'metadata_sources':meta['sources'],'settings':meta['settings']}
 receipt={'scope':'17 fresh runtime tests, including one 256-run status fuzz, on full inherited pinned router; raw locator and Lido fixtures, not deployed contract identity or whole gateway CALL proof.',
  'command':command,'foundry_config':settings,'forge_version':subprocess.check_output(['forge','--version'],text=True),'solc_version':subprocess.check_output([str(solc),'--version'],text=True),'solc_sha256':sha(solc),
  'source_sha256':{n:hashlib.sha256(v['content'].encode()).hexdigest() for n,v in sorted(sources.items())},'artifacts':artifacts,'log_sha256':sha(OUT/'forge.log')}
 (OUT/'receipt.json').write_text(json.dumps(receipt,indent=2,sort_keys=True)+'\n')
