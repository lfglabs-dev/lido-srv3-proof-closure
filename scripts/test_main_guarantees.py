"""Main claim mutations must fail independently of the legacy registrations."""
import copy
import json
from pathlib import Path
import generate_ux2
from main_guarantees import load_main, main_record


def main():
    root = Path(__file__).resolve().parents[1]
    context = {
        'main_results': load_main(root),
        'declarations': generate_ux2.declarations(root),
        'assumptions': {row['id']: row for row in json.loads(
            (root / 'audit/assumptions.yaml').read_text())['assumptions']},
    }
    mutations = [
        ('theorems', ['LidoSRv3.Audit.Source.Nonexistent.result'], 'expected exactly one declaration'),
        ('assumptions', ['A-NONEXISTENT'], 'unknown main assumption'),
        ('conditions', [], 'invalid main result conditions'),
    ]
    for key, value, diagnostic in mutations:
        changed = copy.deepcopy(context)
        changed['main_results']['P-ALLOC-2'][key] = value
        try:
            main_record('P-ALLOC-2', changed, generate_ux2.theorem_record, generate_ux2.fail)
        except SystemExit as error:
            if diagnostic not in str(error):
                raise
        else:
            raise SystemExit(f'{key}: main registry mutation was accepted')
    closed = copy.deepcopy(context)
    closed['main_results']['P-TOPUP-2']['missing'] = []
    resolved = main_record('P-TOPUP-2', closed, generate_ux2.theorem_record, generate_ux2.fail)
    assert resolved['main_result']['missing'] == []
    assert resolved['main_result']['theorems']
    print('main guarantee declaration, assumption and condition mutations rejected')


if __name__ == '__main__':
    main()
