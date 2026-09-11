from pathlib import Path
import hashlib,json,subprocess
R=Path(__file__).resolve().parents[2];O=Path(__file__).resolve().parent;OLD=R/'audit/address-steth-quote-call';BASE='ee24f9dc158ed25cec118a8ab8cd3a4fc59942f1'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def run(*xs):return subprocess.check_output(xs,text=True).strip()
# Reuse the exact complete previous evidence, never infer source identity from a green build.
receipt=json.loads((OLD/'receipt.json').read_text())
for p,h in receipt['files'].items():
 assert sha(R/p)==h,p
 assert (R/p).read_bytes()==subprocess.check_output(['git','-C',str(R),'show',BASE+':'+p]),p
ident=json.loads((O/'solidity/lido/source-identities.json').read_text())
assert len(ident['sources'])==37
for rel,h in ident['sources'].items():
 p=O/'solidity/lido/src'/rel
 assert sha(p)==h and p.read_bytes()==(OLD/'solidity/lido/src'/rel).read_bytes(),rel
records={'reused_parent':BASE,'reused_receipt_hashes':len(receipt['files']),'original_lido_inputs':37}
for name,project,dirname,rel in [('ConversionHarness','lido','out','ConversionHarness.sol/ConversionHarness.json'),('BatchHarness','queue','artifacts','BatchHarness.sol/BatchHarness.json')]:
 a=json.loads((O/'solidity'/project/dirname/rel).read_text());m=a['metadata']
 for src,info in m['sources'].items():assert run('cast','keccak','0x'+(O/'solidity'/project/src).read_bytes().hex())==info['keccak256'],src
 assert m['settings']['optimizer']=={'enabled':True,'runs':200}
 if name=='ConversionHarness':
  assert m['compiler']['version']=='0.4.24+commit.e67f0147' and m['settings']['evmVersion']=='byzantium' and len(m['sources'])==38
  assert (O/'ConversionHarness.asm').read_text()==a['assembly']+'\n'
  fixture=json.loads((O/'solidity/queue/artifacts/ConversionHarness.json').read_text())
  for k in ['bytecode','deployedBytecode']:assert fixture[k]['object']==a[k]['object']
  assert fixture['metadata']==m
 else:
  assert m['compiler']['version']=='0.8.9+commit.e5eed63a'
  old=json.loads((OLD/'BatchHarness-compiler-artifact.json').read_text())
  for k in ['bytecode','deployedBytecode']:assert old[k]['object']==a[k]['object']
  assert old['metadata']==m
 (O/(name+'-compiler-artifact.json')).write_text(json.dumps(a,separators=(',',':'))+'\n')
 records[name]={'compiler':m['compiler'],'settings':m['settings'],'source_count':len(m['sources']),'artifact_sha256':sha(O/(name+'-compiler-artifact.json'))}
for name in ['Lido','WstETH']:
 p=O/'solidity/queue/artifacts'/(name+'.json')
 assert p.read_bytes()==(OLD/'solidity/queue/artifacts'/(name+'.json')).read_bytes()
 records[name+'_reused_artifact_sha256']=sha(p)
for p in (O/'solidity/queue/src').rglob('*.sol'):
 assert p.read_bytes()==(OLD/'solidity/queue/src'/p.relative_to(O/'solidity/queue/src')).read_bytes()
records['reused_full_assemblies']={str(p.relative_to(R)):sha(p) for p in [OLD/'Lido.asm',OLD/'BatchHarness.asm',R/'audit/address-wrapped-token-call/solidity/token/WstETH.asm']}
# The inherited token assembly predates ee24; verify its precise source-provider bytes.
for p,h in records['reused_full_assemblies'].items():assert (R/p).read_bytes()==subprocess.check_output(['git','-C',str(R),'show',BASE+':'+p])
records['tools']={'forge':run('forge','--version'),'cast':run('cast','--version')}
(O/'compiler-identities.json').write_text(json.dumps(records,indent=2)+'\n')
print('PASS exact111 parent receipt inputs; reused37 original Lido sources; fresh38-body derived fixture and unchanged queue objects/metadata; actual archived Lido/WstETH deployments; reused full Lido/WstETH/queue assembly identities')
