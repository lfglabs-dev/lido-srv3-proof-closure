# ALLOC-2 conservation checkpoint — objective remains incomplete

Resumed private branch `trio/alloc2-proportional-composition` from `8f52313`.
Exact base remains `c7adae04416704a839d56333efad003f0a0f46b7`; Solidity gitlink
remains `17005714f151e5502c559932319a3f2f74ac2436`. Disk preflight reported
1.9T available, 47% used. No existing base-tracked file was edited.

## Checked results

`Conservation.lean` adds the unbounded mathematical observation `bucketTotal`.
It is not an executable Solidity accumulator or a new word-overflow premise.

- `bucketTotal_set`: replacing the actually indexed word with its checked sum
  increases total allocation by exactly the increment.
- `step_conserves`: actual successful `step` increases the total by exactly its
  returned amount, with no separate scan/update success assumptions.
- `allocateLoop_conserves`: successful loop execution gives
  `sum(final) + initialAllocated = sum(initial) + returnedAllocated`.
  Includes the zero-step break, using the successful step conservation theorem.
- `allocate_conserves`: the complete zero-initialized library loop increases the
  bucket sum by exactly the returned allocation.
- `allocate_twice_conserves`: feeding the first successful result into a second
  execution conserves both returned amounts, whose sum is bounded by the sum of
  demands. The second capacity array may differ. The combined sum is Nat, not
  a claim that a combined word addition succeeds.

Five executed sequential model checks feed the actual first output into the
second call: capacity exhaustion, reduced capacities with an already overfull
row, maximum-word saturation, second-call bounds error, and zero-demand guard
precedence with missing second-call capacities. These do not model router
storage, external-call rollback, same-block accounting, or batching equivalence.
They are not Solidity/Verity differential tests.

## Commands and durable evidence

Preparation from repository root:

```
python3 audit/trio/alloc2/prepare_slice.py
```

Exit 0; twelve current source/config files copied and individually hashed.
Submission from `/workspaces/mission-44053c4f/temp/alloc2-verification/audit/trio/alloc2`:

```
REMOTE_BUILD_PASSIVE=1 REMOTE_BUILD_ESTIMATED_DISK_GB=2 remote-lean-build lake build
```

Each submission exited 75 with a durable job handle. One-shot terminal retrieval
used `python3 audit/trio/alloc2/read_receipt.py <job> --node ashur`, exit 0.
No polling loops or credential/security changes.

| Job | Result |
| --- | --- |
| `edf911eb-f71c-4d3a-8724-3244f53cde37` | Exit 1: proof-script case naming and unreduced structure projections; corrected explicitly. |
| `15bde56e-57b1-48a5-8fe8-3da417b06ec5` | Exit 0: conservation module and axiom inspection, 12 jobs. |
| `201e16b2-9c5e-463c-aa0e-e6db10697573` | Exit 0: final conservation/sequential candidate, 13 jobs. |

Individual `receipt-<job>.json` files retain validation identities and logs;
`conservation-submit-{1,2,3}.log` retain submissions. Final verified overlay hash:
`66796ea55c47d0d58b593a22e64362007c58b30638fbdfcf8c4c170d26c7892a`.
`conservation-source-identity.json` records all twelve per-file hashes; current
files were checked against the submitted manifest. Remote toolchain is pinned
Lean v4.31.0. All inspected theorem dependencies are subsets of
`{propext, Quot.sound}`. This is an isolated Init-only slice receipt, **not**
production/test/trust full-suite validation or independent source correspondence.

Supplemental checks, logs `conservation-check-<n>.log`:

| n | Command | Exit |
| --- | --- | --- |
| 0 | `python3 scripts/check_proof_escapes.py` | 0 |
| 1 | `python3 scripts/check_source_annotations.py` | 0 |
| 2 | `python3 scripts/check_report_theorem_inventory.py` | 0 |
| 3 | `python3 scripts/check_verity_provenance.py` | 0 |
| 4 | `make test` | 2: registry passes, shared UX2 source hash differs; later gates do not run. |

Annotation and inventory checks retain their previously documented limited
coverage. No shared metadata or generated file was regenerated. `make prove`
and full production/test/trust compilation remain outstanding as described in
prior checkpoints; no successful full-suite result is claimed.

## Outstanding dependencies and work

Producer SHA remains `2a4e9d2a91d257353470677c6101fd91293cf4e4`; its Interface
was re-read and still provides output/memory views and length lemmas, not an
executor-success theorem. Consumer written acceptance remains unchanged in
`interface-acceptance.md`. No orchestrator record of both agreements or newer
producer checkpoint was supplied during this resumed work. The named
`producer_success_establishes_consumer_premises` bridge remains unimplemented;
no compatibility or success premise was invented to replace it.

Selection/specification correspondence, row-wise bounds, index/count memory
bounds, byte-memory/ABI and exact error precedence, parent checked conversions,
all-outcome state/input relation, calls/events, instrumentation erasure, adversarial
external failures, router sequential composition and executed Solidity/Verity
mutants/differentials remain open. The new sequential library theorem closes
none of those parent-level gaps. Prior +1 declarations remain intact.

The requested public draft PR versus prohibition on public publication remains
unresolved; a clarification was requested while independent work continued.
No public branch push, PR, review, comment, merge, site edit, or Lido contact was
made. This checkpoint records incremental checked implementation, not completion,
self-certification, or a canonical guarantee upgrade.
