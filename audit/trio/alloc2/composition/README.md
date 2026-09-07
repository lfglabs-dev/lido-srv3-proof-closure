# Integrated producer/consumer composition

The composition declarations now live in
`LidoSRv3/Audit/Source/TrioAlloc2/Composition.lean`, inside the production source
glob. The former staged `Composition.lean` is a compatibility import.

The integration branch includes ALLOC-1 `9923f9d6836a081d9c962846b898a52e44982af1`,
ALLOC-2 `b279d572b694a9e106fdf61337323fbe5f6d3d33` and RESERVE-1
`1b3adaed91651156071513f8b2d9a4990a26346c` on main
`bcfbb5f027a5c370594891c1a455fde137709941`. This is integration-branch work,
not delivery or a merge into GitHub main.

The three composition theorems derive consumer array-length premises, successful
allocation with conservation and demand bounds, and the independent proportional
distribution relation from actual producer success. They pass the same demand and
actual output arrays to the consumer. No consumer-success assumption is added.

`MemoryComposition.lean` additionally makes the consumer read the stored array
lengths and byte-addressed elements through `allocateMemory`. `readMemoryArray_eq`
proves those reads recover the arrays under `ArrayAt`; `allocateMemory_eq` transfers
all decoded outcomes. The producer-to-memory and producer-to-byte distribution
theorems derive successful independent distribution without assuming consumer
success. The byte theorem derives the memory relation from `outputBytes` and an
explicit nonwrapping extent bound.


The execution checks cover prefixes/gaps, proportional ties, empty arrays,
zero-demand precedence over short capacity arrays, short-capacity failure,
already-over-capacity rows, and a wrong-capacity-pointer negative control. They
execute the memory consumer, not Solidity or Verity Contract.run. The complete
Init-only closure now contains 27 modules; its receipt is
`audit/trio/integration/memory-composition-init-receipt.json`.

This still does not derive the compiler's concrete allocation or memory mutations.
The encoded bytes are a proved representation of producer outputs, not evidence
that an EVM execution constructed them. Compiler memory allocation, byte-memory/ABI
execution, parent conversion, source refinement, callbacks and rollback remain
required. The separate +1 algorithm is unchanged.

Bounded reproduction from the repository root (Lean 4.31.0 via elan):

```sh
python3 audit/trio/integration/check-init-composition.py --output /tmp/trio-composition-check
```

The output directory must not exist. The check elaborates the transitive Init-only
closure, imposes a 30-second limit per module and records source hashes, compiler,
commands and exit codes. The initial integration check passed all 23 modules;
its receipt is in `audit/trio/integration/composition-init-receipt.json`. This is
not a production/test/trust build, make-prove/test result, or certification.

`prepare.py` and `source-identity.json` retain the isolated ABI candidate setup
against producer `8269ac576cf119975a7e9954459cd4aa04d5cd82`. They do not validate
the integrated producer. `LibraryABI.lean` and its vectors remain staged outside
the production glob; the decoded and memory compositions above are integrated.
Use the root build for complete validation.

Historical job `d6b747be-05b7-486a-b03c-bfb97f840ad1` against producer
`5f1683eaf753ff73aec6f1e787cb7f68bedcf056`, old-agent, exit 0, 21 jobs,
compiled the complete producer/consumer source closure. The historical receipt records its verified source bundle; `source-identity.json`
now records the current candidate described below.
The receipt is in the parent audit directory. Both bridge theorem inspections
report only propext and Quot.sound. This is implementation evidence, not
independent certification or full-suite validation.

The isolated ABI candidate includes the producer's Bytes and Memory modules.
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

