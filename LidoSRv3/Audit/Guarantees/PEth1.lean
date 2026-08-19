import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Verity.PEth1CompositionTx
import Mathlib.Tactic.SplitIfs

namespace LidoSRv3.Audit.Guarantees.PEth1

abbrev Address := Nat

/-- Abstract destinations covering every ETH-bearing leg of the P-ETH-1
inventory. `other` is the residual lateral destination the parent forbids. -/
inductive EthDestination
  | lido
  | withdrawalQueue
  | consolidationContract
  | withdrawalRequestContract
  | refundRecipient
  | other (addr : Address)
  deriving DecidableEq, Repr

structure EthMove where
  amount : Nat
  destination : EthDestination
  deriving DecidableEq, Repr

/-- P-ETH-1a approves only the two protocol rebalance/redemption destinations. -/
def is_approved (m : EthMove) : Prop :=
  m.destination = .lido ∨ m.destination = .withdrawalQueue

def totalAmount (moves : List EthMove) : Nat :=
  moves.foldl (fun acc m => acc + m.amount) 0

def approvedReturnMoves (moves : List EthMove) : List EthMove :=
  moves.filter fun m => m.destination = .lido ∨ m.destination = .withdrawalQueue

def guarantee : Guarantee := ⟨.pEth1, [.model, .source, .verityTx]⟩

/-! ## Sum laws for `totalAmount`

`totalAmount` is an accumulating `foldl`, so the parent needs the accumulator
generalised before it can be split across `++` and `List.replicate`. -/

private theorem foldl_amount (moves : List EthMove) (acc : Nat) :
    moves.foldl (fun a m => a + m.amount) acc = acc + totalAmount moves := by
  induction moves generalizing acc with
  | nil => simp [totalAmount]
  | cons m ms ih =>
      simp only [List.foldl_cons, totalAmount, Nat.zero_add]
      rw [ih (acc + m.amount), ih m.amount]
      omega

theorem totalAmount_nil : totalAmount [] = 0 := rfl

theorem totalAmount_cons (m : EthMove) (ms : List EthMove) :
    totalAmount (m :: ms) = m.amount + totalAmount ms := by
  simp only [totalAmount, List.foldl_cons, Nat.zero_add]
  exact foldl_amount ms m.amount

theorem totalAmount_append (xs ys : List EthMove) :
    totalAmount (xs ++ ys) = totalAmount xs + totalAmount ys := by
  induction xs with
  | nil => simp [totalAmount]
  | cons x xs ih =>
      rw [List.cons_append, totalAmount_cons, ih, totalAmount_cons]
      omega

theorem totalAmount_replicate (n : Nat) (m : EthMove) :
    totalAmount (List.replicate n m) = n * m.amount := by
  induction n with
  | zero => simp [totalAmount]
  | succ n ih =>
      rw [List.replicate_succ, totalAmount_cons, ih, Nat.succ_mul]
      omega

theorem composed_eth_conservation (msgValue fee : Nat) (hFee : fee ≤ msgValue) :
    fee + (msgValue - fee) = msgValue := by
  omega

theorem eth_flow_confined (moves : List EthMove) :
    (∀ m, m ∈ moves → is_approved m) →
      totalAmount moves = totalAmount (approvedReturnMoves moves) := by
  intro h
  have hFilter : approvedReturnMoves moves = moves := by
    apply List.filter_eq_self.mpr
    intro m hm
    simpa [is_approved] using h m hm
  rw [hFilter]

structure Config where
  consolidationRequest : Address
  deriving DecidableEq, Repr

structure ConsolidationFeeCall where
  feeAmount : Nat
  target : Address
  deriving DecidableEq, Repr

def ethTrace (cfg : Config) (c : ConsolidationFeeCall) : List EthMove :=
  [{ amount := c.feeAmount
     destination := if c.target = cfg.consolidationRequest then
       .consolidationContract
     else
       .other c.target }]

