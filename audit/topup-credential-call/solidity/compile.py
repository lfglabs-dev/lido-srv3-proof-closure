from pathlib import Path
import json,re,subprocess,posixpath,hashlib
ROOT=Path(__file__).resolve().parents[3];OUT=Path(__file__).resolve().parent
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core');PIN='17005714f151e5502c559932319a3f2f74ac2436'
HARNESS='audit/topup-gateway-witness-batch/solidity/TopupGatewayWitnessBatch.t.sol'
sources={};ids={}
def add(name):
 if name in sources:return
 if name.startswith('contracts/'):
  data=subprocess.check_output(['git','-C',str(CORE),'show',PIN+':'+name]);origin='core:'+PIN
 elif name.startswith('@openzeppelin/'):
  data=subprocess.check_output(['git','-C',str(ROOT),'show','f193ebf96beef3f5e1e1568fc9f2b906c0192299:audit/deposit-dsm-call/solidity/src/'+name]);origin='accepted-deposit-dsm-vendored'
 else:
  data=subprocess.check_output(['git','-C',str(ROOT),'show','f193ebf96beef3f5e1e1568fc9f2b906c0192299:'+name]);origin='accepted-proof-base'
 text=data.decode();sources[name]={'content':text};ids[name]={'sha256':hashlib.sha256(data).hexdigest(),'origin':origin}
 for dep in re.findall(r'import\s+(?:[^;]*?from\s+)?["\']([^"\']+)["\']\s*;',text):
  add(posixpath.normpath(posixpath.join(posixpath.dirname(name),dep)) if dep.startswith('.') else dep)
add(HARNESS)
settings={'optimizer':{'enabled':True,'runs':200},'viaIR':True,'evmVersion':'cancun','outputSelection':{HARNESS:{'GatewayWitnessHarness':['irOptimized','metadata','evm.methodIdentifiers']}}}
i={'language':'Solidity','sources':sources,'settings':settings};(OUT/'input.json').write_text(json.dumps(i,sort_keys=True)+'\n')
solc=Path.home()/'.svm/0.8.25/solc-0.8.25'
r=subprocess.run([str(solc),'--standard-json'],input=json.dumps(i),text=True,capture_output=True);(OUT/'output.json').write_text(r.stdout);r.check_returncode()
o=json.loads(r.stdout);assert not [x for x in o.get('errors',[]) if x['severity']=='error'],o.get('errors')
c=o['contracts'][HARNESS]['GatewayWitnessHarness'];(OUT/'GatewayWitnessHarness.ir').write_text(c['irOptimized']+'\n')
(OUT/'compiler-identities.json').write_text(json.dumps({'solc':str(solc),'binary_sha256':hashlib.sha256(solc.read_bytes()).hexdigest(),'version':subprocess.check_output([str(solc),'--version'],text=True),'sources':ids,'methods':c['evm']['methodIdentifiers']},indent=2,sort_keys=True)+'\n')
print('PASS compiled unchanged GatewayWitnessHarness;',len(sources),'pinned inputs')
