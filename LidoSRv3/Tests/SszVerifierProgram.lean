import LidoSRv3.Audit.Source.SszVerifierProgram

namespace LidoSRv3.Tests.SszVerifierProgram

open LidoSRv3.Audit.Source.SszVerifierProgram

example : publicKeyBytes = 48 ∧ withdrawalCredentialsBytes = 32 ∧
    signatureBytes = 96 ∧ amountBytes = 8 ∧ depositDataBytes = 184 := by decide

example : scratchOffset = 0 ∧ rightScratchOffset = 32 ∧
    shaPairInputBytes = 64 ∧ shaOutputBytes = 32 ∧ shaAddress = 2 := by decide

example : depositDataRootCalls.length = 7 := by decide

/-- Validator call sources are bound to the pinned semantic field order. -/
example : (validatorRootCalls.map (fun call => call.preimage.map Piece.source))[1]? =
    some [.digest 0, .validatorField .withdrawalCredentials] := by decide

example : (validatorRootCalls.map (fun call => call.preimage.map Piece.source))[4]? =
    some [.validatorField .exitEpoch, .validatorField .withdrawableEpoch] := by decide

example : (verifierPair 2 0).map Piece.source =
    [.verifierLeaf, .proofElement 0] := by decide

example : (verifierPair 3 0).map Piece.source =
    [.proofElement 0, .verifierLeaf] := by decide

/-- Later calls consume the preceding digest, rather than reusing the input leaf. -/
example : (verifierPair 2 1).map Piece.source =
    [.digest 0, .proofElement 1] := by decide

example : (verifierPair 3 2).map Piece.source =
    [.proofElement 2, .digest 1] := by decide

def noCapabilities : OfficialVerityCapabilities := ⟨false, false, false⟩

/-- No official memory/ABI/SHA semantics means no fabricated success. -/
example (root : Bytes) :
    gateOfficialSemantics noCapabilities
      (.returnedDepositRoot root depositDataRootCalls) =
        .reverted .officialSemanticsUnavailable [] := by
  simp [gateOfficialSemantics, officialSemanticsReady, noCapabilities]

/-- Supplying only memory and ABI remains insufficient. -/
example : gateOfficialSemantics ⟨true, true, false⟩ (.verified []) =
    .reverted .officialSemanticsUnavailable [] := by decide

/-- Supplying only SHA and memory remains insufficient. -/
example : gateOfficialSemantics ⟨true, false, true⟩ (.verified []) =
    .reverted .officialSemanticsUnavailable [] := by decide

/-! `allCapabilityFlags` exercises the ready side of the interface; it is not
evidence that the pinned Verity revision supplies those semantics. -/
def allCapabilityFlags : OfficialVerityCapabilities := ⟨true, true, true⟩

def zeroDigest : Bytes := List.replicate 32 0

example : observeDepositDataRoot allCapabilityFlags ⟨48, 32, 96, 184⟩ zeroDigest =
    .returnedDepositRoot zeroDigest depositDataRootCalls := by decide

example : observeDepositDataRoot allCapabilityFlags ⟨47, 32, 96, 184⟩ zeroDigest =
    .reverted .invalidAbi [] := by decide

/-- A candidate SHA observation cannot fabricate a non-`bytes32` result. -/
example : observeDepositDataRoot allCapabilityFlags ⟨48, 32, 96, 184⟩ [] =
    .reverted .invalidRoot [] := by decide

example : observeDepositDataRoot allCapabilityFlags ⟨48, 32, 96, 184⟩
    (256 :: List.replicate 31 0) = .reverted .invalidRoot [] := by decide

/-- Empty proof is the pinned verifier's first rejection. -/
example : observeVerifierControl allCapabilityFlags ⟨0, 1, [], true⟩ =
    .reverted .invalidProof [] := by decide

/-- A generalized index outside Solidity `uint256` is not source-reachable. -/
example : observeVerifierControl allCapabilityFlags ⟨256, 2 ^ 256, List.replicate 256 true, true⟩ =
    .reverted .invalidIndex [] := by decide

/-- Shifting index one to zero rejects an extra item before calling SHA. -/
example : observeVerifierControl allCapabilityFlags ⟨1, 1, [true], true⟩ =
    .reverted .branchHasExtraItem [] := by decide

/-- A failed precompile call records no completed call. -/
example : observeVerifierControl allCapabilityFlags ⟨1, 2, [false], true⟩ =
    .reverted .shaCallFailed [] := by decide

/-- A later SHA failure retains exactly the calls that completed before it. -/
example : observeVerifierControl allCapabilityFlags ⟨2, 4, [true, false], true⟩ =
    .reverted .shaCallFailed [verifierShaCall 0 4] := by decide

/-- Consuming too short a branch leaves an index other than one. -/
example : observeVerifierControl allCapabilityFlags ⟨1, 4, [true], true⟩ =
    .reverted .branchHasMissingItem [verifierShaCall 0 4] := by decide

/-- Root mismatch is checked after the branch and index are accepted. -/
example : observeVerifierControl allCapabilityFlags ⟨1, 2, [true], false⟩ =
    .reverted .invalidProof [verifierShaCall 0 2] := by decide

example : observeVerifierControl allCapabilityFlags ⟨1, 2, [true], true⟩ =
    .verified [verifierShaCall 0 2] := by decide

#print axioms deposit_call_preimages_exact
#print axioms validator_root_preimages_exact
#print axioms verifier_pair_preimage_exact
#print axioms missing_memory_fails_closed
#print axioms missing_abi_fails_closed
#print axioms missing_sha_fails_closed

end LidoSRv3.Tests.SszVerifierProgram
