# ALLOC-2 proportional outer loop — still incomplete

This advances the initial checkpoint, without changing its producer acceptance or
claiming composition. The prior goal turn was **progress**: it committed the
consumer acceptance and compiled candidate step. This turn adds the outer loop
and proves its termination and basic invariants. The complete objective stays open.

## New checked declarations

- `allocateLoop` transcribes the pinned while loop at
  `MinFirstAllocationStrategy.sol:30–44`: compare allocated to demand, checked
  subtraction, candidate step, break on zero amount, checked addition, repeat.
  There is no fuel input, fuel hypothesis or exhaustion result. The well-founded
  measure is `2^256 - allocated.val`. A successful checked addition of a nonzero
  step amount strictly decreases it. This establishes mathematical termination,
  not a gas/resource bound or feasible execution time for all words.
- `step_invariants` derives the demand bound and unchanged array length from the
  actual successful step result. It does not assume that scans or arithmetic
  separately succeed. `ceilDiv_le_numerator` supplies the proportional share bound.
- `allocateLoop_amount_between` proves the final accumulated amount lies between
  the initial accumulated amount and demand, assuming the initial amount is at
  most demand and the actual loop succeeds. `allocate_amount_le_demand` starts
  at zero. `allocateLoop_preserves_length` and `allocate_preserves_length` prove
  unchanged array length for every successful result.
- `Spec.Distributes` independently specifies the complete proportional process
  by mathematical selection and row-update rules. Its finite derivations preserve
  length. Existence and correspondence are **not proved**. It has no source
  executor call, success premise, or fuel parameter.

`LidoSRv3/Tests/TrioAlloc2/Loop.lean` executes seven `#eval` assertions, including
zero demand with short capacities, empty arrays, bounds failure, surplus capacities,
overfull rows, the complete [9998,70,0] example and maximum-word demand/capacity.
Any mismatch throws an IO exception. These are executed model tests, not new
theorem axioms and not Solidity/Verity differential execution. Earlier attempts
to use `rfl` or recursively unfold the loop with `simp` failed; their receipts
remain recorded. Universal invariants are independent of these vector checks.

## Successful receipt and exact source identity

Job `3fbc0741-f4a0-48f9-a176-c36d492a9cf5` on `ashur`: **succeeded, exit 0**.
See `receipt-3fbc0741-f4a0-48f9-a176-c36d492a9cf5.json` for command, toolchain,
base tree, timestamps, overlay identity, full available log and axiom output.
All 10 current Lean/config source files were hashed and compared to the remote
verified overlay:
`2ac6b4617f86817d332a601177c4868c360c3c5ebb92dc547cd94d9743388613`.
The per-file SHA256 values are in `loop-source-identity.json`.

Exact preparation and submission:

```
git worktree add --detach /workspaces/mission-44053c4f/temp/alloc2-verification c7adae04416704a839d56333efad003f0a0f46b7
python3 audit/trio/alloc2/prepare_slice.py
cd /workspaces/mission-44053c4f/temp/alloc2-verification/audit/trio/alloc2
REMOTE_BUILD_PASSIVE=1 REMOTE_BUILD_ESTIMATED_DISK_GB=2 remote-lean-build lake build
```

Preparation exits 0; submission exits 75 while the durable job runs. From the
implementation worktree, one-shot retrieval is:

```
python3 audit/trio/alloc2/read_receipt.py 3fbc0741-f4a0-48f9-a176-c36d492a9cf5 --node ashur
```

Retrieval exits 0 and records the terminal job's exit 0. No polling loop, public
push, credential forwarding/change, or security configuration change was used.
The private implementation branch remains intact. The second private worktree
exists because the runner's legacy gitlink transport cannot fetch an unpublished
implementation commit (`edbef81c...` failed before compilation). The verified
hashed overlay binds the private candidate to the publicly fetchable exact base.

A default 12 GiB estimate was rejected by placement: 86 GiB available against
12 GiB plus the unchanged 80 GiB emergency floor. The isolated Init-only build
uses a 2 GiB estimate (no third-party package builds; pinned lido-core checkout
is 11 MiB locally), which placement accepted. This estimate does not apply to
the full repository build. The isolated target is not a full-suite receipt.

The supplemental Axioms module prints dependencies of the loop, step invariants,
whole-loop bounds/length, and mathematical relation length theorem. The printed
sets are subsets of `{propext, Quot.sound}`; no project or native-decision axioms.
This does not substitute for the shared `LidoSRv3Audit` target.

## Additional commands and limits

| Command | Exit and scope |
| --- | --- |
| `python3 scripts/check_proof_escapes.py` | 0; 226 project Lean files, no escapes; existing native-decision inventory unchanged. |
| `python3 scripts/check_source_annotations.py` | 0; 720 citations, no false citations/quote mismatches; reported annotation coverage remains 95/142, not a complete new-slice inventory claim. |
| `python3 scripts/check_report_theorem_inventory.py` | 0; existing eight ALLOC-1 theorems/two registered parents only, not an inventory of these new declarations. |
| `python3 scripts/check_verity_provenance.py` | 0; reports pinned e977aaad6e1a9e92e0132d41b3d33a14135a4d46. |
| `make test` | 2; registry passes, shared UX2 source-tree hash fails before subsequent test/Lean gates. |

Logs are `loop-*.log`. Intermediate remote failures retain individual
`receipt-<job>.json` records, including their command, overlay and available log.
The source/target fixes, not a retry of an assumed-dead job, led to the final build.

## Next required work

Prove selection/amount/update correspondence to the independent specification,
total conservation and row-wise bounds, then lift it through the terminating
loop. Prove index and count bounds against actual decoded memory. Complete byte
memory/ABI, exact error encoding, library call/return copying and checked parent
wei conversion. The consumer-owned producer-success bridge remains unimplemented
pending a concrete producer executor theorem and recorded interface agreements;
producer SHA stays `2a4e9d2a91d257353470677c6101fd91293cf4e4`.

Still required: explicit all-outcome state/input relation, external call behavior,
ordered calls/events, instrumentation erasure, parent rollback and sequential
composition; executed pinned Solidity/Verity differential tests and parent-shaped
mutants; full production/test/trust and make prove/test gates. Forge and solc are
not currently available on the local PATH. No compilation/differential claim is
made for Solidity. `make prove` has not been run because its existing tracked
report writes require isolation or coordinated integration.

The shared UX2 hash requires coordinated regeneration after final validation;
no shared file, existing declaration, +1 algorithm, canonical status, PR230/231/243,
or site was edited. The public-PR/publication clarification remains pending; no
public PR or push occurred. There is no completion, certification or deployment claim.
