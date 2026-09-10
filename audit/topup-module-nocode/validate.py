#!/usr/bin/env python3
"""Recompute exact source identities and scoped kernel axiom dependencies."""
import hashlib
import importlib.util
import json
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = pathlib.Path(__file__).resolve().parent
MODULES = [
    'LidoSRv3.Audit.Source.TopupModuleCall',
    'LidoSRv3.Audit.Guarantees.PTopup2ModuleFailure',
    'LidoSRv3.Tests.TopupModuleCallMutants',
    'LidoSRv3.Tests.TopupBatchRootCallsRegression',
]
NEW = {m.replace('.', '/') + '.lean' for m in MODULES}

def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])

def sha(data):
    return hashlib.sha256(data).hexdigest()

manifest = json.loads((ROOT / 'lake-manifest.json').read_text())
pins = {p['name']: p['rev'] for p in manifest['packages']}
for name, pin in pins.items():
    assert git(ROOT / '.lake/packages' / name, 'rev-parse', 'HEAD').decode().strip() == pin, name

sources = {}
for module in MODULES:
    setup = json.loads((ROOT / '.lake/build/ir' / (module.replace('.', '/') + '.setup.json')).read_text())
    sources[module] = ROOT / (module.replace('.', '/') + '.lean')
    for imported, artifacts in setup['importArts'].items():
        artifact = artifacts[0]
        prefix, suffix = artifact.split('/.lake/build/lib/lean/')
        source = pathlib.Path(prefix) / pathlib.Path(suffix).with_suffix('.lean')
        assert source.exists(), (imported, source)
        sources[imported] = source

entries = []
for module, path in sorted(sources.items()):
    data = path.read_bytes()
    absolute = str(path.resolve())
    if '/.lake/packages/' in absolute:
        name, relative = absolute.split('/.lake/packages/', 1)[1].split('/', 1)
        repo = ROOT / '.lake/packages' / name
        assert git(repo, 'show', pins[name] + ':' + relative) == data, str(path)
        relpath = '.lake/packages/' + name + '/' + relative
        local = False
    else:
        relpath = str(path.resolve().relative_to(ROOT.resolve()))
        if relpath not in NEW:
            assert git(ROOT, 'show', '64f73f101187992db5b9b446852c3063a5a6d5b7:' + relpath) == data, relpath
        local = True
    entries.append(dict(module=module,path=relpath,local=local,sha256=sha(data)))
(OUT / 'source-inputs.json').write_text(json.dumps(dict(entries=entries, package_pins=pins,
    scope='Actual four-target setup import closures; inherited local sources match base; package sources match pinned git bodies.'), indent=2) + '\n')

spec = importlib.util.spec_from_file_location('trust_checker', ROOT / 'scripts/check_trust_axioms.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)
checker.ROOT = ROOT
computed = {}
for module in MODULES:
    source = (ROOT / (module.replace('.', '/') + '.lean')).read_text()
    namespace = re.search(r'^namespace (\S+)', source, re.M).group(1)
    names = []
    for name in re.findall(r'^#print axioms (\S+)', source, re.M):
        names.append(('LidoSRv3.Audit.Source.'+name) if name.startswith('TopupModuleCall.') else namespace+'.'+name)
    assert not re.search(r'\b(sorry|admit|axiom|native_decide|unsafe|implemented_by)\b',
        re.sub(r'/\-.*?\-/', '', source, flags=re.S)), module
    computed.update(checker.environment_dependencies(names, module, None))
assert all(axioms <= {'propext','Classical.choice','Quot.sound'} for axioms in computed.values())
(OUT / 'axioms.json').write_text(json.dumps({n:sorted(a) for n,a in computed.items()},indent=2) + '\n')
print(f'PASS: {len(entries)} source identities, {len(pins)} pins, {len(computed)} independently recomputed theorem axiom sets; foundations only.')
