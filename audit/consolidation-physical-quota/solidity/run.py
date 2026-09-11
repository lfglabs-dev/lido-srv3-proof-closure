#!/usr/bin/env python3
"""Materialize exact retained inputs in an isolated temporary Forge project.
Writes only this new dossier. Legacy vault artifact is reused, never compiled.
"""
from pathlib import Path
import hashlib,json,subprocess,tempfile
OUT=Path(__file__).resolve().parent
sha=lambda b:hashlib.sha256(b).hexdigest()
pinned=json.loads((OUT/'pinned-sources.json').read_text())['sources']
sources=dict(pinned)
for name in ['PhysicalQuotaHarness.sol','PhysicalQuota.t.sol']:
 sources['test/'+name]={'content':(OUT/name).read_text()}
with tempfile.TemporaryDirectory(prefix='lido-physical-quota-forge-') as tmp:
 root=Path(tmp)
 for name,item in sources.items():
  p=root/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(item['content'])
 (root/'legacy').mkdir();(root/'legacy/SettlementVaultHarness.json').write_bytes((OUT/'SettlementVaultHarness.json').read_bytes())
 config='''[profile.default]
src="contracts"
test="test"
libs=[]
optimizer=true
optimizer_runs=200
via_ir=true
evm_version="cancun"
build_info=true
extra_output=["irOptimized", "storageLayout"]
fs_permissions=[{access="read",path="./"}]
'''
 (root/'foundry.toml').write_text(config)
 command=['forge','test','--root',str(root),'--use',str(Path.home()/'.svm/0.8.25/solc-0.8.25'),'--offline','--fuzz-runs','1024','--match-contract','PhysicalQuotaTest','-vv']
 result=subprocess.run(command,text=True,capture_output=True)
 (OUT/'forge.log').write_text(result.stdout+result.stderr)
 print(result.stdout+result.stderr,end='',flush=True)
 result.check_returncode()
 artifacts={}
 for name in ['PhysicalQuotaHarness','PhysicalQuotaTest','QuotaInbox','QuotaRefund']:
  paths=list((root/'out').glob('*/'+name+'.json'));assert len(paths)==1
  raw=paths[0].read_bytes();(OUT/(name+'.json')).write_bytes(raw);artifacts[name]=sha(raw)
  if name=='PhysicalQuotaHarness':
   artifact=json.loads(raw);(OUT/'PhysicalQuotaHarness.ir').write_text(artifact['irOptimized']+'\n')
 infos=list((root/'out/build-info').glob('*.json'));assert len(infos)==1,infos
 info=json.loads(infos[0].read_text())
 (OUT/'build-info.json').write_bytes(infos[0].read_bytes())
 (OUT/'receipt.json').write_text(json.dumps({'scope':'Actual inherited Gateway quota plus explicit typed settlement suffix; full outer admission excluded. Actual cached0.8.9 vault reused. No production bytecode identity claim.',
  'command':command,'config':config,'forge_version':subprocess.check_output(['forge','--version'],text=True),
  'sources':{n:sha(v['content'].encode()) for n,v in sorted(sources.items())},'artifacts':artifacts,
  'legacy_sha256':sha((OUT/'SettlementVaultHarness.json').read_bytes()),'log_sha256':sha((OUT/'forge.log').read_bytes()),
  'build_info_sha256':sha((OUT/'build-info.json').read_bytes())},indent=2)+'\n')
 print('PASS retained full new compiler inputs/build-info/artifacts/IR; cached legacy artifact reused')
