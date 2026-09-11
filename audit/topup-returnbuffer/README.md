# TOPUP derived returnBuffer (credentials.next)

Additive lot on `grok/lido-topup-returnbuffer-20260911`. No existing Lean,
registry, Trust, or import-DAG file is edited. Integration is a later
agent’s job.

## Identities

| Pin | SHA |
| --- | --- |
| Campaign base `origin/main` | `4c4c8bcf283c32b8487dd81080eaf1b0812f9281` |
| Pinned Solidity `lidofinance/core` | `17005714f151e5502c559932319a3f2f74ac2436` |
| Lean toolchain | `leanprover/lean4:v4.31.0` |
| Verity pin (`lakefile.lean`) | `e977aaad6e1a9e92e0132d41b3d33a14135a4d46` |

CLAIM: grok owns topup-returnbuffer since 2026-09-11

STATUS: claimed

## Obligation

`TopupRouterLocatorCall.run` threads locator `next` into the credentials
cursor and forwards `returnBuffer` unchanged. The pointer-origin lot proved
disjointness *if* `returnBuffer = credentials.next`. This lot supplies the
decoder that makes that equation definitional: the module cursor is not a
caller `Word`.

The public `run` still takes `returnBuffer`. This does not edit
`TopupRouterLocatorCall` / `TopupTimingHistory` and does not close a
`guarantees.yaml` row.

## Files

| File | Role |
| --- | --- |
| `LidoSRv3/Audit/Source/TopupReturnBuffer.lean` | Additive decoder + theorems |
| `LidoSRv3/Tests/TopupReturnBufferMutants.lean` | Witnesses |
| `audit/topup-returnbuffer/README.md` | This note |

## Out of scope

- Editing the public `run` to derive `returnBuffer`
- Wei conversion, `allocateDeposits` policy, A-TOPUP-BEACON-ADDRESS
- Bytecode, gas, deployed LidoLocator
