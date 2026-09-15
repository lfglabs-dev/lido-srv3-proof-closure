#!/usr/bin/env python3
"""The registry guard must reject a moved-away or misspelled proof target."""
import json
from pathlib import Path
import tempfile
from check_reproduction_targets import check

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    (root / 'audit').mkdir()
    (root / 'LidoSRv3/Audit/Guarantees/Composition').mkdir(parents=True)
    name = 'LidoSRv3.Audit.Guarantees.Composition.SszDeclaredSiblings'
    path = root / (name.replace('.', '/') + '.lean')
    path.write_text('-- fixture\n')
    registry = root / 'audit/guarantees.yaml'
    row = {'id': 'P-SSZ-1', 'reproduction': {'command': 'lake build ' + name}}
    registry.write_text(json.dumps({'guarantees': [row]}))
    assert check(root) == 1
    row['fidelity'] = {'covered': ['Proof: ' + str(path.relative_to(root))]}
    registry.write_text(json.dumps({'guarantees': [row]}))
    assert check(root) == 1
    row['fidelity']['covered'] = ['Proof: LidoSRv3/Audit/Spec/MovedProof.lean']
    registry.write_text(json.dumps({'guarantees': [row]}))
    try:
        check(root)
    except ValueError as error:
        assert 'missing fidelity source' in str(error)
    else:
        raise AssertionError('accepted a removed source path in a covered claim')
    row['fidelity']['covered'] = []
    row['fidelity']['missing'] = ['See LidoSRv3/Audit/Verity/ConsolidationEthUnboundedFuel.lean']
    registry.write_text(json.dumps({'guarantees': [row]}))
    try:
        check(root)
    except ValueError as error:
        assert 'missing fidelity source' in str(error)
    else:
        raise AssertionError('accepted a stale citation in a missing obligation')
    row['fidelity']['missing'] = []
    row['reproduction']['command'] = 'lake build LidoSRv3.Audit.Source.SszDeclaredSiblings'
    registry.write_text(json.dumps({'guarantees': [row]}))
    try:
        check(root)
    except ValueError as error:
        assert 'missing reproduction target' in str(error)
    else:
        raise AssertionError('accepted the retired module path')
print('reproduction target regression: moved-away target rejected')
