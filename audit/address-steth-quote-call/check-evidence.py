from pathlib import Path
import hashlib,json,subprocess
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def run(*xs):return subprocess.check_output(xs,text=True).strip()
ident=json.loads((O/'solidity/lido/source-identities.json').read_text())
for rel,h in ident['sources'].items():assert sha(O/'solidity/lido/src'/rel)==h
assert len(ident['sources'])==37
records={}
for name,project,artifact in [('Lido','lido','Lido.sol/Lido.json'),('QuoteHarness','lido','QuoteHarness.sol/QuoteHarness.json'),('BatchHarness','queue','BatchHarness.sol/BatchHarness.json')]:
 a=json.loads((O/'solidity'/project/('artifacts' if project=='queue' else 'out')/artifact).read_text());m=a['metadata']
 for rel,item in m['sources'].items():assert run('cast','keccak','0x'+(O/'solidity'/project/rel).read_bytes().hex())==item['keccak256'],rel
 assert m['settings']['optimizer']=={'enabled':True,'runs':200}
 if project=='lido':assert m['compiler']['version']=='0.4.24+commit.e67f0147' and m['settings']['evmVersion']=='byzantium'
 if name=='Lido':assert len(m['sources'])==37 and a['methodIdentifiers']['getSharesByPooledEth(uint256)']=='19208451'
 if name=='QuoteHarness':assert len(m['sources'])==38
 if name=='BatchHarness':assert m['compiler']['version']=='0.8.9+commit.e5eed63a'
 assert (O/(name+'.asm')).read_text()==a['assembly']+'\n',name
 archived=O/(name+'-compiler-artifact.json')
 if not archived.exists():archived.write_text(json.dumps(a,separators=(',',':'))+'\n')
 # inspect may add assembly/source maps: executable and compiler source metadata must remain exact.
 old=json.loads(archived.read_text())
 for key in ['bytecode','deployedBytecode']:
  assert old[key]['object']==a[key]['object'],(name,key)
 assert old['metadata']==m
 records[name]={'compiler':m['compiler'],'settings':m['settings'],'sources':len(m['sources']),'artifact_sha256':sha(archived),'object_sha256':hashlib.sha256(a['deployedBytecode']['object'].encode()).hexdigest()}
 for key in ['bytecode','deployedBytecode','metadata']:
  if name!='BatchHarness':
   fixture=json.loads((O/'solidity/queue/artifacts'/(name+'.json')).read_text())
   assert (fixture[key]['object']==a[key]['object']) if key!='metadata' else fixture[key]==m
# Every queue source is the unchanged accepted permit fixture/source; only fresh quote test is new.
for p in (O/'solidity/queue/src').rglob('*.sol'):
 rel=p.relative_to(O/'solidity/queue/src');assert p.read_bytes()==(R/'audit/address-permit-request-calls/solidity/src'/rel).read_bytes()
assert (O/'solidity/queue/artifacts/WstETH.json').read_bytes()==(R/'audit/address-permit-request-calls/solidity/artifacts/WstETH.json').read_bytes()
records['reused']={'parent':'6e87eb6e7d6465936d3fab76c3fc7fab5ec51194','WstETH_artifact_sha256':sha(O/'solidity/queue/artifacts/WstETH.json'),'queue_sources':len(list((O/'solidity/queue/src').rglob('*.sol')))}
records['tools']={'forge':run('forge','--version'),'cast':run('cast','--version')}
(O/'compiler-identities.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS 37 original Lido inputs; metadata keccak for full Lido/QuoteHarness/BatchHarness closures; compiled fixture objects; unchanged queue sources and WstETH artifact')
