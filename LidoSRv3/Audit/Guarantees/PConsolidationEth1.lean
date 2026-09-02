import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal
import LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversalRevert
import Mathlib.Tactic.SplitIfs

namespace LidoSRv3.Audit.Guarantees.PConsolidationEth1

abbrev Address := Nat

/-- Abstract destinations covering every ETH-bearing leg of the P-CONSOLIDATION-ETH-1
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

/-- Retired former P-CONSOLIDATION-ETH-1a filter: Lido / WithdrawalQueue only. Kept as an
unregistered auxiliary predicate. It is not part of the consolidation
fee/refund parent and is not a P-RESERVE-1 buffer fact. -/
def is_approved (m : EthMove) : Prop :=
  m.destination = .lido ∨ m.destination = .withdrawalQueue

def totalAmount (moves : List EthMove) : Nat :=
  moves.foldl (fun acc m => acc + m.amount) 0

def approvedReturnMoves (moves : List EthMove) : List EthMove :=
  moves.filter fun m => m.destination = .lido ∨ m.destination = .withdrawalQueue

def guarantee : Guarantee := ⟨.pConsolidationEth1, [.model, .source, .verityTx]⟩

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

/-- Unregistered auxiliary (retired P-CONSOLIDATION-ETH-1a). `List.filter_eq_self` under its
own Lido/WQ tagging hypothesis; not a registered parent conjunct. -/
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

/-- Named parent-conjunct helper (former P-CONSOLIDATION-ETH-1b): if the call
targets the configured consolidation-request address, the trace is tagged
`.consolidationContract`. Together with
`Verity.PConsolidationEth1RequestTx.consolidation_fee_target_success`, this is
registered parent evidence for the fee leg, not a sibling guarantee.
Canonical equality with the pinned EIP-7251 source literal remains the OPEN
`A-CANONICAL-REQUEST-ADDRESS` provenance boundary. -/
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

/-- Canonical EIP-7251 consolidation-request predeploy.  The model pins this
literal directly; identifying a deployed gateway immutable/slot with it remains
the explicit provenance boundary `A-CANONICAL-REQUEST-ADDRESS`. -/
def canonicalRequestAddress : Address :=
  0x0000BBdDc7CE488642fb579F8B00f3a590007251

def canonicalApprovedSet (refundRecipient : Address) : ApprovedSet :=
  { consolidationContract := canonicalRequestAddress, refundRecipient }

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

/-- **P-CONSOLIDATION-ETH-1 Wave 1 registered parent.**

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

/-- "One gateway execution is classified": `msgValue = 0` reverts
`ZeroArgument`, `n * fee ≥ 2^256` reverts overflow, `n * fee > msgValue`
reverts `InsufficientValue`, and otherwise every move is parent-approved (no
lateral `.other` destination) and the moved total equals `msgValue`. -/
abbrev GatewayOutcomeClassified (approved : ApprovedSet) (msgValue n fee : Nat) : Prop :=
  match gatewayExecute approved msgValue n fee with
  | .reverted .zeroArgument => msgValue = 0
  | .reverted .overflowPanic => n * fee ≥ 2^256
  | .reverted .insufficientValue => n * fee > msgValue
  | .success moves =>
      (∀ m, m ∈ moves → parentApproved m.destination) ∧
      totalAmount moves = msgValue

/-- **P-CONSOLIDATION-ETH-1, abstract plane.** At the canonical request
predeploy, for every `(msgValue, n, fee)`: zero value, wrapping fee and
underfunding revert, and otherwise every wei goes to the request contract or
the refund recipient with the total equal to `msgValue`.

**Registry-facing abstract parent at the canonical request predeploy.**
This folds the fee destination into the parent conclusion instead of leaving
the canonical target only in sibling evidence.  The literal is model content;
its equality with the deployed configured target remains
`A-CANONICAL-REQUEST-ADDRESS`. -/
theorem eth_flow_parent_at_canonical (refundRecipient : Address)
    (hDistinct : refundRecipient ≠ canonicalRequestAddress) :
    (canonicalApprovedSet refundRecipient).consolidationContract = canonicalRequestAddress ∧
      ∀ (msgValue n fee : Nat),
        GatewayOutcomeClassified (canonicalApprovedSet refundRecipient) msgValue n fee := by
  refine ⟨rfl, eth_flow_parent (canonicalApprovedSet refundRecipient) ?_⟩
  simpa [canonicalApprovedSet] using hDistinct

/-! ## Verity plane

