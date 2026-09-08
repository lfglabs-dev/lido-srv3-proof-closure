"""Main claim mutations must fail independently of the legacy registrations."""
import json
import tempfile
from pathlib import Path
from test_ux2 import copy_tree, expect


def main():
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        copy_tree(root)
        path = root / 'audit/trio/main-guarantees.json'
        original = path.read_text()
        mutations = [
            ('theorems', ['LidoSRv3.Audit.Source.Nonexistent.result'], 'expected exactly one declaration'),
            ('assumptions', ['A-NONEXISTENT'], 'unknown main assumption'),
            ('conditions', [], 'invalid main result conditions'),
        ]
        for key, value, diagnostic in mutations:
            data = json.loads(original)
            data['guarantees']['P-ALLOC-2'][key] = value
            path.write_text(json.dumps(data))
            expect(root, 'generate', False, diagnostic)
        path.write_text(original)
        expect(root, 'check', True, '11 guarantee records match')
    print('main guarantee declaration, assumption and condition mutations rejected')


if __name__ == '__main__':
    main()
