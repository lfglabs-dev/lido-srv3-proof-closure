import LidoSRv3.Audit.Source.TopupRouterContinuation

namespace LidoSRv3.Tests.TopupRouterContinuationMutants
open LidoSRv3.Audit.Source TrioReserve1 Live TopupBeaconCallee TopupBeaconBatch
open LidoSRv3.Audit.Verity LidoSRv3.Audit.Verity.TopupTx
open LidoSRv3.Audit.SolidityTopup TopupRouterContinuation

set_option maxRecDepth 16384
set_option maxHeartbeats 2000000

def address (n : Nat) : Address := Verity.Core.Address.ofNat n
def ether : Nat := 10^18
def context : Context := ⟨address 1,address 2⟩
def beacon : Address := address 8
def config : Pipeline.Config :=
  ⟨address 3,⟨address 4,address 2,address 5⟩,⟨word 0,word 1⟩,address 6,⟨0,1,1,7⟩,address 1⟩
/-- Mapping hash is an explicit fixture; source SHA remains opaque. -/
def mapHash : TopupRouterCredentials.Keccak := fun _ => word 90
def before : World :=
  let core := {Verity.defaultState with codeSize := fun _ => word 1,blockTimestamp := word 1}
  let core := (core.writeContractSlot 1 locatorSlot (word 3)).writeContractSlot 5 Oracle.consensusSlot (word 6)
  let core := (core.writeContractSlot 1 activeSlot (word 1)).writeContractSlot 1 bufferSlot (word (100*ether))
  let core := core.writeContractSlot 4 Queue.bunkerSlot (word (2^256-1))
  let core := (core.writeContractSlot 6 7 (word (2^64))).writeContractSlot 1 seedSlot (word 9)
  let core := (core.writeContractSlot 8 countSlot (word 3)).writeContractSlot 2 90 (word (2*2^232))
  let core := core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+4) (word 42)
  ⟨core,fun a => if a=address 1 then 100*ether else if a=address 2 then 7 else if a=beacon then 11 else 0,
    [⟨address 40,"ModuleEffect",[word 77]⟩]⟩
def reject : External := fun _ _ => .rejected []
def rejectStatic : StaticCall.External := fun _ _ => .rejected []
def callee := Pipeline.external (fun _ => word 0) config rejectStatic reject
def key (b : UInt8) : List UInt8 := b :: List.replicate 47 0
def input : Input :=
  ⟨word 7,word (3*ether),[key 1,key 9,key 2],
    [word (2*ether),word (2*ether),word (2*ether)],[word ether,word 0,word (2*ether)]⟩
def gateway : TopupWeiBounds.GatewayConfig := ⟨⟨2000000000,by decide⟩,⟨3,by decide⟩,⟨0,by decide⟩⟩
def validator : TopupWeiBounds.ValidatorInput := ⟨⟨0,by decide⟩,⟨0,by decide⟩,⟨2^64-1,by decide⟩,false⟩
def result := TopupRouterContinuation.execute mapHash callee context beacon input before

def positiveFacts := positive_success mapHash gateway [validator,validator,validator]
  [2000000000,2000000000,2000000000] (by decide) (by decide)
  (fun _ => word 0) config rejectStatic reject context beacon before input (3*ether)
  (by decide) (by decide) (by decide) (by decide) (by decide)
  (by simp [input,key])
  (by change ∀ a ∈ [ether,0,2*ether], a ≠ 0 → 10^18 ≤ a; simp [ether]) 0 0 1 0
  (by constructor <;> decide) (by decide) (by decide) (by rfl)
  (by rfl) (by decide) (by rfl) (by rfl) (by decide) (by rfl)
  (by decide) (by decide) (by decide) (by decide) (by decide) (by decide)

example : result.outcome = .ok () := positiveFacts.2.1
example : result.world.balances (address 2) = 7 := positiveFacts.2.2.2.1
example : result.world.balances (address 1) = 97*ether := by
  have h := positiveFacts.2.2.2.2.1
  change result.world.balances (address 1) + 3*ether = 100*ether at h
  omega
