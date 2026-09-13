import LidoSRv3.Audit.Guarantees.PSsz1
import LidoSRv3.Audit.Source.BeaconRootsEip4788Source
import LidoSRv3.Audit.Source.Sha256OpacitySource
import LidoSRv3.Audit.Source.SszValidatorHashTreeRootSource
import LidoSRv3.Audit.Source.SszVerifyProofSource

/-! # P-CONSOLIDATION-ETH-1 CL-proof composition premise

**Chantier 2 continuation (Thomas 2026-09-13), item (d.CL): compose
`_validatePubKeyWCProof` CL-proof into the ETH-1 statement.**

The pinned Solidity's `_validatePubKeyWCProof`
(`CLProofVerifier.sol:150-175`, invoked at
`ConsolidationGateway.sol:206` for each per-group consolidation
witness) performs four steps:

  (i) `_verifySlot(witness)` — slot/proposer parity check;
  (ii) leaf construction `sha256Pair(pubkeyRoot(pubkey),
       withdrawalCredentials)`;
  (iii) fork-aware gindex composition
       `concat(GI_STATE_ROOT, concat(_getValidatorGI(validatorIndex,
       slot), GI_PUBKEY_WC_PARENT))`;
  (iv) `SSZ.verifyProof(proof, root = _getParentBlockRoot(childBlockTimestamp),
       leaf, gI)`.

Steps (iii) and (iv) reduce **exactly** to the source-level facts
P-SSZ-1's chantier-1 abstract parent `real_validator_correspondence`
(`LidoSRv3.Audit.Guarantees.PSsz1.real_validator_correspondence`)
already registers:

  - The fork-aware gindex choice PREV/CURR under
    `provenSlot < pivotSlot` (conjunct 2 of the P-SSZ-1 parent);
  - The `SSZ.verifyProof` Merkle fold iff the reconstructed root
    matches the claimed one (conjunct 3 of the P-SSZ-1 parent);
  - The EIP-4788 anchor at the pinned predeploy
    `0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02` (conjunct 4).

Step (ii) — the pubkey/withdrawalCredentials leaf — is the specific
composition premise the ETH-1 side needs: given a per-group witness
supplying `witness.pubkey` and the vault's
`withdrawalCredentials`, the CL-proof soundness for the
consolidation gateway follows once we have (a) a `RealValidatorInput`
holding the pinned validator's fields and (b) the P-SSZ-1 parent's
conclusions.

**Status: naming scaffold, not a full composition** — same status as
the sibling fee-STATICCALL premise module
`PConsolidationEth1FeeStaticcallPremise.lean`. The theorem
`cl_proof_derived_under_pinned_cl_proof_shape` below is a straight-line
projection under the shape. A full composition additionally requires:

  - A Verity model of `_validatePubKeyWCProof`'s executable frame,
    typed on `Live.World`;
  - A cross-guarantee Verity theorem tying P-SSZ-1's
    `real_validator_correspondence` output into
    `PhysicalEntrySettlement`'s per-group gate;
  - An ABI decoder for `sha256Pair(pubkeyRoot(pubkey),
    withdrawalCredentials)` on the gateway's calldata.

None of the three are tree-resident yet; those residuals are named
here so the composition entry point is explicit and load-bearing on
the P-SSZ-1 parent's premises rather than an isolated scaffold. -/

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1CLProofPremise

open LidoSRv3.Audit.Guarantees.PSsz1
open LidoSRv3.Audit.Source.BeaconRootsEip4788Source
open LidoSRv3.Audit.Source.Sha256OpacitySource
open LidoSRv3.Audit.Source.SszValidatorHashTreeRootSource
open LidoSRv3.Audit.Source.SszVerifyProofSource

