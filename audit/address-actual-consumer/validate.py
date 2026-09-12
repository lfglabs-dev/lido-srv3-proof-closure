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
MODULES = ['LidoSRv3.Audit.Verity.AddressClaimBatchTx', 'LidoSRv3.Audit.Verity.AddressRecipientCallBridge', 'LidoSRv3.Audit.Verity.AddressTx', 'LidoSRv3.Audit.Guarantees.PAddress1', 'LidoSRv3.Audit.Spec.AddressClaimCorrespondence', 'LidoSRv3.Tests.PackDAddressClaimMutants']
NEW = {m.replace(".", "/") + ".lean" for m in MODULES}

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
            assert git(ROOT, 'show', '85a1f338990020f1b41cfbcf260609ed90675252:' + relpath) == data, relpath
        local = True
    entries.append(dict(module=module,path=relpath,local=local,sha256=sha(data)))
(OUT / 'source-inputs.json').write_text(json.dumps(dict(entries=entries, package_pins=pins,
    scope='Actual six-target setup import closures; inherited local sources match base; package sources match pinned git bodies.'), indent=2) + '\n')

spec = importlib.util.spec_from_file_location('trust_checker', ROOT / 'scripts/check_trust_axioms.py')
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)
checker.ROOT = ROOT
groups = {
 'LidoSRv3.Audit.Guarantees.PAddress1': [
  'LidoSRv3.Audit.Guarantees.PAddress1.actual_claim_recipient_effect',
  'LidoSRv3.Audit.Guarantees.PAddress1.actual_claim_withdrawals_to_chain',
  'LidoSRv3.Audit.Guarantees.PAddress1.actual_claim_withdrawals_failure_restores',
  'LidoSRv3.Audit.Verity.AddressRecipientCallBridge.emptyValueCall_success',
  'LidoSRv3.Audit.Verity.AddressClaimBatchTx.claimOne_success_storage',
  'LidoSRv3.Audit.Verity.AddressClaimBatchTx.claimOne_success_guards'],
 'LidoSRv3.Tests.PackDAddressClaimMutants': [
  'LidoSRv3.Tests.PackDAddressClaimMutants.swapped_payout_order_changes_actual_attempts',
  'LidoSRv3.Tests.PackDAddressClaimMutants.wrong_recipient_changes_actual_attempt',
  'LidoSRv3.Tests.PackDAddressClaimMutants.zero_recipient_rejects_before_claim',
  'LidoSRv3.Tests.PackDAddressClaimMutants.failed_batch_restores_world'],
 'LidoSRv3.Audit.Spec.AddressClaimCorrespondence': [
  'LidoSRv3.Audit.Spec.AddressClaimCorrespondence.actual_claim_payout_matches_locked_write']}
computed = {}
for module,names in groups.items():
    computed.update(checker.environment_dependencies(names,module,None))
assert all(a <= {'propext','Classical.choice','Quot.sound'} for a in computed.values()),computed
(OUT/'axioms.json').write_text(json.dumps({n:sorted(a) for n,a in computed.items()},indent=2)+'\n')
for module in MODULES:
    source=(ROOT/(module.replace('.','/')+'.lean')).read_text()
    assert not re.search(r'^\s*(axiom|unsafe)\b|\bsorry\b|\badmit\b',
        re.sub(r'/\-.*?\-/', '', source, flags=re.S),re.M),module
print(f'PASS: {len(entries)} source identities, {len(pins)} package pins, {len(computed)} exact theorem axiom sets; foundations only.')