**Registered parent.** `verity_tx_universal_success_shape` below is the
Verity-plane lift of the success arm of `eth_flow_parent` to matching
`∀`-quantifier strength: for every `(msgValue, batchSize, feePerRequest)`
that is nonzero-valued, word-sized, non-wrapping in the product fee, funded,
and within the dispatch fuel budget, the honest-wiring transaction commits
with the whole product fee at the consolidation-request predeploy, the
remainder at the caller's refund recipient, and zero retained by every
protocol contract on the route.  The premises are exactly the abstract
parent's non-revert conditions plus the model's fuel bound; each is shown
undroppable by a premise-necessity kill-line in
`Tests.PConsolidationEth1CompositionTxMutants`, which also refutes the same universal
predicate on four wiring mutants.

**Auxiliary evidence.** `verity_tx_composes_value_flow_and_rollback` keeps
the five numeral witnesses (now also consequences of the universal parent),
the rejecting-predeploy rollback, the underfunded revert, ETH conservation,
and the dispatch/multicall replay agreement as regression facts. -/

/-- **Registry-facing P-CONSOLIDATION-ETH-1 Verity-plane parent (universal).**

For every funded, guard-passing, non-wrapping batch that fits the dispatch
fuel budget, the honest wiring commits: the whole product fee lands at the
consolidation-request predeploy, the remainder lands at the refund recipient,
and no protocol contract on the route retains ETH.  Proved by frame-by-frame
chaining through the recursive dispatcher in
`Verity.PConsolidationEth1CompositionTxUniversal.run_success_shape`. -/
theorem verity_tx_universal_success_shape (msgValue batchSize feePerRequest : Nat)
    (hpos : 0 < msgValue)
    (hmv : msgValue < _root_.Verity.Core.Uint256.modulus)
    (hnM : batchSize < _root_.Verity.Core.Uint256.modulus)
    (hfee : feePerRequest < _root_.Verity.Core.Uint256.modulus)
    (hnf : batchSize * feePerRequest < _root_.Verity.Core.Uint256.modulus)
    (hle : batchSize * feePerRequest ≤ msgValue)
    (hfuel : batchSize + 4 ≤
      _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.fuelBudget) :
    _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest
          msgValue batchSize feePerRequest) =
      ⟨.success, batchSize + 3 + (if msgValue - batchSize * feePerRequest = 0 then 0 else 1),
        ⟨0, 0, 0, 0, 0, batchSize * feePerRequest, msgValue - batchSize * feePerRequest⟩⟩ :=
  _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversal.run_success_shape
    msgValue batchSize feePerRequest hpos hmv hnM hfee hnf hle hfuel

section VerityUniversalRevert

open _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx (observe run honest fuelBudget)
open _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTxUniversalRevert
  (run_zero_value_reverts run_overflow_reverts run_underfunded_reverts run_exhausts_fuel
    run_success_at_zero_remainder_boundary)

/-- The Verity-plane non-success partition at `∀`-quantifier strength: one
universally quantified rollback arm for each revert clause of the abstract
parent `eth_flow_parent`, plus the model's dispatch-fuel arm.

Every arm is read through `observe`, i.e. through `finalWorld`, so each arm
asserts transaction-entry rollback of the whole balance sheet, not merely a
control tag. The premises are the abstract parent's guard conditions stated
positively; none is dischargeable from the others. -/
def UniversalRevertPartition : Prop :=
  (∀ (batchSize feePerRequest : Nat),
      batchSize < _root_.Verity.Core.Uint256.modulus →
      observe (run honest 0 batchSize feePerRequest) =
        ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2,
          ⟨0, 0, 0, 0, 0, 0, 0⟩⟩) ∧
  (∀ (msgValue batchSize feePerRequest : Nat),
      0 < msgValue →
      msgValue < _root_.Verity.Core.Uint256.modulus →
      0 < batchSize →
      batchSize < _root_.Verity.Core.Uint256.modulus →
      feePerRequest < _root_.Verity.Core.Uint256.modulus →
      _root_.Verity.Core.Uint256.modulus ≤ batchSize * feePerRequest →
      observe (run honest msgValue batchSize feePerRequest) =
        ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2,
          ⟨msgValue, 0, 0, 0, 0, 0, 0⟩⟩) ∧
  (∀ (msgValue batchSize feePerRequest : Nat),
      0 < msgValue →
      msgValue < _root_.Verity.Core.Uint256.modulus →
      batchSize < _root_.Verity.Core.Uint256.modulus →
      feePerRequest < _root_.Verity.Core.Uint256.modulus →
      batchSize * feePerRequest < _root_.Verity.Core.Uint256.modulus →
      msgValue < batchSize * feePerRequest →
      observe (run honest msgValue batchSize feePerRequest) =
        ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2,
          ⟨msgValue, 0, 0, 0, 0, 0, 0⟩⟩) ∧
  (∀ (msgValue batchSize feePerRequest : Nat),
      0 < msgValue →
      msgValue < _root_.Verity.Core.Uint256.modulus →
      batchSize < _root_.Verity.Core.Uint256.modulus →
      feePerRequest < _root_.Verity.Core.Uint256.modulus →
      batchSize * feePerRequest < _root_.Verity.Core.Uint256.modulus →
      batchSize * feePerRequest ≤ msgValue →
      29 ≤ batchSize →
      (29 < batchSize ∨ 0 < msgValue - batchSize * feePerRequest) →
      observe (run honest msgValue batchSize feePerRequest) =
        ⟨.exhausted, fuelBudget, ⟨msgValue, 0, 0, 0, 0, 0, 0⟩⟩)

