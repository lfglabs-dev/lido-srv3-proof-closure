import LidoSRv3.Audit.Source.TopupBeaconEffects
import LidoSRv3.Audit.Source.TopupFundedSource
import LidoSRv3.Audit.Source.TrioReserve1.Pipeline
import LidoSRv3.Audit.Source.TrioReserve1.BalanceSpec

/-! The pinned TOPUP beacon loop over actual source input bytes and Live.World.
No caller projection, manual debit/credit, per-call success oracle or root-match
premise. The old PR267 implementation is imported for source amounts only and
remains unchanged. -/
namespace LidoSRv3.Audit.Source.TopupBeaconBatch
open TrioReserve1 Live TopupBeaconCallee
open LidoSRv3.Audit.Verity.TopupTx LidoSRv3.Audit.SolidityTopup
open DepositDataRootCorrespondence

/-- Count specification selects source nonzero allocations. -/
def nonzeroCount (amounts : List Nat) : Nat :=
  (amounts.filter fun a => a ≠ 0).length

def attempts (ctx : Context) (target : Address)
    (inputs : List SourceDepositDataRootInput) (amounts : List Nat) : List Attempt :=
  (inputs.zip amounts).filterMap fun p => if p.2 = 0 then none else
    some ⟨⟨ctx.self,target,word p.2,TopupBeaconEffects.sourcePayload p.1⟩,true,[],[]⟩

/-- Source helper guard order: key width before zero skip; minimum and uint64
before CALL. Exact gwei alignment is checked by the actual callee. -/
def loop (ctx : Context) (target : Address) :
    List SourceDepositDataRootInput → List Nat → Exec Unit
  | [], [] => pureExec ()
  | [], _::_ => fail (.reason "SourceDepositLengthMismatch")
  | _::_, [] => fail (.reason "SourceDepositLengthMismatch")
  | input::inputs, a::amounts => do
    require (decide (input.publicKey.length = 48)) (.reason "InvalidPublicKeysBatchLength")
    if a = 0 then loop ctx target inputs amounts
    else do
      require (decide (10^18 ≤ a)) (.reason "DepositAmountTooLow")
      require (decide (a / 10^9 ≤ 2^64-1)) (.reason "AmountTooLarge")
      let _ ← TopupBeaconEffects.push sha256 ctx target (TopupBeaconEffects.sourcePayload input) (word a)
      loop ctx target inputs amounts

/-- Source-valued admission, independently phrased over the paired inputs. -/
def Admissible (input : SourceDepositDataRootInput) (a : Nat) : Prop :=
  input.publicKey.length = 48 ∧ input.withdrawalCredentials.length = 32 ∧
  input.signature.length = 96 ∧ input.amountGwei = a / 10^9 ∧ a < uint256Modulus ∧
  (a ≠ 0 → 10^18 ≤ a ∧ a % 10^9 = 0 ∧ a / 10^9 ≤ 2^64-1)

/-- Per-call effect predicate has no execution/result equality. -/
structure Step (ctx : Context) (target : Address) (input : SourceDepositDataRootInput)
    (a : Nat) (before after : World) : Prop where
  balances : CallSpec.Balances before.balances after.balances ctx.self target a
  count : (after.core.readContractSlot target.val countSlot).val =
    (before.core.readContractSlot target.val countSlot).val + 1
  event_fields : after.logs = before.logs ++ [depositEvent target (sourceFields input) (word a)
    (before.core.readContractSlot target.val countSlot).val]
  branch : BranchEffect sha256 target (reconstructed sha256 (sourceFields input) (word a)) before after

/-- A chain of independent per-deposit effects, retaining every intermediate
branch insertion and event instead of replacing the batch by aggregate credit. -/
inductive Effects (ctx : Context) (target : Address) :
    List SourceDepositDataRootInput → List Nat → World → World → Prop where
  | nil (w : World) : Effects ctx target [] [] w w
  | zero (input inputs amounts before after)
      (tail : Effects ctx target inputs amounts before after) :
      Effects ctx target (input::inputs) (0::amounts) before after
  | positive (input inputs a amounts before middle after) (hn : a ≠ 0)
      (step : Step ctx target input a before middle)
      (tail : Effects ctx target inputs amounts middle after) :
      Effects ctx target (input::inputs) (a::amounts) before after

theorem branch_code (hash : Hash) (target : Address) (node : Word) (before after : World)
    (h : BranchEffect hash target node before after) : after.core.codeSize = before.core.codeSize := by
  obtain ⟨_, _, _, _, he⟩ := h
  rw [he, Pipeline.write_code, Pipeline.write_code]

