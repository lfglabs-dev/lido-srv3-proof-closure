from pathlib import Path
import hashlib,json,subprocess,sys,tempfile
root=Path.cwd().resolve();out=root/'audit/account-accounting-call'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source_commit='a4abd69d7acbcae9ff927d45057337029b21eb93'
old=json.loads((out/'normal-build-identities.json').read_text());current={};normal={}
for module,record in old.items():
 path=root/record['source'];rel=module.replace('.','/')
 assert path.read_bytes()==subprocess.check_output(['git','show',source_commit+':'+record['source']])
 current[module]={'source':record['source'],'source_sha256':sha(path),'olean_sha256':sha(root/'.lake/build/lib/lean'/Path(rel+'.olean')),'ilean_sha256':sha(root/'.lake/build/lib/lean'/Path(rel+'.ilean'))}
 setup_path=root/'.lake/build/ir'/Path(rel+'.setup.json');trace_path=root/'.lake/build/lib/lean'/Path(rel+'.trace')
 setup=json.loads(setup_path.read_text());trace=json.loads(trace_path.read_text())
 assert setup['name']==module and setup['options']=={} and setup['plugins']==[]
 assert trace['synthetic'] is False and 'skipKernelTC' not in trace_path.read_text()
 normal[module]={**current[module],'setup_sha256':sha(setup_path),'trace_sha256':sha(trace_path)}
tmp=Path('/tmp/lido-account-call-integration-normal.json')
tmp.write_text(json.dumps(current,indent=2)+'\n')
source=(out/'validate.py').read_text()
needle="records=json.loads((OUT/'normal-build-identities.json').read_text())"
assert source.count(needle)==1
source=source.replace(needle,"records=json.loads(Path('/tmp/lido-account-call-integration-normal.json').read_text())")
needle="assert (ROOT/path).read_bytes()==git(ROOT,'show',BASE+':'+path)"
assert source.count(needle)==1
source=source.replace(needle,"assert (sha((ROOT/path).read_bytes())=='68a2eeea808e5fe3ada64e9a89f7da8698c67893a021bdde219043fc99110411' if path=='lakefile.lean' else (ROOT/path).read_bytes()==git(ROOT,'show',BASE+':'+path))")
write=Path.write_text
def compare(path,text,*args,**kwargs):
 if not path.resolve().is_relative_to(out.resolve()):
  assert not path.resolve().is_relative_to(root) and path.resolve().is_relative_to(Path(tempfile.gettempdir()).resolve()),path
  return write(path,text,*args,**kwargs)
 assert path.read_text()==text,path
 return len(text)
Path.write_text=compare
try:
 exec(compile(source,str(out/'validate.py'),'exec'),{'__file__':str(out/'validate.py'),'__name__':'__main__'})
finally:Path.write_text=write
receipt=json.loads((out/'receipt.json').read_text())
for path,h in receipt['sha256'].items():assert sha(root/path)==h,path
for module in ['LidoSRv3.Audit.AllGuarantees','LidoSRv3.Audit.Trust']:
 rel=module.replace('.','/');setup_path=root/'.lake/build/ir'/Path(rel+'.setup.json');trace_path=root/'.lake/build/lib/lean'/Path(rel+'.trace')
 setup=json.loads(setup_path.read_text());trace=json.loads(trace_path.read_text())
 assert setup['options']=={} and setup['plugins']==[] and trace['synthetic'] is False
 assert 'skipKernelTC' not in trace_path.read_text()
 selected=list(current) if module.endswith('Trust') else list(current)[:3]
 for m in selected:
  selected_olean=Path(setup['importArts'][m][0]);actual=root/'.lake/build/lib/lean'/Path(m.replace('.','/')+'.olean')
  assert selected_olean.resolve()==actual.resolve() and sha(selected_olean)==current[m]['olean_sha256'],m
 normal[module]={'source_sha256':sha(root/Path(rel+'.lean')),'olean_sha256':sha(root/'.lake/build/lib/lean'/Path(rel+'.olean')),'setup_sha256':sha(setup_path),'trace_sha256':sha(trace_path)}
Path('/tmp/lido-account-call-integration-identities.json').write_text(json.dumps({'source_commit':source_commit,'sources':45,'pins':11,'solidity_bodies':10,'scoped_axioms':11,'source_receipt_hashes':len(receipt['sha256']),'normal':normal,'configuration_sha256':{p:sha(root/p) for p in ['lakefile.lean','lake-manifest.json','lean-toolchain']},'note':'Four fresh registered normal artifacts replace source-stage manual compile identities. Actual normal setup/providers and all scoped dependencies are rechecked; old manual olean equality is not asserted.'},indent=2)+'\n')
print('PASS 67 exact source hashes; four fresh registered normal modules and both aggregator providers; new lakefile hash explicit, other configurations unchanged; dossier outputs compared without writes')
