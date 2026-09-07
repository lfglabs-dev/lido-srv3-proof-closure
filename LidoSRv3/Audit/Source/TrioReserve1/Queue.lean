import LidoSRv3.Audit.Source.TrioReserve1.Live
import LidoSRv3.Audit.Source.TrioReserve1.QueueSpec
import Lean.Elab.Tactic.Omega

/-!
Pinned WithdrawalQueueBase.sol:116-125,143-146,548-553 and
WithdrawalQueue.sol:346-354. The live demand uses current physical request ids
and the first packed word of each mapping row; no cache or freshness flag.
`keccak` is an explicit primitive parameter, not an injectivity axiom. The
state relation uses the same physical Solidity mapping-slot derivation.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.Queue
open Live

abbrev Keccak := Bytes → Word

def queueSlot : Nat := 0xe21b95c4eb1b99fd548b219e3b5c175a8efb31f910cb76456b20e14eba8cfe43
def lastSlot : Nat := 0x8ee26abbbdf533de3953ccf2204279e845eecb5ab51f8398522746e4ea068041
def finalizedSlot : Nat := 0x992f2e0c24ce59a21f2dab8bba13b25c2f872129df7f4d45372155e717db0c48
def bunkerSlot : Nat := 0x1450eb8d0693284079f6627b2c1c6bb2e076066e44df1b18ba6ea7cc507e9bcb

def requestSlot (keccak : Keccak) (id : Nat) : Nat :=
  (keccak (encode 32 id ++ encode 32 queueSlot)).val

def getLastRequestId (queue : Address) (w : World) : Word :=
  w.core.readContractSlot queue.val lastSlot

def getLastFinalizedRequestId (queue : Address) (w : World) : Word :=
  w.core.readContractSlot queue.val finalizedSlot

def cumulative (keccak : Keccak) (queue : Address) (w : World) (id : Nat) : Nat :=
  (w.core.readContractSlot queue.val (requestSlot keccak id)).val % width

/-- The only exceptional branch is the 0.8.9 uint128 subtraction underflow.
No index validity guard is added: arbitrary physical storage is admitted. -/
def unfinalizedStETH (keccak : Keccak) (queue : Address) (w : World) : Except Nat Nat :=
  let last := getLastRequestId queue w
  let finalized := getLastFinalizedRequestId queue w
  let hi := cumulative keccak queue w last.val
  let lo := cumulative keccak queue w finalized.val
  if lo ≤ hi then .ok (hi - lo) else .error 0x11

/-- Read actual bunker timestamp, where uint256 max means disabled. -/
def isBunkerModeActive (queue : Address) (w : World) : Bool :=
  (w.core.readContractSlot queue.val bunkerSlot).val < Verity.Core.MAX_UINT256

def panicBytes (code : Nat) : Bytes := encode 4 0x4e487b71 ++ encode 32 code

/-- The queue implementations own just these two selectors in this partial
interpreter. All other code is delegated, not replaced by successful stubs.
Nonpayable dispatcher checks apply even though Lido itself always sends zero. -/
def dispatch (keccak : Keccak) (queue : Address) (other : External) : External := fun req w =>
  if req.target = queue ∧ req.payload = encode 4 0xd0fb84e8 then
    if req.value.val ≠ 0 then .rejected []
    else match unfinalizedStETH keccak queue w with
      | .error code => .rejected (panicBytes code)
      | .ok amount => .success (encode 32 amount) w
  else if req.target = queue ∧ req.payload = encode 4 0x2b95b781 then
    if req.value.val ≠ 0 then .rejected []
    else .success (encode 32 (if isBunkerModeActive queue w then 1 else 0)) w
  else other req w

/-- Explicit physical-storage/input relation to the independently stated spec.
All row values are tied to their low-128-bit physical mapping word, including
malformed/reversed queue states. No monotonicity or freshness premise. -/
def StateRel (keccak : Keccak) (queue : Address) (w : World) (s : QueueSpec.State) : Prop :=
  s.last = (getLastRequestId queue w).val ∧
  s.finalized = (getLastFinalizedRequestId queue w).val ∧
  ∀ id, s.cumulative id = cumulative keccak queue w id

def observe : Except Nat Nat → QueueSpec.Outcome
  | .ok amount => .value amount
  | .error code => .panic code

/-- Both successful demand and underflow match the independent relation for
all physically related states. Callee bytes/dispatcher binding are separate. -/
theorem unfinalized_corresponds (keccak : Keccak) (queue : Address) (w : World)
    (s : QueueSpec.State) (h : StateRel keccak queue w s) :
    QueueSpec.Describes s (observe (unfinalizedStETH keccak queue w)) := by
  rcases h with ⟨hlast, hfinal, hrows⟩
  unfold unfinalizedStETH
  dsimp only
  split
  · simp only [observe, QueueSpec.Describes, hlast, hfinal, hrows]
    constructor
    · assumption
    · omega
  · simp only [observe, QueueSpec.Describes, hlast, hfinal, hrows]
    constructor
    · omega
    · trivial

/-- Physical extraction derives a bound even on unreachable/malformed rows. -/
theorem cumulative_bound (keccak : Keccak) (queue : Address) (w : World) (id : Nat) :
    cumulative keccak queue w id < width := by
  exact Nat.mod_lt _ (by decide)

end LidoSRv3.Audit.Source.TrioReserve1.Queue
