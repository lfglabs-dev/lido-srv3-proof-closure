# Reproducing ALLOC-1 implementation checks

These are implementation receipts, not independent certification. The full original
scope is tracked in `implementation-status.md` and remains open.

## Lightweight Lean

With Lean 4.31.0 available, run from the repository root:

```sh
python3 audit/trio/alloc1/validate-light.py --lean /path/to/lean --output /fresh/output/light
```

The script checks the 23 Init-only owned modules (including the interface and test entry)
with private oleans, rejects non-Init/non-owned imports, bounds each check to 30
seconds, and records each source SHA-256, exact command, output and exit status.
`vectors.json` is produced by actually evaluating `produce`, not by printing expected
results. Increasing the kernel reduction depth to 4096 in the test module permits
nested fixed-width byte encodings; no unchecked reduction or new axiom is used.

## Executed Solidity and paired SOURCE model

```sh
npm ci --prefix solidity/trio-alloc1 --no-audit --no-fund
node solidity/trio-alloc1/check-layout.cjs /fresh/output/compiler-layout.json
node solidity/trio-alloc1/run.cjs /fresh/output/solidity /fresh/output/light/vectors.json
node solidity/trio-alloc1/run.cjs /fresh/output/target-mutant /fresh/output/light/vectors.json target-only
node solidity/trio-alloc1/run.cjs /fresh/output/prefetch-mutant /fresh/output/light/vectors.json stake-before-subtraction
```

The ordinary run must exit 0. The mutant runs must exit 1 **because of the recorded
outcome mismatch**, not because of compilation/deployment/infrastructure failure.
The target-only mutant reaches `trailing-summary`: `[1]/[11]` differs from `[1]/[2]`.
The prefetch mutant reaches `underflow-before-stake`: its raw stake rejection and
extra attempted call differ from the original arithmetic panic and one-call trace.

The harness invokes the unmodified pinned internal helper. Seeding and raw modules
are test instrumentation. Source and solc versions are checked, imported file hashes
and optimizer settings are recorded, and `debug_traceTransaction` observes executed
STATICCALL target/payload order. Target addresses are normalized to seeded module
indices; outcomes preserve raw revert bytes. Relevant router slots and harness/module
balances must be unchanged, with no SSTORE and no committed events. Sender gas costs
are excluded. Calls nested inside callbacks are not exercised by these vectors.

The compiler is solc 0.8.25, with optimizer 200 and via-IR. These runs target Shanghai
because this Ganache version does not implement Cancun. They are pinned-source
execution evidence, not a production Cancun bytecode receipt. The optional µWS
native binary is unavailable on this Node build; Ganache falls back to its JS
implementation and the EVM runs complete normally.

The ordinary light runner evaluates the SOURCE executor. The separate remote
Verity runner below executes the complete call tree in pinned Verity external-call
denotation. Its 12 results/raw errors and top-level call lists match independently
executed Solidity; this is not a complete bytecode/compiler correspondence claim.

## Heavy Lean and infrastructure

Use `remote-lean-build` for production/test/trust and full-repository Lean targets.
`initialize-deps.py --cache /read-only/pinned/package/cache` creates private Git
checkouts at every root manifest revision without sharing mutable Lake state.
`prepare-remote.py` can construct a complete pinned-source/dependency snapshot.
It never reads credential files or copies compiled caches.

Observed remote diagnostics:

- Full JSON source bundle: HTTP 413, `Failed to buffer the request body: length limit exceeded`.
- Complete Git-object archive: HTTP 413, `remote build JSON exceeds 33554432 bytes after decompression`.
- Published pinned-repository fetch: HTTP 422, `insufficient node disk: 86 GiB available, 32 GiB estimated plus 80 GiB emergency floor`.
- Explicit `old-agent` also resolves to `ashur` and returns the same disk rejection.

No rejected request is a successful remote build. Initial requests retained the
32 GiB estimate. On 2026-09-07, measurement of the existing complete pinned build
showed 2.9 GiB `.lake`, 283 MiB Git data and 11 MiB Solidity source. With a revised
5 GiB estimate, the unchanged emergency floor admitted the full build:

