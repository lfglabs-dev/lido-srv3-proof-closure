import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Verity.PEth1CompositionTx

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

/-- Parent abstract conservation law for the Gateway split: every wei
forwarded by the Bus is assigned exactly once to either the Vault fee or the
resolved refund recipient. -/
theorem composed_eth_conservation (msgValue fee : Nat) (hFee : fee ≤ msgValue) :
    fee + (msgValue - fee) = msgValue := by
  omega

/-- Every committed move made through the protocol-controlled stVault
rebalance/redemption interface is retained by the approved-path filter, so its
total is exactly the total sent to Lido or WithdrawalQueue.

Scope assumption: `StakingVault.withdraw` is deliberately excluded. That raw
owner-controlled interface permits transfers to any nonzero recipient and is
not a protocol rebalance/redemption return path. -/
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
  /-- Source-level target supplied by the immutable `CONSOLIDATION_REQUEST`. -/
  consolidationRequest : Address
  deriving DecidableEq, Repr

structure ConsolidationFeeCall where
  feeAmount : Nat
  target : Address
  deriving DecidableEq, Repr

/-- The committed ETH trace of the modeled fee interface consists of its one
fee-bearing call. The target classification is kept separate from the concrete
address so lateral calls cannot be conflated with the consolidation contract. -/
def ethTrace (cfg : Config) (c : ConsolidationFeeCall) : List EthMove :=
  [{ amount := c.feeAmount
     destination := if c.target = cfg.consolidationRequest then
       .consolidationContract
     else
       .other c.target }]

/-- If the modeled fee call targets the configured immutable consolidation
request address, its sole committed ETH move is classified as the
consolidation-contract move and not as any lateral move.

Deployment-provenance assumption: source establishes use of the nonzero
immutable `CONSOLIDATION_REQUEST`; identifying its deployed value with the
canonical EIP-7251 address `0x00...007251` is a separate deployment fact and is
not proved by this theorem. -/
theorem consolidation_fee_path_confined (cfg : Config) (c : ConsolidationFeeCall) :
    c.target = cfg.consolidationRequest →
      ∀ (other : EthMove), other ∈ ethTrace cfg c →
        ∀ addr, other.destination ≠ EthDestination.other addr := by
  intro hTarget other hMem addr
  simp [ethTrace, hTarget] at hMem
  simp [hMem]

/-!
## Parent: every ETH-bearing path

The three constructors of `EthPath` are the complete ETH-bearing call-site
inventory recovered by the source review:

* `consolidation` — `ConsolidationBus.executeConsolidation` forwards `msg.value`
  to `ConsolidationGateway`, which pays `requestsCount × feePerRequest` onward
  through `WithdrawalVault` to the immutable EIP-7251 `CONSOLIDATION_REQUEST`
  contract and refunds the remainder to the resolved `refundRecipient`
  (`msg.sender` when unset).
* `withdrawalRequests` — `WithdrawalVault` pays EIP-7002 fees to the immutable
  `WITHDRAWAL_REQUEST` contract, one per request.
* `withdrawalsToLido` — `WithdrawalVault.withdrawWithdrawals` sends ETH to Lido.

The parent states, over every path, that no wei reaches a lateral destination
and that the trace totals exactly the value the path was entered with. -/

structure ConsolidationTx where
  msgValue : Nat
  requestsCount : Nat
  feePerRequest : Nat
  deriving DecidableEq, Repr

def consolidationFee (t : ConsolidationTx) : Nat :=
  t.requestsCount * t.feePerRequest

def consolidationRefund (t : ConsolidationTx) : Nat :=
  t.msgValue - consolidationFee t

/-- The Gateway skips the refund leg entirely when the remainder is zero. -/
def refundMoves (t : ConsolidationTx) : List EthMove :=
  if consolidationRefund t = 0 then []
  else [{ amount := consolidationRefund t, destination := .refundRecipient }]

inductive EthPath
  | consolidation (t : ConsolidationTx)
  | withdrawalRequests (count feePerRequest : Nat)
  | withdrawalsToLido (amount : Nat)
  deriving Repr

