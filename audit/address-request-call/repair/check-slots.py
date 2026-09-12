#!/usr/bin/env python3
"""Compare consumed Lean literals with pinned Solidity preimages and assembly."""
from pathlib import Path
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
PIN = '17005714f151e5502c559932319a3f2f74ac2436'
CORE = Path('/tmp/lido-ssz-proof-committed/lido-core')
BRIDGE = ROOT / 'LidoSRv3/Audit/Verity/AddressRecipientCallBridge.lean'
BATCH = ROOT / 'LidoSRv3/Audit/Verity/AddressClaimBatchTx.lean'
OUT = Path(__file__).resolve().parent
assembly = (OUT.parent / 'solidity/RequestHarness.asm').read_text()
rows = []
for name, suffix, erc721 in [
    ('lastRequestIdPosition', 'lastRequestId', False),
    ('lastReportTimestampPosition', 'lastReportTimestamp', False),
    ('queuePosition', 'queue', False),
    ('requestsByOwnerPosition', 'requestsByOwner', False),
    ('checkpointsPosition', 'checkpoints', False),
    ('lastFinalizedRequestIdPosition', 'lastFinalizedRequestId', False),
    ('lastCheckpointIndexPosition', 'lastCheckpointIndex', False),
    ('lockedEtherAmountPosition', 'lockedEtherAmount', False),
    ('tokenApprovalsPosition', 'tokenApprovals', True),
    ('operatorApprovalsPosition', 'operatorApprovals', True),
]:
    contract = 'WithdrawalQueueERC721' if erc721 else 'WithdrawalQueue'
    preimage = 'lido.' + contract + '.' + suffix
    source = 'contracts/0.8.9/' + ('WithdrawalQueueERC721.sol' if erc721 else 'WithdrawalQueueBase.sol')
    pinned = subprocess.check_output(['git', '-C', str(CORE), 'show', PIN + ':' + source], text=True)
    assert 'keccak256("' + preimage + '")' in pinned, source
    matches = [(p, re.search(r'def ' + name + r' : Nat :=\s*(0x[0-9a-f]+)', p.read_text()))
               for p in (BRIDGE, BATCH)]
    matches = [(p, m) for p, m in matches if m]
    assert len(matches) == 1, name
    lean_file, match = matches[0]
    expected = subprocess.check_output(['cast', 'keccak', preimage], text=True).strip()
    assert int(match[1], 16) == int(expected, 16), name
    in_assembly = hex(int(expected, 16)) in assembly
    if name in {'lastRequestIdPosition', 'lastReportTimestampPosition', 'queuePosition', 'requestsByOwnerPosition'}:
        assert in_assembly, name
    rows.append(dict(name=name, preimage=preimage, source=source, value=expected,
                     lean_file=str(lean_file.relative_to(ROOT)),
                     present_in_request_assembly=in_assembly))
for name, signature in [
    ('transferFromSelector', 'transferFrom(address,address,uint256)'),
    ('getSharesByPooledEthSelector', 'getSharesByPooledEth(uint256)'),
    ('getPooledEthBySharesSelector', 'getPooledEthByShares(uint256)'),
    ('erc20TransferSelector', 'transfer(address,uint256)'),
]:
    expected = subprocess.check_output(['cast', 'sig', signature], text=True).strip()
    match = re.search(r'def ' + name + r' : Nat :=\s*(0x[0-9a-f]+)', BRIDGE.read_text())
    assert match and int(match[1], 16) == int(expected, 16), name
    rows.append(dict(name=name, signature=signature, value=expected))
print(json.dumps(dict(pin=PIN, checks=rows, verdict='PASS'), indent=2))