set_option maxRecDepth 2048 in
/-- Derive each CALL's funding and capacity from the initial mathematical sum
and initial count plus number of nonzero entries. No per-call state guard,
callee frame, acceptance or successful execution is provided. -/
theorem loop_success (ctx : Context) (target : Address) (amounts : List Nat) :
    ∀ (inputs : List SourceDepositDataRootInput) (before : World),
    List.Forall₂ Admissible inputs amounts →
    ctx.self ≠ target →
    (before.core.codeSize target.val).val ≠ 0 →
    allocSum amounts ≤ before.balances ctx.self →
    (before.core.readContractSlot target.val countSlot).val + nonzeroCount amounts ≤ maxCount →
    ∃ after, loop ctx target inputs amounts before = ⟨.ok (),after,attempts ctx target inputs amounts⟩ ∧
      CallSpec.Balances before.balances after.balances ctx.self target (allocSum amounts) ∧
      (after.core.readContractSlot target.val countSlot).val =
        (before.core.readContractSlot target.val countSlot).val + nonzeroCount amounts ∧
      after.core.codeSize = before.core.codeSize ∧ Effects ctx target inputs amounts before after := by
  induction amounts with
  | nil =>
    intro inputs before ha _ _ _ _
    cases ha
    exact ⟨before,rfl,by simp [CallSpec.Balances,allocSum],by simp [nonzeroCount],rfl,.nil before⟩
  | cons a amounts ih =>
    intro inputs before ha hd hc hf hcap
    cases ha with
    | cons hi ht =>
      rename_i input inputs
      obtain ⟨hpk,hwc,hsig,hamount,hfit,hguards⟩ := hi
      by_cases hz : a = 0
      · subst a
        obtain ⟨after,he,hb,hn,hcode,heffects⟩ := ih inputs before ht hd hc
          (by simpa [allocSum] using hf) (by simpa [nonzeroCount] using hcap)
        refine ⟨after,?_,by simpa [allocSum] using hb,by simpa [nonzeroCount] using hn,hcode,
          .zero _ _ _ _ _ heffects⟩
        simp [loop,hpk,require,bind,pure,bindExec,pureExec,he,attempts]
      · obtain ⟨hmin,halign,hmax⟩ := hguards hz
        have hv : (word a).val = a := word_val hfit
        have hnz : nonzeroCount (a::amounts) = 1 + nonzeroCount amounts := by
          simp [nonzeroCount,hz,Nat.add_comm]
        have hfirst : (before.core.readContractSlot target.val countSlot).val < maxCount := by
          rw [hnz] at hcap; omega
        obtain ⟨middle,he,hb,hn,hlogs,hbranch⟩ := TopupBeaconEffects.source_push_success
          input ctx target (word a) before hpk hwc hsig (by rwa [hv]) (by rwa [hv])
          (by rwa [hv]) (by rw [hv,hamount]) hfirst hc (by rw [hv]; unfold allocSum at hf; omega)
        have hcount : (middle.core.readContractSlot target.val countSlot).val =
            (before.core.readContractSlot target.val countSlot).val+1 := by
          rw [hn]
          apply word_val
          unfold maxCount at hfirst
          unfold uint256Modulus
          omega
        have hcode := branch_code _ _ _ _ _ hbranch
        have hbal : CallSpec.Balances before.balances middle.balances ctx.self target a := by rwa [hv] at hb
        have hsender := hbal ctx.self
        simp only [if_neg hd,ite_true,Nat.add_zero] at hsender
        obtain ⟨after,htail,hbTail,hnTail,hcodeTail,effectsTail⟩ := ih inputs middle ht hd
          (by rwa [hcode]) (by unfold allocSum at hf; omega) (by rw [hcount]; rw [hnz] at hcap; omega)
        refine ⟨after,?_,?_,?_,hcodeTail.trans hcode,
          .positive _ _ _ _ _ _ _ hz ⟨hbal,hcount,hlogs,hbranch⟩ effectsTail⟩
        · simp only [loop,hpk,decide_true,require,if_true,bind,pure,bindExec,pureExec,if_neg hz,
            hmin,hmax,he,htail]
          simp [attempts,hz]
        · intro account
          have h1 := hbal account
          have h2 := hbTail account
          unfold allocSum
          split_ifs at h1 h2 ⊢ <;> omega
        · rw [hnTail,hcount,hnz]; omega

/-- Finite ledger bounds are inherited from an independent initial world
invariant; initial reachability or asset supply is not invented here. -/
theorem batch_bounded (ctx : Context) (target : Address) (amounts : List Nat)
    (inputs : List SourceDepositDataRootInput) (before : World)
    (ha : List.Forall₂ Admissible inputs amounts) (hd : ctx.self ≠ target)
    (hc : (before.core.codeSize target.val).val ≠ 0)
    (hf : allocSum amounts ≤ before.balances ctx.self)
    (hcap : (before.core.readContractSlot target.val countSlot).val + nonzeroCount amounts ≤ maxCount)
    (accounts : List Address) (limit : Nat)
    (hb : BalanceSpec.Bounded before.balances accounts limit)
    (hs : ctx.self ∈ accounts) (ht : target ∈ accounts) :
    ∃ after, loop ctx target inputs amounts before = ⟨.ok (),after,attempts ctx target inputs amounts⟩ ∧
      BalanceSpec.Bounded after.balances accounts limit ∧
      BalanceSpec.mass after.balances accounts = BalanceSpec.mass before.balances accounts := by
  obtain ⟨after,he,hbalances,_⟩ := loop_success ctx target amounts inputs before ha hd hc hf hcap
  exact ⟨after,he,BalanceSpec.preserves _ _ _ _ _ _ _ hb hs ht hbalances⟩