/-- **Registry-facing P-CONSOLIDATION-ETH-1 Verity-plane revert parent (universal).**

Discharges `UniversalRevertPartition` from the frame-by-frame executions in
`Verity.PConsolidationEth1CompositionTxUniversalRevert`.  This closes the former
quantifier gap between the abstract parent's `∀`-quantified revert clauses and
the Verity plane's four numeral rollback witnesses; those witnesses are now
instances of these arms and are retained as regression facts. -/
theorem verity_tx_universal_revert_partition : UniversalRevertPartition :=
  ⟨fun batchSize feePerRequest hnM => run_zero_value_reverts batchSize feePerRequest hnM,
   fun msgValue batchSize feePerRequest hpos hmv hn hnM hfee hover =>
     run_overflow_reverts msgValue batchSize feePerRequest hpos hmv hn hnM hfee hover,
   fun msgValue batchSize feePerRequest hpos hmv hnM hfee hnf hgt =>
     run_underfunded_reverts msgValue batchSize feePerRequest hpos hmv hnM hfee hnf hgt,
   fun msgValue batchSize feePerRequest hpos hmv hnM hfee hnf hle hbig hpend =>
     run_exhausts_fuel msgValue batchSize feePerRequest hpos hmv hnM hfee hnf hle hbig hpend⟩

/-- The exact success/exhaustion boundary corner that the registered success
parent's conservative `batchSize + 4 ≤ fuelBudget` premise excludes: a funded
batch with zero remainder still commits when it needs exactly `batchSize + 3`
frames.  Together with `verity_tx_universal_success_shape` and
`UniversalRevertPartition` this leaves no word-sized input unclassified between
the modeled success and non-success arms. -/
theorem verity_tx_universal_zero_remainder_boundary
    (msgValue batchSize feePerRequest : Nat)
    (hpos : 0 < msgValue)
    (hmv : msgValue < _root_.Verity.Core.Uint256.modulus)
    (hnM : batchSize < _root_.Verity.Core.Uint256.modulus)
    (hfee : feePerRequest < _root_.Verity.Core.Uint256.modulus)
    (hnf : batchSize * feePerRequest < _root_.Verity.Core.Uint256.modulus)
    (hle : batchSize * feePerRequest ≤ msgValue)
    (hz : msgValue - batchSize * feePerRequest = 0)
    (hfuel : batchSize + 3 ≤ fuelBudget) :
    observe (run honest msgValue batchSize feePerRequest) =
      ⟨.success, batchSize + 3,
        ⟨0, 0, 0, 0, 0, batchSize * feePerRequest,
          msgValue - batchSize * feePerRequest⟩⟩ :=
  run_success_at_zero_remainder_boundary msgValue batchSize feePerRequest
    hpos hmv hnM hfee hnf hle hz hfuel

end VerityUniversalRevert

section VerityRegisteredParent

open _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx
  (observe run honest fuelBudget honest_revert_partition)

/-! ## Vocabulary for the registered Verity statement

Each name is an `abbrev` unfolding to the exact clause it stands for, so the
registered conjunction below is the same proposition as before (same clauses,
same order, same nesting). -/

/-- "For every funded, word-sized, fuel-fit batch the honest wiring commits: the
whole product fee lands at the request predeploy, the remainder at the refund
recipient, and no protocol contract on the route retains ETH." -/
abbrev UniversalSuccessShape (msgValue batchSize feePerRequest : Nat) : Prop :=
  observe (run honest msgValue batchSize feePerRequest) =
    ⟨.success, batchSize + 3 + (if msgValue - batchSize * feePerRequest = 0 then 0 else 1),
      ⟨0, 0, 0, 0, 0, batchSize * feePerRequest, msgValue - batchSize * feePerRequest⟩⟩

/-- "Zero value rolls back" (concrete witness `msgValue = 0`, `n = 2`, `fee = 0`). -/
abbrev RevertsOnZeroValue : Prop :=
  observe (run honest 0 2 0) =
    ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2, ⟨0, 0, 0, 0, 0, 0, 0⟩⟩

