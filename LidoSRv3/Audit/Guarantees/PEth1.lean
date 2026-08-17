import LidoSRv3.Audit.Guarantees.Registry
import LidoSRv3.Audit.Verity.PEth1CompositionTx

namespace LidoSRv3.Audit.Guarantees.PEth1

abbrev Address := Nat

/-- Abstract destinations relevant to the two P-ETH-1 sub-properties. -/
inductive EthDestination
  | lido
  | withdrawalQueue
  | consolidationContract
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

/-- The canonical parent remains open; the theorems below are subordinate
evidence for its two bounded child rows, not additional public guarantees. -/
def guarantee : Guarantee := ⟨.pEth1, [.model, .source, .verityTx]⟩

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
## ETH-bearing call-site inventory

This file proves only the two bounded abstract child properties above. The
parent P-ETH-1 remains open and includes every ETH-bearing path identified by
the source review:

* `ConsolidationBus.executeConsolidation` forwards `msg.value` to
  `ConsolidationGateway`.
* `ConsolidationGateway` sends `requestsCount × fee` to `WithdrawalVault` and
  refunds the remainder to an arbitrary `refundRecipient` (falling back to
  `msg.sender`).
* `WithdrawalVault.withdrawWithdrawals` sends ETH to Lido.
* `WithdrawalVault` sends EIP-7002 fees to the immutable
  `WITHDRAWAL_REQUEST` request contract.
* `WithdrawalVault` sends EIP-7251 fees to the immutable
  `CONSOLIDATION_REQUEST` request contract.
-/

end LidoSRv3.Audit.Guarantees.PEth1