def AmountsAdmitted (amounts : List Nat) : Prop :=
  ∀ a ∈ amounts, a ≠ 0 → 10^18 ≤ a ∧ a % 10^9 = 0 ∧ a / 10^9 ≤ 2^64-1

theorem sourceDepositsOf_admissible (call : TopupCall) (pubkeys : List (List Nat)) :
    ∀ (amounts : List Nat)
      (hpks : ∀ pk ∈ pubkeys, pk.length = 48 ∧ ∀ b ∈ pk, b < 256)
      (hfit : ∀ a ∈ amounts, a < uint256Modulus)
      (hwc : call.routerWithdrawalCredentials.length = 32)
      (ht : call.withdrawalCredentialsType < 256)
      (hbytes : ∀ b ∈ call.routerWithdrawalCredentials, b < 256),
      pubkeys.length = amounts.length → AmountsAdmitted amounts →
      List.Forall₂ Admissible (sourceDepositsOf call pubkeys amounts hpks hfit hwc ht hbytes) amounts := by
  induction pubkeys with
  | nil =>
    intro amounts _ _ _ _ _ hl _
    have hz : amounts = [] := List.length_eq_zero_iff.mp hl.symm
    subst amounts
    exact .nil
  | cons pk pks ih =>
    intro amounts hpks hfit hwc ht hbytes hl hg
    cases amounts with
    | nil => simp at hl
    | cons a amounts =>
      apply List.Forall₂.cons
      · refine ⟨(hpks pk (by simp)).1,routerWithdrawalCredentials_length call hwc,?_,rfl,
          hfit a (by simp),hg a (by simp)⟩
        simp [sourceDepositInput,dummySignature]
      · exact ih amounts (fun key hk => hpks key (by simp [hk]))
          (fun n hn => hfit n (by simp [hn])) hwc ht hbytes
          (by simpa using hl) (fun n hn => hg n (by simp [hn]))

/-- Source lengths, source WC/setType, zero signature and the gwei amount all
come from the SAME call and allocation list used by the actual loop. -/
theorem sourceDeposits_admissible (call : TopupCall) (hw : SourceTopupCallWellFormed call)
    (hg : AmountsAdmitted call.moduleReturndata) :
    List.Forall₂ Admissible (sourceDeposits call hw) call.moduleReturndata :=
  sourceDepositsOf_admissible call call.pubkeys call.moduleReturndata
    ((pubkeysPinned_iff call.pubkeys).mp hw.2.2.2.1)
    (by simpa using hw.2.2.2.2.2) hw.1 hw.2.1
    ((bytesBounded_iff call.routerWithdrawalCredentials).mp hw.2.2.1)
    hw.2.2.2.2.1 hg

set_option maxRecDepth 4096 in
/-- An actual canonical source payload reaches the callee's alignment guard.
Neither SHA equality nor tree availability is needed for this rejection. -/
theorem source_push_unaligned (input : SourceDepositDataRootInput)
    (ctx : Context) (target : Address) (value : Word) (before : World)
    (hpk : input.publicKey.length = 48) (hwc : input.withdrawalCredentials.length = 32)
    (hsig : input.signature.length = 96) (hmin : 10^18 ≤ value.val)
    (halign : value.val % 10^9 ≠ 0)
    (hcode : (before.core.codeSize target.val).val ≠ 0)
    (hfunds : value.val ≤ before.balances ctx.self) :
    TopupBeaconEffects.push sha256 ctx target (TopupBeaconEffects.sourcePayload input) value before =
      ⟨.error (.bubbled "deposit value not multiple of gwei".toUTF8.toList),before,
        [⟨⟨ctx.self,target,value,TopupBeaconEffects.sourcePayload input⟩,false,
          "deposit value not multiple of gwei".toUTF8.toList,[]⟩]⟩ := by
  have hd : dispatch sha256 target
      ⟨ctx.self,target,value,TopupBeaconEffects.sourcePayload input⟩
      (transfer before ctx.self target value.val) = rejected "deposit value not multiple of gwei" := by
    unfold dispatch
    simp only [ne_eq,not_true_eq_false,if_false,
      TopupBeaconEffects.decode_sourcePayload input hpk hwc hsig]
    simp only [deposit,sourceFields,List.length_map,hpk,hwc,hsig,ne_eq,not_true_eq_false,
      if_false,Nat.not_lt.mpr hmin,halign,not_false_eq_true,if_true]
  unfold TopupBeaconEffects.push CallData.invoke
  simp only [hcode,if_false,Nat.not_lt.mpr hfunds,hd,rejected]

end LidoSRv3.Audit.Source.TopupBeaconBatch