/-- **Pinned `_validatePubKeyWCProof` shape.** A per-group CL-proof
call satisfies this premise when the ETH-1 side supplies a
`RealValidatorInput` whose leaf and gindex are those the pinned
`CLProofVerifier.sol:150-175` computes for the witness. Concretely:

  - `input.leaf = validatorHashTreeRoot input.oracle input.validator`
    is the 8-leaf pinned `_validatorHashTreeRoot` schedule at
    `CLValidatorVerifier.sol:60-85` (this equality is a definitional
    property of `RealValidatorInput.leaf`, always true — it is
    named here so the premise reads as a pinned-Solidity assertion);
  - `verifyProof input.oracle input.leaf input.siblings
     input.parentBlockRoot = true` names the successful pinned-Solidity
    Merkle fold at `SSZ.sol:179`;
  - `input.eip4788Call = canonicalCall input.timestamp` is the pinned
    EIP-4788 anchor (`BEACON_ROOTS` at
    `0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02`).

The premise NAMES what the pinned Solidity does; the abstract parent
`real_validator_correspondence` proves it is well-typed. -/
def PinnedCLProofShape (input : RealValidatorInput) : Prop :=
  input.leaf = validatorHashTreeRoot input.oracle input.validator ∧
  verifyProof input.oracle input.leaf input.siblings input.parentBlockRoot = true ∧
  input.eip4788Call = canonicalCall input.timestamp

/-- **Chantier 2 (Thomas 2026-09-13) CL-proof gateway derivation
under the pinned shape.** Under `PinnedCLProofShape input`, the
`SSZ.verifyProof` Merkle fold succeeds AND the anchor targets the
pinned EIP-4788 predeploy — the two conclusions of P-SSZ-1's
`real_validator_correspondence` that a consolidation-gateway
consumer needs to admit the per-group CL proof. Load-bearing on
`hShape`: dropping it leaves `input.leaf`, `verifyProof`, and
`input.eip4788Call` unrelated to the pinned Solidity. Composes
`real_validator_correspondence` from `LidoSRv3.Audit.Guarantees.PSsz1`
into the ETH-1 gateway plane. -/
theorem cl_proof_derived_under_pinned_cl_proof_shape
    (input : RealValidatorInput)
    (hShape : PinnedCLProofShape input)
    (gIFirstValidatorPrev gIFirstValidatorCurr : Nat) :
    (verifyProof input.oracle input.leaf input.siblings
        input.parentBlockRoot = true ↔
      foldPath input.oracle input.leaf input.siblings =
        input.parentBlockRoot) ∧
    input.eip4788Call.target = beaconRootsAddress := by
  obtain ⟨_, hVerify, hAnchor⟩ := hShape
  have hCorr := real_validator_correspondence input hAnchor
    gIFirstValidatorPrev gIFirstValidatorCurr
  exact ⟨hCorr.2.2.1, hCorr.2.2.2⟩

/-- Non-vacuity witness for the `PinnedCLProofShape` premise: for any
concrete inputs where the leaf matches `validatorHashTreeRoot`, the
Merkle fold verifies, and the anchor is canonical, the shape is
satisfied. Aligns with the `real_validator_correspondence_witness`
pattern registered in P-SSZ-1. -/
theorem cl_proof_derived_witness
    (oracle : Sha256Oracle) (validator : Validator)
    (siblings : List (List Nat × Nat)) (parentBlockRoot : List Nat)
    (provenSlot pivotSlot validatorIndex timestamp : Nat)
    (hFold : foldPath oracle (validatorHashTreeRoot oracle validator)
      siblings = parentBlockRoot) :
    let input : RealValidatorInput := {
      oracle := oracle,
      validator := validator,
      siblings := siblings,
      parentBlockRoot := parentBlockRoot,
      provenSlot := provenSlot,
      pivotSlot := pivotSlot,
      validatorIndex := validatorIndex,
      eip4788Call := canonicalCall timestamp,
      timestamp := timestamp
    }
    PinnedCLProofShape input := by
  refine ⟨rfl, ?_, rfl⟩
  unfold verifyProof
  exact decide_eq_true hFold

end LidoSRv3.Audit.Guarantees.PConsolidationEth1CLProofPremise
