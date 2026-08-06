import LidoSRv3.Audit.Guarantees.Registry

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

/-- P-ETH-1a approves only the two stVault return destinations. -/
def is_approved (m : EthMove) : Prop :=
  m.destination = .lido ∨ m.destination = .withdrawalQueue

def totalAmount (moves : List EthMove) : Nat :=
  moves.foldl (fun acc m => acc + m.amount) 0

def approvedReturnMoves (moves : List EthMove) : List EthMove :=
  moves.filter fun m => m.destination = .lido ∨ m.destination = .withdrawalQueue

def guaranteeA : Guarantee := ⟨.pEth1a, [.model]⟩

def guaranteeB : Guarantee := ⟨.pEth1b, [.model]⟩

/-- Every committed stVault return move is retained by the approved-path
filter, so its total is exactly the total sent to Lido or WithdrawalQueue. -/
theorem eth_flow_confined (moves : List EthMove) :
    (∀ m, m ∈ moves → is_approved m) →
      totalAmount moves = totalAmount (approvedReturnMoves moves) := by
  intro h
  have hFilter : approvedReturnMoves moves = moves := by
    apply List.filter_eq_self.mpr
    intro m hm
    simpa [is_approved] using h m hm
  rw [hFilter]

/-- The EIP-7251 consolidation request contract, `0x00...007251`. -/
def CONSOLIDATION_CONTRACT_ADDR : Address := 0x7251

structure ConsolidationFeeCall where
  feeAmount : Nat
  target : Address
  deriving DecidableEq, Repr

/-- The committed ETH trace of the modeled fee interface consists of its one
fee-bearing call. The target classification is kept separate from the concrete
address so lateral calls cannot be conflated with the consolidation contract. -/
def ethTrace (c : ConsolidationFeeCall) : List EthMove :=
  [{ amount := c.feeAmount
     destination := if c.target = CONSOLIDATION_CONTRACT_ADDR then
       .consolidationContract
     else
       .other c.target }]

/-- If the modeled fee call targets EIP-7251, its sole committed ETH move is
classified as the consolidation-contract move and not as any lateral move. -/
theorem consolidation_fee_path_confined (c : ConsolidationFeeCall) :
    c.target = CONSOLIDATION_CONTRACT_ADDR →
      ∀ (other : EthMove), other ∈ ethTrace c →
        ∀ addr, other.destination ≠ EthDestination.other addr := by
  intro hTarget other hMem addr
  simp [ethTrace, hTarget] at hMem
  simp [hMem]

end LidoSRv3.Audit.Guarantees.PEth1
