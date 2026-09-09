import LidoSRv3.Audit.Verity.TopupBeaconFundedTx

namespace LidoSRv3.Tests.TopupBeaconFundedMutants
open LidoSRv3.Audit.Source TrioReserve1 Live TopupBeaconCallee TopupBeaconBatch
open LidoSRv3.Audit.Verity LidoSRv3.Audit.Verity.TopupTx LidoSRv3.Audit.Verity.TopupBeaconFundedTx
open LidoSRv3.Audit.SolidityTopup

set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def address (n : Nat) : Address := Verity.Core.Address.ofNat n
def ether : Nat := 10^18
def context : Context := ⟨address 1,address 2⟩
def beacon : Address := address 8
def config : Pipeline.Config :=
  ⟨address 3,⟨address 4,address 2,address 5⟩,⟨word 0,word 1⟩,address 6,⟨0,1,1,7⟩,address 1⟩
def before : World :=
  let core := {Verity.defaultState with codeSize := fun _ => word 1,blockTimestamp := word 1}
  let core := (core.writeContractSlot 1 locatorSlot (word 3)).writeContractSlot 5 Oracle.consensusSlot (word 6)
  let core := (core.writeContractSlot 1 activeSlot (word 1)).writeContractSlot 1 bufferSlot (word (100*ether))
  let core := core.writeContractSlot 4 Queue.bunkerSlot (word (2^256-1))
  let core := (core.writeContractSlot 6 7 (word (2^64))).writeContractSlot 1 seedSlot (word 9)
  let core := core.writeContractSlot 8 countSlot (word 3)
  ⟨core,fun a => if a=address 1 then 100*ether else if a=address 2 then 7 else if a=beacon then 11 else 0,[]⟩
def reject : External := fun _ _ => .rejected []
def rejectStatic : StaticCall.External := fun _ _ => .rejected []
def callee := Pipeline.external (fun _ => word 0) config rejectStatic reject
def key (b : Nat) : List Nat := b :: List.replicate 47 0
def call : TopupCall :=
  ⟨3*ether,List.replicate 32 0,2,[key 1,key 9,key 2],[0,1,2],[0,0,0],
    [ether,0,2*ether],[ether,0,2*ether]⟩
theorem wellFormed : SourceTopupCallWellFormed call := by decide
def result := TopupBeaconFundedTx.execute callee context beacon call wellFormed before

/-- Instantiate the universal source/callee theorem using physical fixture
inputs. SHA stays opaque: success is proved through field/root correspondence,
not by substituting a zero hash or an acceptance oracle. -/
def positiveFacts := positive_conservation (fun _ => word 0) config rejectStatic reject
  context beacon before call wellFormed 0 0 1 0
  (by constructor <;> decide) (by decide) (by decide) (by rfl) (by decide) (by decide)
  (by rfl) (by decide) (by rfl) (by rfl) (by decide) (by rfl) (by decide) (by decide)
  (by decide) (by decide) (by decide)
  (by simp [AmountsAdmitted,call,ether]) (by decide)

example : result.outcome = .ok () := positiveFacts.1
example : result.world.balances (address 2) = 7 := positiveFacts.2.1
example : result.world.balances (address 1) = 97*ether := by
  have h := positiveFacts.2.2.1
  change result.world.balances (address 1) + (ether + (0 + (2*ether + 0))) = 100*ether at h
  omega
example : result.world.balances beacon = 3*ether+11 := by
  have h := positiveFacts.2.2.2.1
  change result.world.balances beacon = 11 + (ether + (0 + (2*ether + 0))) at h
  omega
example : result.world.balances (address 9) = 0 :=
  positiveFacts.2.2.2.2.1 (address 9) (by decide) (by decide) (by decide)
example : (result.world.core.readContractSlot 8 countSlot).val = 5 := by
  exact positiveFacts.2.2.2.2.2.2.1

/-- Single chronological journal, with the real withdrawal callback before
both real beacon calls. The zero middle allocation emits no call. -/
example : (result.attempts.reverse.take 3).reverse.map (fun a =>
    (a.request.caller.val,a.request.target.val,a.request.value.val,a.accepted)) =
    [(1,2,3*ether,true),(2,8,ether,true),(2,8,2*ether,true)] := by
  have h := positiveFacts.2.2.2.2.2.2.2.1
  change result.attempts = _ at h
  rw [h]
  decide
