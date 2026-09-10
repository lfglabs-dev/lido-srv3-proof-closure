#!/usr/bin/env python3
"""Verify the exact proof-only delta, actual imported sources and kernel axioms."""
from pathlib import Path
import hashlib, importlib.util, json, re, subprocess
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
BASE='70301660264f2f710e7160e190aaa3af330e84fa'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core')
PIN='17005714f151e5502c559932319a3f2f74ac2436'
MODULES={
 'ReportFeeMint':'audit/trio/account-address/ReportFeeMint.lean',
 'ReportFeeCheckedSplit':'audit/trio/account-address/ReportFeeCheckedSplit.lean',
 'LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit':'LidoSRv3/Audit/Guarantees/PAccount1CheckedFeeSplit.lean',
 'Tests.Verity.ReportFeeCheckedSplitTest':'audit/trio/account-address/Tests/Verity/ReportFeeCheckedSplitTest.lean'}
def git(repo,*args): return subprocess.check_output(['git','-C',str(repo),*args])
def sha(data): return hashlib.sha256(data).hexdigest()
# Remove only the inserted theorem block, recovering every old byte, including
# executable definitions, previous theorem statements/proofs and namespaces.
old=git(ROOT,'show',BASE+':'+MODULES['ReportFeeMint'])
current=(ROOT/MODULES['ReportFeeMint']).read_bytes()
start=current.index(b'/-- Checked loop success determines every exact floor')
end=current.index(b'#print axioms committed_success',start)
assert current[:start]+current[end:]==old
(OUT/'preservation.json').write_text(json.dumps(dict(base=BASE,path=MODULES['ReportFeeMint'],base_sha256=sha(old),current_sha256=sha(current),removed_new_theorem_block_bytes=end-start,all_previous_bytes_identical=True),indent=2)+'\n')
pins={p['name']:p['rev'] for p in json.loads((ROOT/'lake-manifest.json').read_text())['packages']}
for name,pin in pins.items(): assert git(ROOT/'.lake/packages'/name,'rev-parse','HEAD').decode().strip()==pin
sources={m:ROOT/p for m,p in MODULES.items()}
for module in ['LidoSRv3.Audit.Guarantees.PAccount1ActualFeeCasts','Tests.Verity.ReportFeeMintTest']:
    setup=json.loads((ROOT/'.lake/build/ir'/Path(module.replace('.','/')+'.setup.json')).read_text())
    rel=module.replace('.','/')+'.lean'
    own=ROOT/rel
    if not own.exists(): own=ROOT/'audit/trio/account-address'/rel
    sources[module]=own
    for name,arts in setup['importArts'].items():
        prefix,suffix=arts[0].split('/.lake/build/lib/lean/')
        source=Path(prefix)/Path(suffix).with_suffix('.lean')
        if not source.exists(): source=Path(prefix)/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
        assert source.exists(),(name,source)
        sources[name]=source
entries=[]
for module,path in sorted(sources.items()):
    data=path.read_bytes(); absolute=str(path.resolve())
    if '/.lake/packages/' in absolute:
        name,relative=absolute.split('/.lake/packages/',1)[1].split('/',1)
        assert git(ROOT/'.lake/packages'/name,'show',pins[name]+':'+relative)==data
        rel='.lake/packages/'+name+'/'+relative
    else:
        rel=str(path.resolve().relative_to(ROOT.resolve()))
        if rel not in MODULES.values(): assert git(ROOT,'show',BASE+':'+rel)==data,rel
    entries.append(dict(module=module,path=rel,sha256=sha(data)))
(OUT/'source-inputs.json').write_text(json.dumps(dict(entries=entries,package_pins=pins,scope='Actual two prerequisite setup import closures plus the three sequentially compiled new modules; new proof-only ReportFeeMint block byte-isolated.'),indent=2)+'\n')
assert git(CORE,'rev-parse','HEAD').decode().strip()==PIN
corefiles=['contracts/0.8.9/Accounting.sol','contracts/0.8.25/sr/StakingRouter.sol','contracts/0.8.25/sr/SRLib.sol','contracts/0.4.24/Lido.sol','contracts/0.4.24/StETH.sol']
solidity={}
for path in corefiles:
    data=(CORE/path).read_bytes();assert git(CORE,'show',PIN+':'+path)==data
    solidity[path]=sha(data)
(OUT/'solidity-identities.json').write_text(json.dumps(dict(pin=PIN,source_sha256=solidity,fresh_execution=False,scope='Pinned complete source identity for proof-only checked fee split; inherited executable definitions unchanged.'),indent=2)+'\n')
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py')
checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker);checker.ROOT=ROOT
names=[]
for module,path in MODULES.items():
    source=(ROOT/path).read_text();ns=re.search(r'^namespace (\S+)',source,re.M).group(1)
    names.extend(ns+'.'+n for n in re.findall(r'^#print axioms (\S+)',source,re.M))
    assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',re.sub(r'/\-.*?\-/','',source,flags=re.S))
computed=checker.environment_dependencies(names,'Tests.Verity.ReportFeeCheckedSplitTest',None)
assert all(a<={'propext','Classical.choice','Quot.sound'} for a in computed.values())
(OUT/'axioms.json').write_text(json.dumps({n:sorted(a) for n,a in computed.items()},indent=2)+'\n')
print(f'PASS: {len(entries)} exact source identities, {len(pins)} package pins, {len(solidity)} Solidity bodies, {len(computed)} foundation-only kernel axiom sets; every old ReportFeeMint byte preserved.')
