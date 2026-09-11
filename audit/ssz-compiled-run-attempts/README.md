# SSZ-1 compiled run attempts / STATICCALL journal

Additive lot on `grok/lido-ssz-compiled-run-attempts-20260911` from current
`origin/main`. No existing Lean, registry, Trust, or import-DAG file is
edited.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `f8793c157c8a00c98066ae739715128128b38fa3` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns ssz-compiled-run-attempts since 2026-09-11

STATUS: ready

## Obligation

`run.attempts` is the STATICCALL journal of `rootCall` (IR 101-114) and
is empty when the compiled prefix fails before that call
(`SszCompiledClEntry.lean:164-171`). Disjoint from #370 (rollback of
committed state), #375 (afterRoot class) and #377 (beforeRoot class).
EIP-4788 authenticity stays declared.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/SszCompiledRunAttempts.lean` | Additive theorems |
| `LidoSRv3/Tests/SszCompiledRunAttemptsMutants.lean` | Named kill-lines |
| `audit/ssz-compiled-run-attempts/README.md` | This note |

## Theorems

| Theorem | Reflects | Statement |
| --- | --- | --- |
| `run_attempts_of_beforeRoot_error` | `run` / IR 43-100 | `beforeRoot` error ⇒ `attempts = []` |
| `run_attempts_of_rootCall_error` | `run` / IR 101-114 overflow | `rootCall` error ⇒ `attempts = []` |
| `run_attempts_of_rootCall_ok` | `run` / IR 101-114 | `rootCall` ok ⇒ `attempts = out.attempts` |
| `run_outcome_of_beforeRoot_error` | `run` / IR 43-100 | `beforeRoot` error ⇒ `outcome = error e` |
| `run_outcome_of_rootCall_error` | `run` / IR 101-114 | `rootCall` error ⇒ `outcome = error e` |
| `run_outcome_of_rootCall_ok` | `run` / IR 116-417 | `rootCall` ok ⇒ `outcome = afterRoot …` |
| `run_attempts_empty_of_prefix_error` | both prefix phases | prefix error ⇒ empty journal |

The successful-`rootCall` journal is retained even if `afterRoot` later
reverts (the `run` constructor copies `out.attempts` before `afterRoot`).

## Mutants

| Kill-line | Mutant killed |
| --- | --- |
| `beforeRoot_error_empty_journal_kill_line` | Prefix ABI/slot failure still journals a STATICCALL |
| `rootCall_error_empty_journal_kill_line` | Allocator overflow still journals a STATICCALL |
| `rootCall_ok_journal_is_outcome_kill_line` | Journal is an independent caller-supplied list |
| `beforeRoot_error_kills_run_ok` | A `beforeRoot` failure is still a successful `run` |

## Hypotheses (declared, not proved here)

- EIP-4788 authenticity and freshness of the BEACON_ROOTS reply.
- Compilation of the inspected IR against the pinned Solidity source.
- Crypto, gas, consensus, deployed locator identity.

## Axioms

`#print axioms` of every export is only `propext` / `Classical.choice` /
`Quot.sound`, or a subset. No `sorry`, no extra axiom.

## Open / not this lane

- Committed storage/events rollback is #370.
- Constructor classes of the three phases are #375 / #377.
- Header `do`/`throw` rewrite remains a Spark raccord on
  `SszCompiledClEntry.header`.

## Recheck

```sh
export PATH="$HOME/.elan/bin:$PATH"
lake build LidoSRv3.Audit.Source.SszCompiledRunAttempts
lake build LidoSRv3.Tests.SszCompiledRunAttemptsMutants
lake env lean LidoSRv3/Audit/Source/SszCompiledRunAttempts.lean
lake env lean LidoSRv3/Tests/SszCompiledRunAttemptsMutants.lean
```