def pathTrace : EthPath → List EthMove
  | .consolidation t =>
      List.replicate t.requestsCount
          { amount := t.feePerRequest, destination := .consolidationContract }
        ++ refundMoves t
  | .withdrawalRequests count feePerRequest =>
      List.replicate count
        { amount := feePerRequest, destination := .withdrawalRequestContract }
  | .withdrawalsToLido amount =>
      [{ amount := amount, destination := .lido }]

/-- The value the path is entered with: `msg.value` for the consolidation
transaction, the aggregate fee for the request legs, the withdrawn amount for
the Lido leg. -/
def pathValue : EthPath → Nat
  | .consolidation t => t.msgValue
  | .withdrawalRequests count feePerRequest => count * feePerRequest
  | .withdrawalsToLido amount => amount

/-- The Gateway's `InsufficientValue` guard; the other legs are unconditioned. -/
def pathFunded : EthPath → Prop
  | .consolidation t => consolidationFee t ≤ t.msgValue
  | .withdrawalRequests _ _ => True
  | .withdrawalsToLido _ => True

/-- A destination is parent-approved when it is one of the five protocol
destinations, i.e. anything other than a lateral `other` address. -/
def parentApproved : EthDestination → Prop
  | .other _ => False
  | _ => True

theorem totalAmount_refundMoves (t : ConsolidationTx) :
    totalAmount (refundMoves t) = consolidationRefund t := by
  unfold refundMoves
  split
  · next h => simp [totalAmount, h]
  · simp [totalAmount_cons, totalAmount_nil]

theorem refundMoves_approved (t : ConsolidationTx) :
    ∀ m ∈ refundMoves t, parentApproved m.destination := by
  unfold refundMoves
  split
  · intro m hm; simp at hm
  · intro m hm
    simp only [List.mem_singleton] at hm
    subst hm
    trivial

/-- **Parent P-ETH-1.** On every ETH-bearing path of the inventory, provided the
Gateway fee guard holds, no wei escapes to a lateral destination and the
committed trace sums to exactly the value entering the path. -/
theorem eth_flow_parent (p : EthPath) (h : pathFunded p) :
    (∀ m ∈ pathTrace p, parentApproved m.destination) ∧
      totalAmount (pathTrace p) = pathValue p := by
  cases p with
  | consolidation t =>
      have hFee : consolidationFee t ≤ t.msgValue := h
      refine ⟨?_, ?_⟩
      · intro m hm
        rcases List.mem_append.mp hm with hm | hm
        · rw [List.eq_of_mem_replicate hm]; trivial
        · exact refundMoves_approved t m hm
      · show totalAmount (List.replicate _ _ ++ refundMoves t) = t.msgValue
        rw [totalAmount_append, totalAmount_replicate, totalAmount_refundMoves]
        show consolidationFee t + consolidationRefund t = t.msgValue
        unfold consolidationRefund
        omega
  | withdrawalRequests count feePerRequest =>
      refine ⟨?_, ?_⟩
      · intro m hm
        rw [List.eq_of_mem_replicate hm]; trivial
      · exact totalAmount_replicate count _
  | withdrawalsToLido amount =>
      refine ⟨?_, ?_⟩
      · intro m hm
        simp only [pathTrace, List.mem_singleton] at hm
        subst hm
        trivial
      · simp [pathTrace, pathValue, totalAmount_cons, totalAmount_nil]

/-! ## Verity plane

The composed transaction is stated in `LidoSRv3.Audit.Verity.PEth1CompositionTx`
and re-exported here so the assurance contract can name a stable path. -/

/-- **Verity plane P-ETH-1.** Recursive dispatch of the compiled
`Bus → Gateway → Vault → (CONSOLIDATION_REQUEST | refund)` ensemble through
external-call frames over one shared `MultiWorld`: the fee/refund split lands
on the outcome observables, a rejecting request contract restores the entry
world, the underfunded batch reverts inside the Gateway, ETH is conserved
across every run, and the discovered call program replays identically as one
atomic compiled multicall. -/
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