```sh
REMOTE_BUILD_ESTIMATED_DISK_GB=5 REMOTE_BUILD_SOURCE_MODE=overlay \
  remote-lean-build lake build LidoSRv3 LidoSRv3Test LidoSRv3Audit LidoSRv3Legacy
```

Source SHA: `8269ac576cf119975a7e9954459cd4aa04d5cd82`. Remote job:
`3ca9d1e4-e496-43f7-87f2-a5925a9bd083` on `nippur`. Durable wrapper:
`b5419df7-2f52-485e-a96b-38687d1e65e8`. Running as of 12:38 UTC; not yet a
passing receipt. No emergency floor bypass, credential access or heavy local
fallback occurred.

`make test` currently exits 2 at `scripts/generate_ux2.py check`: the shared
`audit/ux2/index.json` differs from the registry/Lean sources. This branch does not
regenerate shared canonical files during the agreed additive phase. The ALLOC-2
owner has the shared integration gate in its goal. Current main was inspected at
`bcfbb5f027a5c370594891c1a455fde137709941`; it was not merged or modified.

## Verity call VM and public writer

The complete call-tree bridge at `9360d989e9b6b7fd3b1dd306e3fecae6e7c7b3d3`
passed remote elaboration (33 jobs, exit 0):

```sh
remote-lean-build lake build LidoSRv3.Audit.Source.TrioAlloc1.VerityProducer
```

Remote job `88d993e7-7dd5-44f6-910d-73a01757e510` on ashur; exact logs are
in `receipts/verity-build-9360.json`. The later world-storage adapter and actual
Verity vector execution are not covered by that older receipt. The remote-only
vector driver builds its imports before executing the same fixtures through Verity:

```sh
remote-lean-build lake env lean --run audit/trio/alloc1/RunVerityVectors.lean
node solidity/trio-alloc1/check-writer.cjs /fresh/output/writer
```

The writer harness inherits the unmodified public StakingRouter entry points. The
packed-word test and six error-order/rejection-rollback cases passed; receipts
`writer-storage.json` and `writer-errors.json` include exact words and raw errors.
The same command also executes fourteen admission rejections and one successful
insertion, writing `admission.json`. Reverted transaction traces identify every
attempted SSTORE slot; historical reads compare those slots before and after the
transaction. Six late failures must execute writes before reverting. Eight public
parameter-update cases additionally check error/enum precedence, two packed words,
and the four event ABIs (`parameters.json`). These writer vectors do not establish
all-writer reachability.

The writer command also emits optimized `writer.ir` and `library.ir`, checks
malformed old name storage and long-name cleanup, and validates the final deposit
state/event (`admission-name.json`). The storage reader treats Ganache's bare
`0x` response as zero. Source/output hashes for the final rerun are recorded in
`receipts/writer-validation.json`; `receipts/string-storage.ir` is the relevant
compiler excerpt, with full IR hash in that receipt.

The test-only `insertModuleId` wrapper invokes original SRStorage.addModuleId to
exercise the compiler storage-array push boundary independently of public admission's
count<32 guard. `enumeration-boundary.json` checks absent-ID panic at 2^64,
existing-ID no-op and growth from 2^64-1. Those transactions use an explicit gas
budget to avoid reusing a lower estimate from the preceding no-op.

Current differential receipt: `receipts/solidity-verity-comparison.json`. Recheck
the independently produced outputs without reevaluating either model:

```sh
python3 audit/trio/alloc1/compare-executions.py \
  audit/trio/alloc1/receipts/solidity-memory.json \
  audit/trio/alloc1/receipts/verity-vectors-03abaac.json /fresh/comparison.json
node solidity/trio-alloc1/check-callback.cjs /fresh/output/callback
```

The full four-target build later passed 1,505 jobs at8269ac (STALE_SUCCESS for
newer heads). The corrected Verity runner passed 37 jobs and actual execution at
03abaac, using a separately measured 2 GiB estimate. Full build estimate remains
5 GiB; no emergency-floor override was used. Exact receipts identify source SHAs.
