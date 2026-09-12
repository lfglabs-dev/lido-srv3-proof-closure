#!/usr/bin/env python3
"""Recompute scoped source identities and independent Lean axiom dependencies."""
import hashlib, importlib.util, json, pathlib, re, subprocess
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(__file__).resolve().parent
BASE = '86ee843a2c755bc044b6eed47fe332a4138d4d6e'
NEW = {
 'ReportFeeCastInvariant':'audit/trio/account-address/ReportFeeCastInvariant.lean',
 'LidoSRv3.Audit.Guarantees.PAccount1ActualFeeCasts':'LidoSRv3/Audit/Guarantees/PAccount1ActualFeeCasts.lean',
 'Tests.Verity.ReportFeeCastInvariantTest':'audit/trio/account-address/Tests/Verity/ReportFeeCastInvariantTest.lean',
}
def git(repo,*args):return subprocess.check_output(['git','-C',str(repo),*args])
def sha(data):return hashlib.sha256(data).hexdigest()
manifest=json.loads((ROOT/'lake-manifest.json').read_text())
pins={p['name']:p['rev'] for p in manifest['packages']}
for name,pin in pins.items():
 assert git(ROOT/'.lake/packages'/name,'rev-parse','HEAD').decode().strip()==pin,name
# The retained direct PAccount1 setup includes its full non-toolchain import
# closure; the three new modules add only each other/ReportFeeMint from it.
setup=json.loads((ROOT/'.lake/build/ir/LidoSRv3/Audit/Guarantees/PAccount1.setup.json').read_text())
entries=[]
for module,arts in setup['importArts'].items():
 artifact=arts[0]
 if '/.lake/packages/' in artifact:
  name,tail=artifact.split('/.lake/packages/',1)[1].split('/',1)
  relative=tail.split('.lake/build/lib/lean/',1)[1].removesuffix('.olean')+'.lean'
  path=ROOT/'.lake/packages'/name/relative
  data=path.read_bytes()
  assert git(ROOT/'.lake/packages'/name,'show',pins[name]+':'+relative)==data,str(path)
  rel='.lake/packages/'+name+'/'+relative
 else:
  rel=module.replace('.','/')+'.lean'
  if not (ROOT/rel).exists():rel='audit/trio/account-address/'+rel
  data=(ROOT/rel).read_bytes()
  assert git(ROOT,'show',BASE+':'+rel)==data,rel
 entries.append(dict(module=module,path=rel,sha256=sha(data)))
for module,rel in NEW.items():entries.append(dict(module=module,path=rel,sha256=sha((ROOT/rel).read_bytes())))
# The imported root facade itself is not listed among its own imports.
rel='LidoSRv3/Audit/Guarantees/PAccount1.lean'
assert git(ROOT,'show',BASE+':'+rel)==(ROOT/rel).read_bytes()
entries.append(dict(module='LidoSRv3.Audit.Guarantees.PAccount1',path=rel,sha256=sha((ROOT/rel).read_bytes())))
(OUT/'source-inputs.json').write_text(json.dumps({'base':BASE,'entries':entries,'package_pins':pins,
 'scope':'Three new modules plus inherited PAccount1 direct setup import closure; toolchain Std/Lean remain pinned by lean-toolchain.'},indent=2)+'\n')
spec=importlib.util.spec_from_file_location('checker',ROOT/'scripts/check_trust_axioms.py')
checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker);checker.ROOT=ROOT
names=[]
for module,rel in NEW.items():
 text=(ROOT/rel).read_text();namespace=re.search(r'^namespace (\S+)',text,re.M).group(1)
 names += [namespace+'.'+name for name in re.findall(r'^#print axioms (\S+)',text,re.M)]
 assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',re.sub(r'/\-.*?\-/','',text,flags=re.S)),rel
names.append('AccountAddress.ReportFeeCastInvariant.casts_of_allocation_le_total')
computed=checker.environment_dependencies(names,'Tests.Verity.ReportFeeCastInvariantTest',None)
assert all(s <= {'propext','Classical.choice','Quot.sound'} for s in computed.values())
(OUT/'axioms.json').write_text(json.dumps({n:sorted(a) for n,a in computed.items()},indent=2)+'\n')
print(f'PASS: {len(entries)} source identities; {len(pins)} package pins; {len(computed)} independently recomputed foundational-only axiom sets')