theorem consolidation_fee_path_confined (cfg : Config) (c : ConsolidationFeeCall) :
    c.target = cfg.consolidationRequest →
      ∀ (other : EthMove), other ∈ ethTrace cfg c →
        ∀ addr, other.destination ≠ EthDestination.other addr := by
  intro hTarget other hMem addr
  simp [ethTrace, hTarget] at hMem
  simp [hMem]

/-!
## Call-journal address classification

The strengthened parent derives ETH destinations from the *call journal*
(concrete addresses emitted by executing bodies) classified against an approved
set.  An address is approved iff it matches one of the protocol destinations.
Any journaled call to an address outside this set produces an
`EthDestination.other` move that the parent rejects. -/

structure ApprovedSet where
  consolidationContract : Address
  refundRecipient : Address
  deriving DecidableEq, Repr

def classifyJournal (approved : ApprovedSet) (addr : Address) : EthDestination :=
  if addr = approved.consolidationContract then .consolidationContract
  else if addr = approved.refundRecipient then .refundRecipient
  else .other addr

/-- A destination is parent-approved when it is one of the five protocol
destinations, i.e. anything other than a lateral `other` address. -/
def parentApproved : EthDestination → Prop
  | .other _ => False
  | _ => True

instance : DecidablePred parentApproved := fun d =>
  match d with
  | .other _ => isFalse (fun h => h)
  | .lido => isTrue trivial
  | .withdrawalQueue => isTrue trivial
  | .consolidationContract => isTrue trivial
  | .withdrawalRequestContract => isTrue trivial
  | .refundRecipient => isTrue trivial

/-!
## Gateway transaction result

**Scope exclusion:** VaultHub and `StakingVault.withdraw` are owner-controlled
interfaces that permit transfers to arbitrary recipients.  They are deliberately
not modeled by this parent theorem. -/

inductive GatewayRevert
  | zeroArgument
  | insufficientValue
  | overflowPanic
  deriving DecidableEq, Repr

inductive GatewayResult
  | reverted (reason : GatewayRevert)
  | success (moves : List EthMove)
  deriving DecidableEq, Repr

/-- Model one Gateway execution.  Revert conditions:
1. `msgValue = 0` → `ZeroArgument`
2. `n * fee ≥ 2^256` → `Panic(0x11)` overflow
3. `n * fee > msgValue` → `InsufficientValue` -/
def gatewayExecute (approved : ApprovedSet) (msgValue n fee : Nat) : GatewayResult :=
  if msgValue = 0 then .reverted .zeroArgument
  else if n * fee ≥ 2^256 then .reverted .overflowPanic
  else if n * fee > msgValue then .reverted .insufficientValue
  else
    let totalFee := n * fee
    let refund := msgValue - totalFee
    let feeMoves := List.replicate n
      { amount := fee, destination := classifyJournal approved approved.consolidationContract }
    let refundMoves := if refund = 0 then []
      else [{ amount := refund
              destination := classifyJournal approved approved.refundRecipient }]
    .success (feeMoves ++ refundMoves)

private theorem classifyJournal_self_consolidation (approved : ApprovedSet) :
    classifyJournal approved approved.consolidationContract = .consolidationContract := by
  simp [classifyJournal]

private theorem classifyJournal_self_refund (approved : ApprovedSet)
    (h : approved.refundRecipient ≠ approved.consolidationContract) :
    classifyJournal approved approved.refundRecipient = .refundRecipient := by
  simp [classifyJournal, h]

/-- **P-ETH-1 Wave 1 registered parent.**

For all `(msgValue, n, fee)` and any approved set where the refund recipient
differs from the consolidation contract:
- `msgValue = 0` reverts (`ZeroArgument` gateway guard).
- `n * fee ≥ 2^256` reverts (`Panic(0x11)` overflow).
- `n * fee > msgValue` reverts (`InsufficientValue`).
- Otherwise every classified move is `parentApproved` (no `.other`) and the
  total equals `msgValue`.

