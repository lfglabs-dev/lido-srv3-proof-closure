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

The candidate depends on exact producer `8269ac576cf119975a7e9954459cd4aa04d5cd82`.
`prepare.py` checks that its interface is byte-identical to accepted v0
`2a4e9d2a91d257353470677c6101fd91293cf4e4` and materializes its six exact Git blobs
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

Historical job `d6b747be-05b7-486a-b03c-bfb97f840ad1` against producer
`5f1683eaf753ff73aec6f1e787cb7f68bedcf056`, old-agent, exit 0, 21 jobs,
compiled the complete producer/consumer source closure. The historical receipt records its verified source bundle; `source-identity.json`
now records the current candidate described below.
The receipt is in the parent audit directory. Both bridge theorem inspections
report only propext and Quot.sound. This is implementation evidence, not
independent certification or full-suite validation.

The current candidate includes the producer's Bytes and Memory modules.
`LibraryABI.lean` uses that exact byte codec for bounds-checked array decoding,
standard dynamic-array arguments, return tuples and Panic(uint256) bytes.
`decodeArguments_encoded`, `decodeReturn_encoded` and `run_encoded` prove canonical
byte round trips and the all-outcome bridge to the decoded consumer. The byte
extent bound is explicit; uint256 count representability alone does not derive
it. This remains an open producer-allocation/reachability obligation, not an
assumed count<=32 shortcut. Compiler dispatch, memory allocation/copying, full
noncanonical input correspondence, parent conversion/rollback and Verity runtime
execution remain open. The old decoded bridge is still checked at the new pin.

`LibraryABIVectors.lean` executes the byte decoder, loop and encoder for eleven
canonical/malformed cases. Receipt 6e204674-c98f-4e7a-b66c-4b5e18947deb is
successful, 30 jobs, complete 29-file source/config closure; source-identity.json
records every file. The new axiom reports contain only propext, Classical.choice
and Quot.sound. The Solidity runner accepts this as a second receipt and compares
the model's exact input and output bytes with the pinned public library.

Coordination remains pending: ask_worker again returned writer_identity_stale
for the producer's existing PR #245 / trio-alloc1 writer. No tags were changed.

The current parent checkpoint adds Parent.lean and ParentVectors.lean and checks
all 32 source/config files in successful 33-job receipt
411a7646-5694-42fc-9173-37012c66f717. The previous 29-file receipt is historical.
Parent.run executes the actual producer followed by the decoded proportional
consumer and ordered wei conversion; eight paired parent vectors include late
conversion overflow and producer rejection. See ../checkpoint-parent.md for the
remaining universal, physical-memory, Verity and review obligations.
