# TOPUP derived returnBuffer (credentials.next)

Additive lot on `grok/lido-topup-returnbuffer-20260911`. No existing Lean,
registry, Trust, or import-DAG file is edited. Integration is a later
agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `4c4c8bcf283c32b8487dd81080eaf1b0812f9281` |
| CLAIM commit | `c833a0a436ce7e03caef651c28ae7e1c53db6cb3` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns topup-returnbuffer since 2026-09-11

STATUS: ready

## Obligation

`TopupRouterLocatorCall.run` threads locator `next` into the credentials
cursor and forwards `returnBuffer` unchanged. The pointer-origin lot proved
disjointness *if* `returnBuffer = credentials.next`. This lot supplies the
decoder that makes that equation definitional: the module cursor is not a
caller `Word`.

The public `run` still takes `returnBuffer`. This does not edit
`TopupRouterLocatorCall` / `TopupTimingHistory` and does not close a
`guarantees.yaml` row.

## Theorems

| Theorem | Claim |
| --- | --- |
| `decodeReturnAtCredentialsNext` | Module `decodeReturn` at `credentials.next`. No `returnBuffer` argument. |
| `decodeReturnAtCredentialsNext_ok` | Wrapper success ⇔ credentials success ∧ module success at that derived cursor. |
| `decodeReturnAtCredentialsNext_disjoint` | Sequential credentials/module zones from wrapper success. No `hchain`. |
| `decodeReturnAfterLocator` | Locator 32-byte copy, then credentials at `locNext`, then module at `credNext`. |
| `decodeReturnAfterLocator_ok` | Triple-wrapper success ⇔ locator decode ∧ `decodeReturnAtCredentialsNext`. |
| `decodeReturnAfterLocator_disjoint` | Locator/credentials/module pairwise sequential, no `hchain`. |

## Mutants

| Theorem | Claim |
| --- | --- |
| `decode_at_credentials_next_128` | Credentials @ 128 → module @ derived 160. |
| `decode_at_credentials_next_disjoint_128` | Those zones are disjoint. |
| `locator_at_128` / `decode_at_credentials_next_160` / `decode_after_locator_128` | Locator 0xabc @ 128 → credentials @ 160 → module @ 192. |
| `decode_after_locator_disjoint_128` | The three zones are pairwise sequential. |
| `public_returnBuffer_is_not_the_wrapper` | The independently supplied `returnBuffer = 128` path still succeeds and aliases; this wrapper is not that public run. |

## Hypotheses

- Wrapper success only (the two/three decoder successes already used by the
  pointer-origin chained theorems).
- Interval aliasing is the same `finalizeAllocation` model. No `mload`/`mstore`.
- The public `run` is not this wrapper.

## Axioms

Source: `propext` on the `_ok` lemmas; `propext` / `Quot.sound` on
credentials-then-module disjointness; `propext` / `Classical.choice` /
`Quot.sound` on the locator triple (from `chained_scalar32_disjoint`).
No `sorryAx`.

Mutants additionally use `native_decide` / `decide +kernel` for the concrete
ABI fixtures, same as `TopupPointerOriginMutants`.

## Gate

```
lake build LidoSRv3.Audit.Source.TopupReturnBuffer
lake build LidoSRv3.Tests.TopupReturnBufferMutants
lake env lean LidoSRv3/Audit/Source/TopupReturnBuffer.lean
lake env lean LidoSRv3/Tests/TopupReturnBufferMutants.lean
```

## Out of scope / still open

- Editing the public `run` to derive `returnBuffer`
- Wei conversion, `allocateDeposits` policy, A-TOPUP-BEACON-ADDRESS
- Bytecode, gas, deployed LidoLocator
- Named P-TOPUP-2 gaps that remain after the keccak-independence lot:
  `_verifyValidator`, live wei conversion, withdraw / makeBeaconChainTopUp