**Scope exclusion:** VaultHub and `StakingVault.withdraw` are owner-controlled
interfaces that permit transfers to arbitrary recipients.  They are deliberately
not modeled by this parent theorem. -/
theorem eth_flow_parent (approved : ApprovedSet)
    (hDistinct : approved.refundRecipient ≠ approved.consolidationContract) :
    ∀ (msgValue n fee : Nat),
      match gatewayExecute approved msgValue n fee with
      | .reverted .zeroArgument => msgValue = 0
      | .reverted .overflowPanic => n * fee ≥ 2^256
      | .reverted .insufficientValue => n * fee > msgValue
      | .success moves =>
          (∀ m, m ∈ moves → parentApproved m.destination) ∧
          totalAmount moves = msgValue := by
  intro msgValue n fee
  unfold gatewayExecute
  split_ifs with h1 h2 h3
  · exact h1
  · exact h2
  · exact h3
  · by_cases h4 : msgValue - n * fee = 0
    · have hRefund :
          (if msgValue - n * fee = 0 then ([] : List EthMove)
            else [{ amount := msgValue - n * fee,
                    destination := classifyJournal approved approved.refundRecipient }]) = [] :=
        if_pos h4
      refine ⟨?_, ?_⟩
      · intro m hm
        rw [hRefund, List.append_nil] at hm
        have := List.eq_of_mem_replicate hm
        subst this
        simp [classifyJournal_self_consolidation, parentApproved]
      · rw [hRefund, List.append_nil, totalAmount_replicate]
        show n * fee = msgValue
        omega
    · have hRefund :
          (if msgValue - n * fee = 0 then ([] : List EthMove)
            else [{ amount := msgValue - n * fee,
                    destination := classifyJournal approved approved.refundRecipient }]) =
            [{ amount := msgValue - n * fee,
               destination := classifyJournal approved approved.refundRecipient }] :=
        if_neg h4
      refine ⟨?_, ?_⟩
      · intro m hm
        rw [hRefund] at hm
        rcases List.mem_append.mp hm with hm | hm
        · have := List.eq_of_mem_replicate hm
          subst this
          simp [classifyJournal_self_consolidation, parentApproved]
        · simp only [List.mem_singleton] at hm
          subst hm
          simp [classifyJournal_self_refund approved hDistinct, parentApproved]
      · rw [hRefund, totalAmount_append, totalAmount_replicate, totalAmount_cons, totalAmount_nil]
        show n * fee + (msgValue - n * fee) = msgValue
        omega

/-! ## Verity plane

**Scope.** `verity_tx_composes_value_flow_and_rollback` is a finite
conjunction over five concrete `(msgValue, batchSize, feePerRequest)` tuples
— unlike `eth_flow_parent` above, it is not a `∀`-quantified theorem over
funded batches. `Tests.PEth1CompositionTxMutants.large_funded_batch_exhausts_fuel_budget`
exhibits a funded, guard-passing tuple outside this witness set whose
dispatch exhausts the model's fixed fuel budget instead of succeeding. -/

theorem verity_tx_composes_value_flow_and_rollback :
    (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 2 3) =
      ⟨.success, 6, ⟨0, 0, 0, 0, 0, 6, 4⟩⟩ ∧
      _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 1 3) =
      ⟨.success, 5, ⟨0, 0, 0, 0, 0, 3, 7⟩⟩ ∧
      _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 6 2 3) =
      ⟨.success, 5, ⟨0, 0, 0, 0, 0, 6, 0⟩⟩) ∧
    _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.observe
      (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
        { _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest with
          requestAccepts := false } 10 2 3) =
      ⟨.calleeReverted _root_.Verity.MultiContract.requestAddr, 4,
        ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ ∧
    _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.observe
      (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
        _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 4 3) =
      ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2,
        ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ ∧
    (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.escrowed
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 2 3) = 10 ∧
      _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.escrowed
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 6 2 3) = 6 ∧
      _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.escrowed
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          { _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest with
            requestAccepts := false } 10 2 3) = 10) ∧
    ((_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
        _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 2 3).program.length = 6 ∧
      _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.replay
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 2 3) =
        (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.observe
          (_root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.run
            _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.honest 10 2 3)).balances) :=
  _root_.LidoSRv3.Audit.Verity.PEth1CompositionTx.verity_tx_composes_value_flow_and_rollback

end LidoSRv3.Audit.Guarantees.PEth1
