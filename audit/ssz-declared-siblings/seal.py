#!/usr/bin/env python3
"""Digest source-only candidate. Default compares; --write creates the receipt."""
from pathlib import Path
import hashlib,json,argparse,subprocess
ROOT=Path(__file__).resolve().parents[2];OUT=Path(__file__).resolve().parent
arg=argparse.ArgumentParser();arg.add_argument('--write',action='store_true');write=arg.parse_args().write
sources=['LidoSRv3/Audit/Source/SszDeclaredSiblings.lean','LidoSRv3/Audit/Guarantees/PSsz1DeclaredSiblings.lean','LidoSRv3/Tests/SszDeclaredSiblingsRegression.lean']
paths=[ROOT/p for p in sources]+[p for p in OUT.rglob('*') if p.is_file() and p.name!='receipt.json' and '__pycache__' not in p.parts]
files={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(paths))}
summary=json.loads((OUT/'validation/summary.json').read_text())
receipt={'status':'source validation PASS; independent review and integration separate','base':summary['base'],'base_tree':summary['base_tree'],'core_pin':'17005714f151e5502c559932319a3f2f74ac2436','summary':summary,'files':files}
text=json.dumps(receipt,indent=2,sort_keys=True)+'\n';target=OUT/'receipt.json'
if write:target.write_text(text)
else:assert target.read_text()==text,'source/dossier receipt mismatch'
print(f'PASS: {len(files)} exact source/dossier hashes')
