"""Pinned file and source-anchor verification, not semantic equivalence."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[2]
PIN = '17005714f151e5502c559932319a3f2f74ac2436'
ANCHORS = {
    'contracts/0.8.25/CLValidatorVerifier.sol': [
        'uint8 private constant STATE_ROOT_DEPTH = 3;',
        'uint256 private constant STATE_ROOT_POSITION = 3;',
        'GIndex public immutable GI_STATE_ROOT = pack((1 << STATE_ROOT_DEPTH) + STATE_ROOT_POSITION, STATE_ROOT_DEPTH);',
        'GIndex gIndexValidator = concat(GI_STATE_ROOT, _getValidatorGI(_validatorIndex, _beaconRootData.slot));',
        'uint256 private constant SLOT_PROPOSER_PARENT_PROOF_OFFSET = 2;',
        'if (_proof[_proof.length - SLOT_PROPOSER_PARENT_PROOF_OFFSET] != parentSlotProposer)',
        'GIndex gI = _provenSlot < PIVOT_SLOT ? GI_FIRST_VALIDATOR_PREV : GI_FIRST_VALIDATOR_CURR;',
        'return gI.shr(_offset);',
    ],
    'contracts/common/lib/GIndex.sol': [
        'if (gI > type(uint248).max)',
        'return uint256(unwrap(self)) >> 8;',
        'return 1 << pow(self);',
        'return uint8(uint256(unwrap(self)));',
        'if ((i % w) + n >= w)',
        'return pack(i + n, pow(self));',
        'if (lhsMSbIndex + 1 + rhsMSbIndex > 248)',
        'pack((lindex << rhsMSbIndex) | (rindex ^ (1 << rhsMSbIndex)), pow(rhs));',
    ],
    'contracts/common/lib/SSZ.sol': [
        'let scratch := shl(5, and(index, 1))',
        'index := shr(1, index)',
        'if iszero(eq(index, 1))',
    ],
    'scripts/upgrade/upgrade-params-mainnet.toml': [
        'gIFirstValidatorPrev = "0x0000000000000000000000000000000000000000000000000096000000000028"',
        'gIFirstValidatorCurr = "0x0000000000000000000000000000000000000000000000000096000000000028"',
    ],
}
results = []
for name, anchors in ANCHORS.items():
    raw = (ROOT / 'lido-core' / name).read_bytes()
    pinned = subprocess.check_output(['git', '-C', str(ROOT / 'lido-core'), 'show', f'{PIN}:{name}'])
    assert raw == pinned, f'working source differs from pin: {name}'
    source = raw.decode()
    for anchor in anchors:
        assert anchor in source, f'missing source anchor: {name}: {anchor}'
    results.append({'file': name, 'sha256': hashlib.sha256(raw).hexdigest(), 'anchors': len(anchors)})
print(json.dumps({'source_pin': PIN, 'scope': 'file identity and textual anchor checks only', 'files': results}, indent=2))
