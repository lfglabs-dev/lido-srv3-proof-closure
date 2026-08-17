import LidoSRv3.Audit.Verity.SszEncodingTx

/-! P-SSZ-1 faithful-plane fail-closed vectors. -/

namespace LidoSRv3.Tests.SszEncodingTxMutants

open Verity
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszEncodingTx
open LidoSRv3.Audit.Source.GIndexConcatCorrespondence

private def gindex (index pow : Nat) (hIndex : index ≤ maxUint248 := by decide)
    (hPow : pow < 2 ^ 8 := by decide) : GIndex :=
  ⟨index, pow, hIndex, hPow⟩

private def baseDeposit : Inputs :=
  { publicKey := zeros 48
    withdrawalCredentials := zeros 32
    signature := zeros 96
    amountLittleEndian := zeros 8 }

private def matching : EncodingInput :=
  { deposit := baseDeposit
    lhs := gindex 2 7
    rhs := gindex 3 11
    expectedRoot := (digestChain baseDeposit).getLastD (zeros digestBytes) }

private def mismatched : EncodingInput :=
  { matching with expectedRoot := zeros 32 }

private def runView (input : EncodingInput) : View :=
  observe ((encode input).run defaultState)

/-- Positive: the four observables commit together. Concat of `10 ++ 11` is
the packed source value `5` with power `11`. Digest count/fingerprint and
the verification bit are persisted. -/
example : (runView matching).status = .committed := by native_decide

example : (runView matching).observables.concat = packConcat 5 11 := by native_decide

example : (runView matching).observables.verified = 1 := by native_decide

/-- Root mismatch reverts the whole transaction. -/
example : runView mismatched = ⟨.reverted, zeroObs⟩ := by native_decide

/-- Single-child drop: omitting the concat write is observationally different. -/
private def dropConcatMutant (input : EncodingInput) : Contract Observables :=
  fun snapshot =>
    match (encode input).run snapshot with
    | .revert reason state => .revert reason state
    | .success obs state =>
        .success obs (state.writeSlot (concatSlot 0) 0)

example :
    observe ((dropConcatMutant matching).run defaultState) ≠ runView matching := by
  native_decide

/-- Single-child drop: omitting the digest fingerprint. -/
private def dropDigestMutant (input : EncodingInput) : Contract Observables :=
  fun snapshot =>
    match (encode input).run snapshot with
    | .revert reason state => .revert reason state
    | .success obs state =>
        .success obs (state.writeSlot (digestXorSlot 0) 0)

example :
    observe ((dropDigestMutant matching).run defaultState) ≠ runView matching := by
  native_decide

/-- Single-child drop: omitting the verification bit. -/
private def dropVerifiedMutant (input : EncodingInput) : Contract Observables :=
  fun snapshot =>
    match (encode input).run snapshot with
    | .revert reason state => .revert reason state
    | .success obs state =>
        .success obs (state.writeSlot (verifiedSlot 0) 0)

example :
    observe ((dropVerifiedMutant matching).run defaultState) ≠ runView matching := by
  native_decide

/-- Encoding-mismatch: swapped concat operands change the packed observable. -/
private def swappedConcat (input : EncodingInput) : EncodingInput :=
  { input with lhs := input.rhs, rhs := input.lhs }

example :
    (runView (swappedConcat matching)).observables.concat ≠
      (runView matching).observables.concat := by native_decide

/-- Encoding-mismatch: the swapped concat is the source wrong-order mutant. -/
example :
    packConcat (concatenatedIndex matching.rhs matching.lhs) matching.lhs.pow ≠
      packConcat (concatenatedIndex matching.lhs matching.rhs) matching.rhs.pow := by
  native_decide

/-- Hash-collision mutant: accept any 32-byte expected root. Two different
expected roots then collide, while the real transaction distinguishes them. -/
private def lengthOnlyRootMutant (input : EncodingInput) : View :=
  if input.expectedRoot.size == 32 && widthsOk input then
    match sourceConcat input.lhs input.rhs with
    | .value index pow =>
        ⟨.committed, ⟨bytesToWord (computedRootBytes input.deposit),
          packConcat index pow,
          xorWords ((digestChain input.deposit).map bytesToWord), 1⟩⟩
    | _ => ⟨.reverted, zeroObs⟩
  else ⟨.reverted, zeroObs⟩

example :
    lengthOnlyRootMutant matching = lengthOnlyRootMutant mismatched ∧
      runView matching ≠ runView mismatched := by native_decide

/-- Two-batch chaining: the second encoding uses the first concat as its left
index. An independent second batch that ignores the first concat differs. -/
private def secondDeposit : Inputs :=
  { publicKey := zeros 47 ++ ByteArray.mk #[1]
    withdrawalCredentials := zeros 32
    signature := zeros 96
    amountLittleEndian := zeros 8 }

private def secondMatching : EncodingInput :=
  { deposit := secondDeposit
    lhs := gindex 1 0
    rhs := gindex 1 4
    expectedRoot := (digestChain secondDeposit).getLastD (zeros digestBytes) }

example :
    let chained := chainedInput matching secondMatching
    chained.isSome = true ∧
      (observeTwo ((encodeTwo matching secondMatching).run defaultState)).1.status =
        .committed ∧
      (observeTwo ((encodeTwo matching secondMatching).run defaultState)).2.status =
        .committed := by native_decide

/-- Two-batch mutant: the second batch keeps its own lhs instead of the first
concat, so the chained concat observable differs. -/
example :
    (observeTwo ((encodeTwo matching secondMatching).run defaultState)).2.observables.concat ≠
      (runView secondMatching).observables.concat := by native_decide

private def revertReason {α : Type} : ContractResult α → Option String
  | .revert reason _ => some reason
  | .success _ _ => none

/-- Failure after the first batch's writes rolls storage back. -/
example :
    revertReason ((encodeTwo matching secondMatching true).run defaultState) =
      some "INJECTED_AFTER_WRITES" := by native_decide

example (rollback : ContractState) (reason : String)
    (h : (encodeTwo matching secondMatching true).run defaultState =
      .revert reason rollback) :
    rollback = defaultState :=
  revert_restores_snapshot_two matching secondMatching true defaultState rollback reason h

/-- Failure after a single-batch intermediate write rolls storage back. -/
example :
    revertReason ((encode matching true).run defaultState) =
      some "INJECTED_AFTER_WRITES" := by native_decide

example (rollback : ContractState) (reason : String)
    (h : (encode matching true).run defaultState = .revert reason rollback) :
    rollback = defaultState :=
  revert_restores_snapshot matching true defaultState rollback reason h

end LidoSRv3.Tests.SszEncodingTxMutants
