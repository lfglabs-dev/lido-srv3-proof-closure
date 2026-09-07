# ALLOC-2 consumer acceptance of producer v0

Accepted producer checkpoint: `2a4e9d2a91d257353470677c6101fd91293cf4e4`,
`LidoSRv3/Audit/Source/TrioAlloc1/Interface.lean` and
`audit/trio/alloc1/interface-proposal.md`, inspected with `git show`.
Consumer base: `c7adae04416704a839d56333efad003f0a0f46b7`.
Solidity remains `17005714f151e5502c559932319a3f2f74ac2436`.

This is the consumer's written acceptance, not a record that the orchestrator
has recorded both agreements. No producer file is imported, copied into its
namespace, or modified. Incompatible interface changes remain prohibited.

| Boundary | Accepted meaning and consumer obligation |
| --- | --- |
| Order and filtering | Preserve the complete EnumerableSet enumeration, including inactive and WC01 top-up rows. IDs and addresses are ghost identity observations, never indices. |
| Capacities | Use exact producer words; permit capacity below allocation, equality, zero, duplicates and saturated rows. Consumer selection tests allocation < capacity. No positive-headroom hypothesis. |
| Units | Demand and both arrays are WC01 validator equivalents. Config maxEB fields and stake are wei. The outer conversion back to wei is checked and may revert even after distribution succeeds. |
| Types | Accept Fin (2^256), Fin (2^160), and List (Fin 256); exact equal lengths derive from CapacityOutput fields. Consumer standalone entry must still model unequal arrays because its external ABI admits them. |
| Bounds | No assumed count <= 32, share reachability, global arithmetic success, or callee success. Word width follows from types; equal length follows from output. Pointer, byte decoding, count and arithmetic bounds require named derivations. |
| Memory | Accept ArrayAt and MemoryArraysRelated as the proposed internal word-memory relation, including disjoint nonwrapping regions. This does not establish byte decoding or copied external-library ABI. Caller allocated must retain its original values until delta conversion. |
| Failures and traces | Accept Failure variants as semantic distinctions. Raw panic/decoder/revert/exception encodings and precedence need execution-layer correspondence, including arbitrary callee rejection. Attempts are separate instrumentation; committed events, storage and balances are observable. |

The planned consumer-owned bridge declaration is
`LidoSRv3.Audit.Source.TrioAlloc2.producer_success_establishes_consumer_premises`.
It is **not implemented or proved** at this checkpoint. Its premise must be the
producer executor's actual successful result under the shared state/input relation;
its conclusion must derive the consumer entry relation and all needed bounds.
Merely assuming MemoryArraysRelated or consumer Preconditions alongside producer
success will not close composition. Producer v0 contains output/view types and
length lemmas, but no executor-success theorem from which this bridge can yet be
proved. The external library and post-library checked wei conversion remain
consumer obligations, including revert propagation and ordered observations.

Source verification: read pinned SRLib.sol:391–431 and 493–559 and the complete
MinFirstAllocationStrategy.sol and Math256.sol. The zero-module return precedes
division; zero demand still executes the producer and checked row conversion.
Standalone MinFirst skips scans at zero demand; otherwise short capacities fail
during indexing, and surplus capacities are ignored. Preserve those boundaries.

PR243 read-only observation: OPEN, unmerged, head
`0347f67558c4c70c3c94f97d309955002b348f2f`. Its
`audit/MINFIRST-SOURCE-ENTRY.md` was inspected from that ref, not treated as base
content or reused proof. No PR230/231/243 comments, reviews or mutations.

Excluded claims: deployed-bytecode refinement, gas equivalence, full consensus
truth, primitive crypto correctness or universal Keccak injectivity. Compiler,
linking and runtime provenance assumptions must remain explicit. Callback scope
must be specified in the eventual state/input relation, not silently removed.
