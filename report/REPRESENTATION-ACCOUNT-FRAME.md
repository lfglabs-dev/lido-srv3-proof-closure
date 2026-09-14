# Account-frame representation milestone

Before this change, queue finalization used `readContractSlot`/`writeContractSlot`
at the queue address, but the claim storage bridge only replaced `sender` on the
whole core. Its `readSlot`/`writeSlot` operations therefore used the independent
unqualified storage channel. A finalized value in another account's channel
could incorrectly determine whether the executing queue reached its claim body.

`AccountFrame.enter` projects the executing account's words into the local
source interpreter and installs sender/self. `AccountFrame.commit` writes only
that account's physical words back to the original core. It preserves other
accounts, including Verity's documented account-zero alias. No equality between
independent storage maps is assumed. Frame-local context/memory is not committed.

The actual `claimStorage` producer now uses this frame. Its registered universal
ADDRESS consumer retains the original source-projection equivariance and actual
unbounded batch/CALL/rollback relation, with the same physical account used for
storage and recipient funding. `ClaimEffect` additionally states that the
storage stage writes its result to that account and preserves foreign-account
words before calling the recipient. Arbitrary callback effects still flow through
the returned World and into the next claim; no false post-callback preservation
claim is made.

The new `AddressAccountFrame` regression module checks:

- QueueFinalize's literal finalized/locked positions agree with claim positions.
- Its actual Live write primitive feeds the claim frame's read for every account,
  world and word, without a supplied correspondence premise.
- A nonzero unqualified finalized word does not authorize an unfinalized nonzero
  queue; the real batch fails before any recipient attempt.
- Frame write-back preserves every foreign account, with no singleton-world
  restriction and no new native-decision axiom.

This is a representation repair consumed by an existing registered parent. It
is **not** completion of the representation roadmap: full finalize→claim
transaction correspondence, other writer frame migrations, whole-world/code
renaming, ABI/deployment identity and runtime/hash refinement remain open. The
ALLOC arbitrary-reply counterexample and all prior semantic obligations remain.

Targeted reproduction, after confirming the pushed full SHA and inspecting any
existing exact-SHA receipt:

```sh
REMOTE_BUILD_NODE_ID=dgx-spark REMOTE_BUILD_PASSIVE=1 remote-lean-build lake build LidoSRv3.Audit.Guarantees.PAddress1 LidoSRv3.Tests.AddressAccountFrame LidoSRv3.Tests.PackDAddressClaimMutants
```

Execution results belong to the exact-head handoff. A successful author job is
not an independent verdict. See `audit/OPEN-INDEPENDENT-VALIDATION.md` for the
named full-gate/axiom-recomputation dependency and reviewer 80fe125b's scope.