example : result.world.balances beacon = 11+3*ether := positiveFacts.2.2.2.2.2.1
example : (result.world.core.readContractSlot 8 countSlot).val = 5 := positiveFacts.2.2.2.2.2.2.1
example : (result.world.logs.getLast?).map (fun l => (l.emitter.val,l.name,l.values.map (·.val))) =
    some (2,"StakingRouterETHTopUp",[7,3*ether]) := by
  obtain ⟨withdrawn,deposited,trace,_,_,_,_,hl,_⟩ := positiveFacts.2.2.2.2.2.2.2
  change result.world.logs = _ at hl
  rw [hl]
  simp only [List.getLast?_append,List.getLast?_singleton]
  rfl

/-- First-guard order and true wrapped arithmetic, without any CALL. -/
example : guardSum [1] [] 0 = .error (.reason "AmountNotAlignedToGwei") := by decide
example : guardSum [1000000000] [] 0 = .error (.reason "Panic(0x32)") := by decide
example : guardSum [1000000000] [0] 0 = .error (.reason "AllocationExceedsLimit") := by decide
example : guardSum [1000000000] [1000000000] (2^256-1000000000) = .ok 0 := by decide
example : guardSum [2^256-1,1] [2^256-1,1] 0 = .error (.reason "AmountNotAlignedToGwei") := by decide
example : guardSum [] [1] 0 = .ok 0 := by decide
example : guardSum [0] [1,2] 0 = .ok 0 := by decide

def overBudget := {input with roundedTarget := word 0}
example : (TopupRouterContinuation.execute mapHash reject context beacon overBudget before).outcome =
    .error (.reason "ModuleReturnExceedTarget") := by rfl
example : (TopupRouterContinuation.execute mapHash reject context beacon overBudget before).attempts = [] := by rfl

def zero := {input with allocations := [],pubkeys := []}
example : TopupRouterContinuation.execute mapHash reject context beacon zero before =
    ⟨.ok (),{before with logs := before.logs ++ [topUpEvent context.sender zero 0]},[]⟩ :=
  zero_event _ _ _ _ _ _ (by decide)
example : (TopupRouterContinuation.execute mapHash reject context beacon zero before).world.logs.head? =
    before.logs.head? := by rfl

/-- Positive short response: real withdrawal precedes helper length failure. -/
def short := {input with allocations := [word ether]}
def poor : World := {before with balances := fun _ => 7}
example : (TopupRouterContinuation.execute mapHash callee context beacon short poor).outcome =
    .error (.bubbled []) := by rfl
example : (TopupRouterContinuation.execute mapHash callee context beacon short before).outcome =
    .error (.reason "ArrayLengthMismatch") := by rfl
example : (TopupRouterContinuation.execute mapHash callee context beacon short before).world = before :=
  failure_restores _ _ _ _ _ _ _ (by rfl)
example : ((TopupRouterContinuation.execute mapHash callee context beacon short before).attempts.getLast?).map
    (fun a => (a.request.caller.val,a.request.target.val,a.request.value.val)) = some (1,2,ether) := by rfl

def badKey := {input with pubkeys := [[],key 9,key 2]}
example : (TopupRouterContinuation.execute mapHash callee context beacon badKey before).outcome =
    .error (.reason "InvalidPublicKeysBatchLength") := by rfl
/-- Empty helper is distinct from nonempty mismatched arrays, including after pull. -/
example : helper mapHash (TopupBeaconFundedTx.routerContext context) beacon
    {input with pubkeys := []} before = ⟨.ok (),before,[]⟩ := by rfl
example : (TopupRouterContinuation.execute mapHash callee context beacon
    {input with pubkeys := [],allocations := [word ether]} before).outcome =
    .error (.reason "Panic(0x01)") := by rfl

/-- The physical word selection changes with the world, not a cached WC field. -/
def changed : World :=
  let core := before.core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+4) (word 99)
  {before with core := core.writeContractSlot 2 90 (word (1*2^232))}
example : (callAt mapHash (address 2) input before).withdrawalCredentialsType = 2 := by rfl
example : (callAt mapHash (address 2) input changed).withdrawalCredentialsType = 1 := by rfl
example : ((inputAt mapHash (address 2) input changed (key 1) (word ether)).withdrawalCredentials.getLast?) =
    some 99 := by decide
example : (inputAt mapHash (address 2) input changed (key 1) (word ether)).withdrawalCredentials.head? =
    some 1 := by decide
example : TopupRouterCredentials.typeOf (word (123+7*2^232+54321*2^240)) = 7 := by decide