/-- "A wrapping product fee rolls back" (concrete witness `n * fee = 2^256`). -/
abbrev RevertsOnWrappedFee : Prop :=
  observe (run honest 10 2 (2 ^ 255)) =
    ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2, ⟨10, 0, 0, 0, 0, 0, 0⟩⟩

/-- "Underfunding rolls back" (concrete witness `n * fee = 12 > 10 = msgValue`). -/
abbrev RevertsOnUnderfunding : Prop :=
  observe (run honest 10 4 3) =
    ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2, ⟨10, 0, 0, 0, 0, 0, 0⟩⟩

/-- "Dispatch-fuel exhaustion rolls back" (concrete witness of the model's
frame-count arm; not gas). -/
abbrev ExhaustsFuelAndRollsBack : Prop :=
  observe (run honest 30 29 1) = ⟨.exhausted, fuelBudget, ⟨30, 0, 0, 0, 0, 0, 0⟩⟩

/-- **P-CONSOLIDATION-ETH-1, Verity plane.** For every funded, word-sized,
fuel-fit batch the Bus/Gateway/Vault ensemble commits the whole product fee at
the request predeploy and the remainder at the refund recipient; it rolls back
at the four modeled non-success boundaries (zero value, wrapped product,
underfunding, fuel exhaustion), both on the four concrete witnesses and at full
`∀`-quantifier strength (`UniversalRevertPartition`).

Registry-facing Verity close: the universal funded success shape conjoined
with executable rollback shapes at all four modeled non-success boundaries
(zero value, wrapped product, underfunding, and dispatch-fuel exhaustion), both
as the four exact numeral witnesses and — since Wave 6 — at full
`∀`-quantifier strength via `UniversalRevertPartition`. -/
theorem verity_tx_success_and_revert_partition (msgValue batchSize feePerRequest : Nat)
    (hpos : 0 < msgValue)
    (hmv : msgValue < _root_.Verity.Core.Uint256.modulus)
    (hnM : batchSize < _root_.Verity.Core.Uint256.modulus)
    (hfee : feePerRequest < _root_.Verity.Core.Uint256.modulus)
    (hnf : batchSize * feePerRequest < _root_.Verity.Core.Uint256.modulus)
    (hle : batchSize * feePerRequest ≤ msgValue)
    (hfuel : batchSize + 4 ≤ fuelBudget) :
    UniversalSuccessShape msgValue batchSize feePerRequest ∧
      RevertsOnZeroValue ∧
      RevertsOnWrappedFee ∧
      RevertsOnUnderfunding ∧
      ExhaustsFuelAndRollsBack ∧
      UniversalRevertPartition := by
  refine ⟨verity_tx_universal_success_shape msgValue batchSize feePerRequest
    hpos hmv hnM hfee hnf hle hfuel, ?_⟩
  obtain ⟨h1, h2, h3, h4⟩ := honest_revert_partition
  exact ⟨h1, h2, h3, h4, verity_tx_universal_revert_partition⟩

end VerityRegisteredParent

theorem verity_tx_composes_value_flow_and_rollback :
    (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 2 3) =
      ⟨.success, 6, ⟨0, 0, 0, 0, 0, 6, 4⟩⟩ ∧
      _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 1 3) =
      ⟨.success, 5, ⟨0, 0, 0, 0, 0, 3, 7⟩⟩ ∧
      _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 6 2 3) =
      ⟨.success, 5, ⟨0, 0, 0, 0, 0, 6, 0⟩⟩) ∧
    _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
      (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
        { _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest with
          requestAccepts := false } 10 2 3) =
      ⟨.calleeReverted _root_.Verity.MultiContract.requestAddr, 4,
        ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ ∧
    _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
      (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
        _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 4 3) =
      ⟨.calleeReverted _root_.Verity.MultiContract.gatewayAddr, 2,
        ⟨10, 0, 0, 0, 0, 0, 0⟩⟩ ∧
    (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.escrowed
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 2 3) = 10 ∧
      _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.escrowed
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 6 2 3) = 6 ∧
      _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.escrowed
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          { _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest with
            requestAccepts := false } 10 2 3) = 10) ∧
    ((_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
        _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 2 3).program.length = 6 ∧
      _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.replay
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
          _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 2 3) =
        (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.observe
          (_root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.run
            _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.honest 10 2 3)).balances) :=
  _root_.LidoSRv3.Audit.Verity.PConsolidationEth1CompositionTx.verity_tx_composes_value_flow_and_rollback

end LidoSRv3.Audit.Guarantees.PConsolidationEth1
