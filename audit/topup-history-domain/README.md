# TOPUP history-domain diagnostic

The existing TOPUP-2 post-return timing theorem requires 0 < block.number < 2^32.
This is not yet a reachability invariant. Three new tests execute the unmodified
pinned public TopUpGateway.topUp inherited by the accepted #278 harness:

- At 2^32-1, after a positive-limit successful call, a second call in the same
  block reverts with MinBlockDistanceNotMet. Exactly one router call commits.
- At 2^32, the actual history write truncates the block to the zero sentinel;
  the same proof can be submitted again and a second router call commits.
- At 2^32+123, the nonzero truncated previous block also admits a repeat,
  because full block.number minus that uint32 word exceeds the positive delay.

The timestamp is 1606824023 + 12*block.number. Actual uint32 timestamp truncation
also makes the same supplied child timestamp newer than the stored word.
The tests retain positive configured minBlockDistance=1. They do not forge
storage, bypass role/pause/input/root-age/credential/SSZ guards, or override
any gateway operation. Initialization uses existing source setters and a role
grant in a standalone fixture, not an initialized production proxy.

The #278 router is an explicit recorder; the exact root is mocked and the
independent synthetic header still has slot4096 and opaque state fields.
These tests therefore refute unconditional post-return same-block exclusion
for this source execution domain. They do not establish authenticated consensus
reachability, actual staking-router/module/beacon funding, an ETH budget breach
or a deployed vulnerability. No new universal TOPUP-2 theorem is credited.
The guard's uint32 horizon cannot simply be called an invariant of its own
successful source transitions: those transitions perform truncating writes.

Fresh Forge: 3 tests pass, solc0.8.25/viaIR/optimizer200/Cancun. All23 compiler
input Keccaks were matched to current files, and pinned core sources checked
byte-for-byte against17005714. Original #278 helpers and external OpenZeppelin
5.2.0 source cache are unchanged. No new installation or full-source campaign
acceptance. Pending independent review; no commit/PR/site credit yet.

The whole useful TOPUP-2 promise still requires the actual router and nested/history
composition. If the promise is refuted under its intended domain, preserve it
as unresolved and seek a substantive decision with the complete evidence.
Do not silently weaken the promise or claim a current-mainnet exploit.

## Source and theorem mapping

At core17005714, TopUpGateway._isBlockDistancePassed (323-325) consumes the
uint32 last-block write in _setLastTopUpData (340-345). The public topUp
invokes that update only after the external router returns and totalLimits>0
(232-236). The configured uint16 delay comes from _setMinBlockDistance
(362-366), which rejects zero and values above65535 before truncation.

TopupHistoryDomain.truncated_blocks_reopen proves the truncation behavior for
EVERY full block number >=2^32 and EVERY representable uint16 delay. It derives
the subtraction and comparison result; no wrapped-state readback is a premise.
truncated_timestamp_is_older proves the analogous timestamp condition.
configured_does_not_give_unrestricted_exclusion negates the proposed universal
post-return exclusion starting from a successful setter configuration. Its
Configured predicate remains setter/update reachability only. No consensus or
full-transaction reachability is silently inferred from that predicate.

The new three-theorem source is integrated into the existing library glob.
The targeted496-job build reuses dependencies and rebuilds that source in2.4s;
all three axiom queries use only propext and Quot.sound. The earlier direct
check was also green but receives no additional build count. Package/local
source identities come from the actual Lake import manifest. No new compiler,
cryptographic, physical-storage or funding assumption is discharged by these
checks. All eight complete guarantees remain OPEN.
