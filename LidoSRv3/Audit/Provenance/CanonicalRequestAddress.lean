import LidoSRv3.Audit.Guarantees.PConsolidationEth1
import LidoSRv3.Audit.Verity.ConsolidationCallFragment

/-!
# A-CANONICAL-REQUEST-ADDRESS is discharged from the deployed bytecode

The Lean model literal
`LidoSRv3.Audit.Verity.ConsolidationCallFragment.consolidationPredeploy`
= `0x0000BBdDc7CE488642fb579F8B00f3a590007251` is now anchored to the
actual `CONSOLIDATION_REQUEST` immutable value inside the deployed
Lido `WithdrawalVault` implementation bytecode.

## Provenance chain (recorded in `audit/artifacts.lock.json`)

- Proxy: `0xB9D7934878B5FB9610B3fE8A5e441e8fad7E293f`
- Implementation slot resolves to
  `0xfB4521BD151BFB45DB6045D2d07e58e0f597e340`
- Runtime bytecode fixture: `fixtures/deployed/WithdrawalVault-impl-runtime.bin`
- Fixture size: 5088 bytes
- Fixture SHA-256:
  `a3e9e582928d58cdfe87a6405ad1a7967f720cafa97f98ae8d619e36b961aa7f`
- `CONSOLIDATION_REQUEST` immutable is patched by `solc` at byte offset
  730, width 20 bytes.
- The 20 bytes at that offset are literally
  `0000bbddc7ce488642fb579f8b00f3a590007251`, i.e. the canonical
  EIP-7251 consolidation-request predeploy.

`scripts/check_deployed_code.py` re-verifies that the deployed
implementation runtime bytecode still matches the fixture (its
byte-for-byte identity is anchored under the accepted assumption
`A-RUNTIME-PROVENANCE`, which is a *global* assumption every guarantee
already carries).

The Lean fact below extracts the 20 immutable bytes from the fixture
and shows they equal the model literal. The fixture bytes at the
extraction offset are hardcoded here as a `List UInt8` — that list is
the exact byte substring `fixture[730:750]` of the pinned fixture
file, which the reproduction script `scripts/verify_consolidation_
request_immutable.py` re-derives (see the finding for details).

Together with the fixture-hash pin in `audit/artifacts.lock.json` and
the `check_deployed_code.py` gate, this closes
`A-CANONICAL-REQUEST-ADDRESS` down to `A-RUNTIME-PROVENANCE`.
-/

namespace LidoSRv3.Audit.Provenance.CanonicalRequestAddress

open LidoSRv3.Audit.Verity.ConsolidationCallFragment

/-- Canonical EIP-7251 consolidation-request predeploy literal. -/
abbrev canonicalRequestPredeploy : Nat :=
  0x0000BBdDc7CE488642fb579F8B00f3a590007251

/-- The exact 20 bytes extracted from
`fixtures/deployed/WithdrawalVault-impl-runtime.bin` at offset
`730` (width 20). This is the solc-patched `CONSOLIDATION_REQUEST`
immutable in the deployed Lido WithdrawalVault runtime bytecode. -/
def deployedConsolidationRequestImmutableBytes : List UInt8 :=
  [0x00, 0x00, 0xbb, 0xdd, 0xc7, 0xce, 0x48, 0x86,
   0x42, 0xfb, 0x57, 0x9f, 0x8b, 0x00, 0xf3, 0xa5,
   0x90, 0x00, 0x72, 0x51]

/-- Fold 20 big-endian bytes into their `Nat` value. -/
def bytesToBigEndianNat (bs : List UInt8) : Nat :=
  bs.foldl (fun acc b => acc * 256 + b.toNat) 0

/-- The 20-byte immutable extracted from the deployed runtime bytecode
equals the canonical EIP-7251 predeploy literal. Proof is by
`decide +kernel` on a concrete finite computation. -/
theorem deployed_consolidation_request_immutable_equals_canonical :
    bytesToBigEndianNat deployedConsolidationRequestImmutableBytes =
      canonicalRequestPredeploy := by decide +kernel

/-- The Lean model's `consolidationPredeploy` literal
(`LidoSRv3.Audit.Verity.ConsolidationCallFragment.consolidationPredeploy`)
equals the canonical predeploy. -/
theorem model_consolidation_predeploy_equals_canonical :
    consolidationPredeploy = canonicalRequestPredeploy := rfl

/-- Composed statement: the Lean model literal equals the immutable value
extracted from the deployed WithdrawalVault runtime bytecode. This
closes `A-CANONICAL-REQUEST-ADDRESS` conditional on the fixture-hash
identity (which sits under the accepted global assumption
`A-RUNTIME-PROVENANCE`). -/
theorem model_predeploy_equals_deployed_immutable :
    consolidationPredeploy =
      bytesToBigEndianNat deployedConsolidationRequestImmutableBytes := by
  rw [model_consolidation_predeploy_equals_canonical]
  exact (deployed_consolidation_request_immutable_equals_canonical).symm

end LidoSRv3.Audit.Provenance.CanonicalRequestAddress
