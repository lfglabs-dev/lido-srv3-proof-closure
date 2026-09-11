#!/usr/bin/env python3
"""Verify the exact additive executor delta, actual imported sources and kernel axioms."""
from pathlib import Path
import hashlib, importlib.util, json, re, subprocess
ROOT=Path(__file__).resolve().parents[2]
OUT=Path(__file__).resolve().parent
BASE='53871e66833bd45190eb83dffc15439ceafa9c42'
CORE=Path('/tmp/lido-ssz-proof-committed/lido-core')
PIN='17005714f151e5502c559932319a3f2f74ac2436'
MODULES={
 'AccountingCall':'audit/trio/account-address/AccountingCall.lean',
 'ReportFeeAccountingCall':'audit/trio/account-address/ReportFeeAccountingCall.lean',
 'LidoSRv3.Audit.Guarantees.PAccount1AccountingCall':'LidoSRv3/Audit/Guarantees/PAccount1AccountingCall.lean',
 'LidoSRv3.Tests.AccountAccountingCall':'LidoSRv3/Tests/AccountAccountingCall.lean'}

def git(repo,*args): return subprocess.check_output(['git','-C',str(repo),*args])
def sha(data): return hashlib.sha256(data).hexdigest()
pins={p['name']:p['rev'] for p in json.loads((ROOT/'lake-manifest.json').read_text())['packages']}
for name,pin in pins.items(): assert git(ROOT/'.lake/packages'/name,'rev-parse','HEAD').decode().strip()==pin
sources={m:ROOT/p for m,p in MODULES.items()}
for module in ['LidoSRv3.Tests.AccountPhysicalPause','LidoSRv3.Audit.Guarantees.PAccount1PhysicalPause','LidoSRv3.Audit.Source.TrioReserve1.ABI']:
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
        if '/.lake/packages/' not in str(source.resolve()):
            local=ROOT/Path(suffix).with_suffix('.lean')
            if not local.exists(): local=ROOT/'audit/trio/account-address'/Path(suffix).with_suffix('.lean')
            assert local.read_bytes()==source.read_bytes(),(name,source,local)
            assert Path(arts[0]).read_bytes()==(ROOT/'.lake/build/lib/lean'/suffix).read_bytes(),name
            source=local
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
(OUT/'source-inputs.json').write_text(json.dumps(dict(entries=entries,package_pins=pins,scope='Actual three prerequisite setup import closures plus four sequentially compiled new modules; every old local source body unchanged at base; cached setup absolute paths checked byte-identical against current source and actual local olean.'),indent=2)+'\n')
assert git(CORE,'rev-parse','HEAD').decode().strip()==PIN
corefiles=['contracts/0.8.9/Accounting.sol','contracts/0.8.25/sr/StakingRouter.sol','contracts/0.8.25/sr/SRLib.sol','contracts/0.4.24/Lido.sol','contracts/0.4.24/StETH.sol','contracts/0.4.24/utils/Pausable.sol','contracts/0.4.24/utils/UnstructuredStorageExt.sol','contracts/0.8.9/LidoLocator.sol','contracts/0.8.9/proxy/OssifiableProxy.sol','contracts/common/interfaces/ILidoLocator.sol']
solidity={}
for path in corefiles:
    data=(CORE/path).read_bytes();assert git(CORE,'show',PIN+':'+path)==data
    solidity[path]=sha(data)
(OUT/'solidity-identities.json').write_text(json.dumps(dict(pin=PIN,source_sha256=solidity,fresh_execution=False,scope='Pinned complete core source identities for actual accounting CALL; reused full-Lido37 and fresh full getter/proxy compiler inputs are recorded in compiler-identities.json.'),indent=2)+'\n')
assert (ROOT/'scripts/check_trust_axioms.py').read_bytes()==git(ROOT,'show',BASE+':scripts/check_trust_axioms.py')
spec=importlib.util.spec_from_file_location('trust',ROOT/'scripts/check_trust_axioms.py')
checker=importlib.util.module_from_spec(spec);spec.loader.exec_module(checker);checker.ROOT=ROOT
names=[]
for module,path in MODULES.items():
    source=(ROOT/path).read_text();ns=re.search(r'^namespace (\S+)',source,re.M).group(1)
    names.extend(n if '.' in n else ns+'.'+n for n in re.findall(r'^#print axioms (\S+)',source,re.M))
    assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',re.sub(r'--[^\n]*','',re.sub(r'/\-.*?\-/','',source,flags=re.S)))
original_probe=checker.lean_probe_output
def capture_probe(*args,**kwargs):
    output=original_probe(*args,**kwargs)
    (OUT/'scoped-axiom-probe.log').write_text(output)
    return output
checker.lean_probe_output=capture_probe
computed=checker.environment_dependencies(names,'LidoSRv3.Tests.AccountAccountingCall',None)
(OUT/'axiom-query-identities.json').write_text(json.dumps({
    'checker_sha256':sha((ROOT/'scripts/check_trust_axioms.py').read_bytes()),
    'probe_template_sha256':sha(checker.TRUST_DEPENDENCY_PROBE.encode()),
    'module_loaded_as_data':'LidoSRv3.Tests.AccountAccountingCall',
    'probe_syntax_import':'Lean',
    'names':sorted(names)},indent=2)+'\n')
assert all(a<={'propext','Classical.choice','Quot.sound'} for a in computed.values())
(OUT/'axioms.json').write_text(json.dumps({n:sorted(a) for n,a in computed.items()},indent=2)+'\n')
for module,path in MODULES.items():
    records=json.loads((OUT/'normal-build-identities.json').read_text())
    out=ROOT/'.lake/build/lib/lean'/module.replace('.','/')
    assert records[module]['source_sha256']==sha((ROOT/path).read_bytes())
    assert records[module]['olean_sha256']==sha(Path(str(out)+'.olean').read_bytes())
    assert records[module]['ilean_sha256']==sha(Path(str(out)+'.ilean').read_bytes())
for path in ['lakefile.lean','lake-manifest.json','lean-toolchain']:
    assert (ROOT/path).read_bytes()==git(ROOT,'show',BASE+':'+path)
print(f'PASS: {len(entries)} exact source identities, {len(pins)} package pins, {len(solidity)} Solidity bodies, {len(computed)} foundation-only kernel axiom sets; all prior source bodies unchanged.')
