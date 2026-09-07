# Canonical external-library byte boundary

The consumer-owned LibraryABI module now executes ABI argument decoding, the
proportional loop and successful return/Panic encoding. It uses the actual
producer byte codec at immutable candidate 8269ac576cf119975a7e9954459cd4aa04d5cd82;
Interface.lean is byte-identical to accepted v0. The original decoded producer
composition remains checked at this new pin. No producer files were changed.

Universal checked results: decodeArray_encoded with arbitrary prefix/tail;
decodeArguments_encoded for a canonical arguments packet within the explicit
64-bit extent bound; decodeReturn_encoded; run_encoded preserving all decoded
allocator outcomes; run_short proving decoding failure precedes demand handling;
and exact Panic(uint256) byte length. These use only propext, Classical.choice,
and Quot.sound. Compiler-generated selector dispatch, physical memory allocation
and copying, and arbitrary noncanonical ABI correspondence remain separate gates.

Current remote ABI receipt: 6e204674-c98f-4e7a-b66c-4b5e18947deb, ashur,
exit 0, 30 jobs. composition/source-identity.json binds all 29 source/config
files. Eleven byte vectors actually execute the new decoder, allocator and
encoder. The Solidity runner validates the exact source overlay and producer
blobs before comparing the model's bytes directly against the pinned public
library. It passed 116 exact return/revert comparisons, comprising the previous
105 comparisons plus eleven byte-model cases. The record is solidity-execution.json.
This is not a Verity runtime claim. JS fallback handled missing optional µWS.

UX2 passed without weakened checks at immutable head 4dce12b799ae9950901a680b4ac976210f786929;
ux2-head-receipt.json records its durable handle. It does not certify later source.
The previous failed UX2 run is correctly attributed to source mutation during its
run. Source annotations and the project proof-escape check passed; the isolated
ABI modules also have explicit kernel axiom inspections in their build receipt.

The exact full-build handle 560e32a9-a498-4c0f-9ad3-d225ccf4ca9d remains live
on old-agent at earlier head 4dce12b; do not restart it based on observation timeout.
Its source/dependency closure is unrelated to the isolated ABI receipt scope.

Open producer premise: actual successful decoded production proves only the
storage-count uint256 bound. It does NOT yet derive the byte extent needed by
allocation/ABI decoding. Neither a count<=32 assumption nor an arbitrary memory
relation has been silently added to close composition. The orchestrator again
rejected interface coordination with writer_identity_stale for existing PR #245
and trio-alloc1 tags. Those tags were not altered.

Remaining original scope: actual producer memory/extent derivation, compiler
memory/copying and ABI integration, parent checked wei conversions and ordered
observations/rollback, Verity differential execution, parent-shaped mutants and
arbitrary rejection/late failures, producer integration/agreement, real current
make prove/test/trust and UX2, and independent certification readiness. The +1
algorithm remains separate. No merge, deployment or unrelated PR mutation.