example : (result.attempts.reverse.take 2).reverse.map (fun a => (a.request.payload.drop 164).take 1) =
    [[1],[2]] := by
  have h := positiveFacts.2.2.2.2.2.2.2.1
  change result.attempts = _ at h
  rw [h]
  decide

/-- Omitted or doubled beacon credit falsifies the independent aggregate law. -/
example : ¬ CallSpec.Balances before.balances before.balances (address 1) beacon (3*ether) := by
  intro h
  have he := h beacon
  change 11 + 0 = 11 + 3*ether at he
  norm_num [ether] at he
example : ¬ CallSpec.Balances before.balances
    (transfer before (address 1) beacon (6*ether)).balances (address 1) beacon (3*ether) := by
  intro h
  have he := h beacon
  change 11 + 6*ether + 0 = 11 + 3*ether at he
  norm_num [ether] at he

/-- No phantom wrap exclusion in the executable zero path. -/
def wrapCall : TopupCall :=
  ⟨0,List.replicate 32 0,2,[key 1,key 2],[0,1],[0,0],[0,0],[2^256-1,1]⟩
theorem wrapWellFormed : SourceTopupCallWellFormed wrapCall := by decide
example : TopupBeaconFundedTx.execute reject context beacon wrapCall wrapWellFormed before =
    ⟨.ok (),before,[]⟩ := wrapped_zero _ _ _ _ _ _ (by decide)

/-- Real Lido funds remain load-bearing despite sufficient accounting buffer. -/
def poor : World := {before with balances := fun _ => 7}
example : (TopupBeaconFundedTx.execute callee context beacon call wellFormed poor).outcome =
    .error (.bubbled []) := by rfl
example : (TopupBeaconFundedTx.execute callee context beacon call wellFormed poor).world = poor :=
  failure_restores _ _ _ _ _ _ _ (by rfl)

/-- A valid first deposit followed by an unaligned second source allocation.
The real withdrawal and first beacon CALL occur before the actual callee
rejects; the outer transaction restores the entire initial World. -/
def lateCall : TopupCall :=
  ⟨2*ether+1,List.replicate 32 0,2,[key 1,key 2],[0,1],[0,0],
    [ether,ether+1],[ether,ether+1]⟩
theorem lateWellFormed : SourceTopupCallWellFormed lateCall := by decide
def lateInputs := sourceDeposits lateCall lateWellFormed
def input1 := lateInputs[0]'(by decide)
def input2 := lateInputs[1]'(by decide)
def withdrawnLate := Live.run (TopupLiveWithdrawal.suffix callee context (amount lateCall)) before

theorem late_execution :
    TopupBeaconFundedTx.execute callee context beacon lateCall lateWellFormed before =
      ⟨.error (.bubbled "deposit value not multiple of gwei".toUTF8.toList),before,
        withdrawnLate.attempts ++
          [⟨⟨(routerContext context).self,beacon,word ether,TopupBeaconEffects.sourcePayload input1⟩,true,[],[]⟩,
           ⟨⟨(routerContext context).self,beacon,word (ether+1),TopupBeaconEffects.sourcePayload input2⟩,
            false,"deposit value not multiple of gwei".toUTF8.toList,[]⟩]⟩ := by
  obtain ⟨middle,hfirst,hbalances,_hcount,_hlogs,hbranch⟩ := TopupBeaconEffects.source_push_success
    input1 (routerContext context) beacon (word ether) withdrawnLate.world
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by rfl)
    (by decide) (by decide) (by decide)
  have hcode : (middle.core.codeSize beacon.val).val ≠ 0 := by
    rw [branch_code _ _ _ _ _ hbranch]
    decide
  have hfunds : (word (ether+1)).val ≤ middle.balances (routerContext context).self := by
    have h := hbalances (routerContext context).self
    change middle.balances (address 2) + ether = 7 + (ether + (ether+1+0)) + 0 at h
    change ether+1 ≤ middle.balances (address 2)
    omega
  have hsecond := source_push_unaligned input2 (routerContext context) beacon (word (ether+1)) middle
    (by decide) (by decide) (by decide) (by decide) (by decide) hcode hfunds
  have hinputs : sourceDeposits lateCall lateWellFormed = [input1,input2] := rfl
  have hloop : TopupBeaconBatch.loop (routerContext context) beacon
      (sourceDeposits lateCall lateWellFormed) lateCall.moduleReturndata withdrawnLate.world =
      ⟨.error (.bubbled "deposit value not multiple of gwei".toUTF8.toList),middle,
        [⟨⟨(routerContext context).self,beacon,word ether,TopupBeaconEffects.sourcePayload input1⟩,true,[],[]⟩,
         ⟨⟨(routerContext context).self,beacon,word (ether+1),TopupBeaconEffects.sourcePayload input2⟩,
          false,"deposit value not multiple of gwei".toUTF8.toList,[]⟩]⟩ := by
    rw [hinputs]
    change TopupBeaconBatch.loop _ _ _ [ether,ether+1] _ = _
    simp only [TopupBeaconBatch.loop,show input1.publicKey.length = 48 from by decide,
      show input2.publicKey.length = 48 from by decide,decide_true,require,if_true,bind,pure,
      bindExec,pureExec,show ether ≠ 0 from by decide,show ether+1 ≠ 0 from by decide,if_false,
      show 10^18 ≤ ether from by decide,show 10^18 ≤ ether+1 from by decide,
      show ether/10^9 ≤ 2^64-1 from by decide,show (ether+1)/10^9 ≤ 2^64-1 from by decide,
      hfirst,hsecond,List.nil_append,List.cons_append]
  have hsuccess : withdrawnLate.outcome = .ok () := rfl
  have hnonzero : allocSumUnchecked lateCall.moduleReturndata ≠ 0 := by decide
  unfold TopupBeaconFundedTx.execute Live.run
  simp only [TopupBeaconFundedTx.program,if_neg hnonzero,bindExec]
  dsimp only [withdrawnLate] at hloop hsuccess ⊢
  rw [hsuccess,hloop]

