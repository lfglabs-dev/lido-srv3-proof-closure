# Physical metadata before the actual deposit continuation

Public consumers: `PDeposit1.actual_physical_metadata_before_calls` and
`actual_physical_metadata_failure_restores`. They support the DEPOSIT-1
state/failure promise. They consume `PhysicalMetadata.execute`, whose computed
allocation/module preparation is followed by the physical writes, source
event and actual `LiveBeacon.suffix` in that order. All eight full guarantees
remain OPEN.

At core17005714, StakingRouter.sol976 updates the module before the zero-key
return at978 and Lido withdrawal at983. Lines1054–1056 call SRLib's update then
emit StakingRouterETHDeposited. SRLib.sol896–901 assigns timestamp then block
number as uint64. SRTypes places both fields in the low128 bits of
ModuleState.deposits (mapping-entry slot1); maxDepositsPerBlock and
minDepositBlockDistance occupy the upper128 bits. SRStorage selects the mapping
at the ERC-7201 router root. ISRBase.sol33 indexes the module ID in the event.

The new executor hashes the actual two mapping ABI words, wraps the slot+1
addition at uint256, performs both physical read/modify/writes and appends the
semantic event before invoking the suffix. Timestamp and block number come
from that live world's environment, not the older separately supplied Context
fields. Their uint64 truncation and both preserved upper fields follow for
every word, without a packing premise or an address restriction. The zero-key
branch retains the physical writes and event and makes no withdrawal/beacon
call. The nonzero branch exposes a necessary SuffixCommitment: its actual
withdrawal receives the updated world, and its actual beacon loop consumes the
withdrawal-returned world. Root rollback restores the physical word, logs,
ledger and allocation transcript after a failure.

Three kernel regressions check the actual root's zero-key effects, a withdrawal
callback reading the updated word/event before rejecting (and the restored
root), and mapping-slot wrap. Three Solidity tests check the same scoped
update/zero-return/withdraw fragment: both packed fields and unchanged upper
fields, actual callback amount/count, selected event topics/data, and rollback
after callback failure. The Solidity harness copies the relevant struct and
assignments and isolates that source fragment; it is not the full router,
SRLib deployment, module prefix or beacon loop. The complete pinned source is
part of the independent review packet. Selected event-byte tests do not prove
universal LOG encoding correspondence for the semantic Live.Log representation.

The original LiveBeacon executor and its integrated pipeline-conservation
theorem remain available. They are not silently replaced by an equality to
this different, corrected world transition. Composing their necessary ledger
proof with this physical prefix still requires the source configuration
binding at the updated world. In particular, no new alias, hash separation or
callback-preservation premise has been added to fake that composition. The
supplied storage/oracle/module outcome in the prepared prefix, source Context
admission, actual outer ABI/error bytes, deployed configuration and full LOG
encoding remain source-specific open obligations. The accepted general solc,
declared Verity, crypto, gas and consensus boundaries are unchanged.