/-- A source-admitted aligned amount below one ETH fails only after a real
successful first beacon insertion. No synthetic callee failure is injected. -/
def late := {input with pubkeys := [key 1,key 2],allocations := [word ether,word 1000000000]}
def lateWithdrawn := Live.run (TopupLiveWithdrawal.suffix callee context (word (ether+1000000000))) before
def lateFirst := inputAt mapHash context.sender late lateWithdrawn.world (key 1) (word ether)
def lateSecond := inputAt mapHash context.sender late lateWithdrawn.world (key 2) (word 1000000000)

theorem late_execution : TopupRouterContinuation.execute mapHash callee context beacon late before =
    ⟨.error (.reason "DepositAmountTooLow"),before,lateWithdrawn.attempts ++
      [⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload lateFirst⟩,true,[],[]⟩]⟩ := by
  obtain ⟨middle,hfirst,_,_,_,_⟩ := TopupBeaconEffects.source_push_success
    lateFirst (TopupBeaconFundedTx.routerContext context) beacon (word ether) lateWithdrawn.world
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by rfl)
    (by decide) (by decide) (by decide)
  have hloop : TopupBeaconBatch.loop (TopupBeaconFundedTx.routerContext context) beacon
      [lateFirst,lateSecond] [ether,1000000000] lateWithdrawn.world =
      ⟨.error (.reason "DepositAmountTooLow"),middle,
        [⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload lateFirst⟩,true,[],[]⟩]⟩ := by
    simp only [TopupBeaconBatch.loop,show lateFirst.publicKey.length = 48 from by decide,
      show lateSecond.publicKey.length = 48 from by decide,decide_true,require,if_true,bind,pure,
      bindExec,pureExec,show ether ≠ 0 from by decide,show (1000000000:Nat) ≠ 0 from by decide,if_false,
      show 10^18 ≤ ether from by decide,show ¬10^18 ≤ (1000000000:Nat) from by decide,
      show ether/10^9 ≤ 2^64-1 from by decide,decide_false,Bool.false_eq_true,hfirst,fail,List.nil_append,List.cons_append]
    rfl
  have hh : helper mapHash (TopupBeaconFundedTx.routerContext context) beacon late lateWithdrawn.world =
      ⟨.error (.reason "DepositAmountTooLow"),middle,
        [⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload lateFirst⟩,true,[],[]⟩]⟩ := by
    exact hloop
  have hs : lateWithdrawn.outcome = .ok () := rfl
  have hg : guardSum (values late.allocations) (values late.limits) 0 = .ok (ether+1000000000) := by decide
  unfold TopupRouterContinuation.execute Live.run
  simp only [program,hg,show ¬ether+1000000000 > late.roundedTarget.val from by decide,
    show ether+1000000000 ≠ 0 from by decide,if_false,bindExec]
  dsimp only [lateWithdrawn] at hs hh ⊢
  rw [hs,hh]

example : (TopupRouterContinuation.execute mapHash callee context beacon late before).world = before := by
  rw [late_execution]
example : ((TopupRouterContinuation.execute mapHash callee context beacon late before).attempts.reverse.take 2).reverse.map
    (fun a => (a.request.target.val,a.accepted)) = [(2,true),(8,true)] := by
  rw [late_execution]
  decide
example : (TopupRouterContinuation.execute mapHash callee context beacon late before).world.logs = before.logs := by
  rw [late_execution]

/-- Synthetic effectful CALL interpreter, deliberately not the delivered router
receiver: verifies that the continuation reads CURRENT post-withdrawal words.
It is an ordering test, not a deployed reentry or callback-reachability claim. -/
def changeWords (w : World) : World :=
  let core := w.core.writeContractSlot 2 (TopupRouterCredentials.routerRoot+4) (word 99)
  {w with core := core.writeContractSlot 2 90 (word (1*2^232))}
def changingCallee : External := fun req w =>
  match callee req w with
  | .success bytes after => .success bytes (changeWords after)
  | reply => reply

def single := {input with pubkeys := [key 1],allocations := [word ether]}
def changedWithdrawal := Live.run (TopupLiveWithdrawal.suffix changingCallee context (word ether)) before
def changedInput := inputAt mapHash context.sender single changedWithdrawal.world (key 1) (word ether)