example : (TopupBeaconFundedTx.execute callee context beacon lateCall lateWellFormed before).world =
    before := by rw [late_execution]
example : ((TopupBeaconFundedTx.execute callee context beacon lateCall lateWellFormed before).attempts.reverse.take 3).reverse.map (fun a => (a.request.target.val,a.accepted)) = [(2,true),(8,true),(8,false)] := by
  rw [late_execution]
  decide

/-- Caller helper guard order and source zero skip remain executable. -/
def badKey := {input1 with publicKey := [],publicKeyBounded := by simp}
example : (TopupBeaconBatch.loop (routerContext context) beacon [badKey] [0] before).outcome =
    .error (.reason "InvalidPublicKeysBatchLength") := by rfl
example : TopupBeaconBatch.loop (routerContext context) beacon [input1] [0] before =
    ⟨.ok (),before,[]⟩ := by rfl
example : (TopupBeaconBatch.loop (routerContext context) beacon [input1] [1] before).outcome =
    .error (.reason "DepositAmountTooLow") := by rfl
example : (TopupBeaconBatch.loop (routerContext context) beacon [input1] [(2^64)*10^9] before).outcome =
    .error (.reason "AmountTooLarge") := by rfl
example : (TopupBeaconBatch.loop (routerContext context) beacon [] [1] before).outcome =
    .error (.reason "SourceDepositLengthMismatch") := by rfl
example : nonzeroCount [0,ether,0,ether,0] = 2 := by decide

def support : List Address := [address 1,address 2,beacon]
theorem initial_bounded : BalanceSpec.Bounded before.balances support uint256Modulus := by
  refine ⟨by decide,?_,by decide⟩
  intro account ha
  have h1 : account ≠ address 1 := by intro he; apply ha; simp [support,he]
  have h2 : account ≠ address 2 := by intro he; apply ha; simp [support,he]
  have h8 : account ≠ beacon := by intro he; apply ha; simp [support,he]
  simp only [before,h1,h2,h8,if_false]
example : BalanceSpec.Bounded result.world.balances support uint256Modulus ∧
    BalanceSpec.mass result.world.balances support = 100*ether+18 := by
  have h := positiveFacts.2.2.2.2.2.2.2.2.2 support uint256Modulus initial_bounded (by decide) (by decide)
  exact h

end LidoSRv3.Tests.TopupBeaconFundedMutants

#print axioms LidoSRv3.Audit.Source.TopupBeaconBatch.loop_success
#print axioms LidoSRv3.Audit.Source.TopupBeaconBatch.batch_bounded
#print axioms LidoSRv3.Audit.Source.TopupBeaconBatch.sourceDeposits_admissible
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.accounting_count
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.gateway_amount_exact
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.positive_conservation
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.wrapped_zero
#print axioms LidoSRv3.Audit.Verity.TopupBeaconFundedTx.failure_restores

#print axioms LidoSRv3.Audit.Source.TopupBeaconBatch.source_push_unaligned
