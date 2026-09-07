# Candidate producer/consumer composition

`Composition.lean` is consumer-owned and defines:

- `producer_success_establishes_consumer_premises`: from the actual successful
  `TrioAlloc1.produce`, derives equal lengths and a bucket length below 2^256.
  The latter is obtained from `producer_router_order`, the actual storage count
  word, and `CapacityOutput.allocations_length`; it is not an assumed memory or
  arithmetic-success predicate.
- `producer_then_consumer_succeeds`: passes the actual producer arrays and the
  same `input.depositsToAllocate` to the consumer, deriving success, demand bound,
  conservation, and preserved module count.

The boundary is explicitly **decoded arrays**. This does not prove byte-memory
or copied ABI correspondence, the public parent conversion, producer Solidity
source refinement, adversarial callback realization, or parent effects/rollback.
Those remain in the original task scope. Producer/consumer agreement was requested
through the orchestrator; an explicit producer confirmation is still pending.

The candidate depends on exact producer `5f1683eaf753ff73aec6f1e787cb7f68bedcf056`.
`prepare.py` checks that its interface is byte-identical to accepted v0
`2a4e9d2a91d257353470677c6101fd91293cf4e4` and materializes its four exact Git blobs
only in the private verification checkout. No producer-owned path in the
implementation branch is created or edited. The composition is staged outside
the production glob while the producer remains an unintegrated candidate; this
is an outstanding integration obligation, not a substitute for the root build.

Preparation from repository root, once the private base checkout exists:

```
python3 audit/trio/alloc2/composition/prepare.py
```

From `../temp/alloc2-composition/audit/trio/alloc2/composition`:

```
REMOTE_BUILD_PASSIVE=1 REMOTE_BUILD_ESTIMATED_DISK_GB=2 remote-lean-build lake build
```

Job `d6b747be-05b7-486a-b03c-bfb97f840ad1`, old-agent, exit 0, 21 jobs,
compiled the complete producer/consumer source closure. `source-identity.json`
records the base, producer, accepted interface and all 20 source/config hashes.
The receipt is in the parent audit directory. Both bridge theorem inspections
report only propext and Quot.sound. This is implementation evidence, not
independent certification or full-suite validation.