theorem current_words_execute : ∃ after : World,
    TopupRouterContinuation.execute mapHash changingCallee context beacon single before =
      ⟨.ok (),{after with logs := after.logs ++ [topUpEvent context.sender single ether]},
        changedWithdrawal.attempts ++
          [⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload changedInput⟩,true,[],[]⟩]⟩ := by
  obtain ⟨after,hpush,hbalances,_,_,_⟩ := TopupBeaconEffects.source_push_success
    changedInput (TopupBeaconFundedTx.routerContext context) beacon (word ether) changedWithdrawal.world
    (by decide) (by decide) (by decide) (by decide) (by decide) (by decide) (by rfl)
    (by decide) (by decide) (by decide)
  have hr : after.balances context.sender = before.balances context.sender := by
    have h := hbalances context.sender
    change after.balances context.sender + ether = (7+ether)+0 at h
    change after.balances context.sender = 7
    omega
  have hh : helper mapHash (TopupBeaconFundedTx.routerContext context) beacon single changedWithdrawal.world =
      ⟨.ok (),after,[⟨⟨context.sender,beacon,word ether,TopupBeaconEffects.sourcePayload changedInput⟩,true,[],[]⟩]⟩ := by
    change TopupBeaconBatch.loop _ _ [changedInput] [ether] _ = _
    simp only [TopupBeaconBatch.loop,show changedInput.publicKey.length = 48 from by decide,
      show ether ≠ 0 from by decide,show 10^18 ≤ ether from by decide,
      show ether/10^9 ≤ 2^64-1 from by decide,decide_true,require,if_true,if_false,
      bind,pure,bindExec,pureExec,hpush,List.append_nil,List.nil_append]
    rfl
  have hs : changedWithdrawal.outcome = .ok () := rfl
  have hg : guardSum (values single.allocations) (values single.limits) 0 = .ok ether := by decide
  refine ⟨after,?_⟩
  unfold TopupRouterContinuation.execute Live.run
  simp only [program,hg,show ¬ether > single.roundedTarget.val from by decide,
    show ether ≠ 0 from by decide,if_false,bindExec]
  dsimp only [changedWithdrawal] at hs hh ⊢
  rw [hs,hh]
  simp [finish,hr]

example : (TopupRouterContinuation.execute mapHash changingCallee context beacon single before).outcome = .ok () := by
  obtain ⟨_,he⟩ := current_words_execute
  rw [he]
example : ((TopupRouterContinuation.execute mapHash changingCallee context beacon single before).attempts.getLast?).map
    (fun a => (a.request.payload.drop 260).take 32) = some (1 :: List.replicate 30 0 ++ [99]) := by
  obtain ⟨_,he⟩ := current_words_execute
  rw [he]
  simp only [List.getLast?_append,List.getLast?_singleton]
  decide


example : (TopupRouterContinuation.execute mapHash callee context beacon
    {input with pubkeys := [[],key 9,key 2],allocations := [word 0,word ether,word 0]} before).outcome =
    .error (.reason "InvalidPublicKeysBatchLength") := by rfl
example : (TopupRouterContinuation.execute mapHash reject context beacon
    {input with allocations := [word 0]} before).outcome = .ok () := by rfl

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
  have h := postcondition_bounded mapHash context beacon input before result (3*ether)
    positiveFacts.2.2 support uint256Modulus initial_bounded (by decide) (by decide)
  exact h

end LidoSRv3.Tests.TopupRouterContinuationMutants

#print axioms LidoSRv3.Audit.Source.TopupRouterCredentials.typeOf_packed
#print axioms LidoSRv3.Audit.Source.TopupRouterContinuation.guardSum_spec
#print axioms LidoSRv3.Audit.Source.TopupRouterContinuation.checked_fields
#print axioms LidoSRv3.Audit.Source.TopupRouterContinuation.inputs_admissible
#print axioms LidoSRv3.Audit.Source.TopupRouterContinuation.positive_success
#print axioms LidoSRv3.Audit.Source.TopupRouterContinuation.postcondition_bounded
#print axioms LidoSRv3.Audit.Source.TopupRouterContinuation.failure_restores

#print axioms LidoSRv3.Tests.TopupRouterContinuationMutants.late_execution
#print axioms LidoSRv3.Tests.TopupRouterContinuationMutants.current_words_execute
