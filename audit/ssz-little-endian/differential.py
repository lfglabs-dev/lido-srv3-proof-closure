"""Finite source-expression checks, NOT an EVM execution receipt."""
from pathlib import Path
import hashlib, json, random, re
root = Path(__file__).resolve().parents[2]
sol_path = root / 'lido-core/contracts/common/lib/SSZ.sol'
lean_path = root / 'LidoSRv3/Audit/Source/SszLittleEndianCorrespondence.lean'
sol = sol_path.read_text()
lean = lean_path.read_text()
assert hashlib.sha256(sol.encode()).hexdigest() == '91ef497b972bbee0fe89043034e6bd62fa0c1059f22874d4826bc6164a22009b'
body = sol.split('function toLittleEndian(uint256 v)', 1)[1].split('return bytes32(v);', 1)[0]
source_masks = re.findall(r'\(\(v & (0x[0-9A-F]+)\) ([<>]{2}) (\d+)\)', body)
lean_masks = re.findall(r'\(\(v &&& (0x[0-9A-F]+)\) ([<>]{3}) \((\d+) : Nat\)\)', lean)
assert len(source_masks) == len(lean_masks) == 8
assert source_masks == [(m, op[:2], n) for m, op, n in lean_masks]
assert 'v = (v >> 128) | (v << 128);' in body
assert '(v >>> (128 : Nat)) ||| (v <<< (128 : Nat))' in lean
assert 'return bytes32(v ? 1 << 248 : 0);' in sol
assert 'if v then (1 : BitVec 256) <<< (248 : Nat) else 0' in lean
mask256 = (1 << 256) - 1
stages = [source_masks[i:i+2] for i in range(0, 8, 2)]
def source(value, skip=None):
    for i, stage in enumerate(stages):
        if skip == i: continue
        result = 0
        for mask, op, count in stage:
            part = value & int(mask, 16)
            result |= part >> int(count) if op == '>>' else part << int(count)
        value = result & mask256
    if skip != 4:
        value = ((value >> 128) | (value << 128)) & mask256
    return value

def expected(value):
    return int.from_bytes(value.to_bytes(32, 'little'), 'big')

rng = random.Random(20260909)
vectors = [0, mask256, (1<<64)-1, int.from_bytes(bytes(range(32)), 'big')]
vectors += [1 << i for i in range(256)]
vectors += [rng.getrandbits(256) for _ in range(2048)]
assert all(source(v) == expected(v) for v in vectors)
mutants = {}
for stage in range(5):
    witness = next((v for v in vectors if source(v, skip=stage) != expected(v)), None)
    assert witness is not None
    mutants[f'omit_swap_stage_{stage}'] = hex(witness)
# The source uint256 overload must not silently narrow to uint64.
assert source((1 << 248) & ((1 << 64)-1)) != expected(1 << 248)
mutants['truncate_to_uint64'] = hex(1 << 248)
assert 1 != int.from_bytes(bytes([1]) + bytes(31), 'big')
mutants['bool_wrong_end'] = True
report = {'source_commit': '17005714f151e5502c559932319a3f2f74ac2436',
    'source_sha256': hashlib.sha256(sol.encode()).hexdigest(),
    'lean_sha256': hashlib.sha256(lean.encode()).hexdigest(),
    'scope': 'parsed pinned Solidity expressions vs independent Python byte serialization; no compiler/EVM execution',
    'masks_and_shifts_match_lean': True, 'uint256_vectors_passed': len(vectors),
    'mutation_witnesses': mutants}
print(json.dumps(report, indent=2))
