import LidoSRv3.Audit.Source.TrioReserve1.StaticCall
import LidoSRv3.Audit.Source.TrioReserve1.FrameSpec

namespace LidoSRv3.Audit.Source.TrioReserve1.Consensus
open Live

structure Config where
  genesis : Nat
  secondsPerSlot : Nat
  slotsPerEpoch : Nat
  frameSlot : Nat

def panic (code : Nat) : Bytes := encode 4 0x4e487b71 ++ encode 32 code
def initialEpochNotArrived : Bytes := encode 4 0xcd0883ea
def add (a b : Nat) : Except Bytes Nat :=
  if a + b < 2^256 then .ok (a + b) else .error (panic 0x11)
def mul (a b : Nat) : Except Bytes Nat :=
  if a * b < 2^256 then .ok (a * b) else .error (panic 0x11)
def mul64 (a b : Nat) : Except Bytes Nat :=
  if a * b < 2^64 then .ok (a * b) else .error (panic 0x11)
def sub (a b : Nat) : Except Bytes Nat :=
  if b ≤ a then .ok (a - b) else .error (panic 0x11)
def divide (a b : Nat) : Except Bytes Nat :=
  if b = 0 then .error (panic 0x12) else .ok (a / b)

/-- HashConsensus.sol:644-719. Includes checked arithmetic, initial epoch
rejection, malformed physical zero frame length, and explicit uint64 narrowing.
Immutable chain fields must be bound to the actual constructor uint64 values.
The frame slot is the compiler-reported inherited storage layout, not a cache.
-/
def compute (c : Config) (time packed : Nat) : Except Bytes (Nat × Nat) := do
  let initial := packed % 2^64
  let epochs := packed / 2^64 % 2^64
  let elapsed ← sub time c.genesis
  let slot ← divide elapsed c.secondsPerSlot
  let epoch ← divide slot c.slotsPerEpoch
  if epoch < initial then throw initialEpochNotArrived
  let difference ← sub epoch initial
  let index ← divide difference epochs
  let offset ← mul index epochs
  let startEpoch ← add initial offset
  let startSlot ← mul startEpoch c.slotsPerEpoch
  -- Both operands of this subexpression are uint64 in the actual source.
  let frameSlots ← mul64 epochs c.slotsPerEpoch
  let nextSlot ← add startSlot frameSlots
  let reference ← sub startSlot 1
  let deadline ← sub nextSlot 1
  pure (reference % 2^64, deadline % 2^64)

def dispatch (consensus : Address) (c : Config) (other : StaticCall.External) :
    StaticCall.External := fun req w =>
  if req.target = consensus ∧ req.payload = encode 4 0x72f79b13 then
    match compute c w.core.blockTimestamp.val
        (w.core.readContractSlot consensus.val c.frameSlot).val with
    | .error data => .rejected data
    | .ok (reference, deadline) => .success (encode 32 reference ++ encode 32 deadline)
  else other req w

private theorem bind_success (first : Except Bytes α) (next : α → Except Bytes β)
    (result : β) (h : first.bind next = .ok result) :
    ∃ value, first = .ok value ∧ next value = .ok result := by
  cases he : first with
  | error e => simp [he, Except.bind] at h
  | ok value => exact ⟨value, rfl, by simpa [he, Except.bind] using h⟩

private theorem sub_success (a b result : Nat) (h : sub a b = .ok result) :
    result = a - b ∧ b ≤ a := by
  unfold sub at h
  split at h
  · simp only [Except.ok.injEq] at h
    exact ⟨h.symm, by assumption⟩
  · contradiction

private theorem divide_success (a b result : Nat) (h : divide a b = .ok result) :
    result = a / b ∧ b ≠ 0 := by
  unfold divide at h
  split at h
  · contradiction
  · simp only [Except.ok.injEq] at h
    exact ⟨h.symm, by assumption⟩

private theorem mul_success (a b result : Nat) (h : mul a b = .ok result) :
    result = a * b ∧ a * b < 2^256 := by
  unfold mul at h
  split at h
  · simp only [Except.ok.injEq] at h
    exact ⟨h.symm, by assumption⟩
  · contradiction

private theorem add_success (a b result : Nat) (h : add a b = .ok result) :
    result = a + b ∧ a + b < 2^256 := by
  unfold add at h
  split at h
  · simp only [Except.ok.injEq] at h
    exact ⟨h.symm, by assumption⟩
  · contradiction

private theorem mul64_success (a b result : Nat) (h : mul64 a b = .ok result) :
    result = a * b ∧ a * b < 2^64 := by
  unfold mul64 at h
  split at h
  · simp only [Except.ok.injEq] at h
    exact ⟨h.symm, by assumption⟩
  · contradiction

/-- Actual successful checked execution selects the independently specified
Euclidean frame and the two uint64 projections. No successful-callee premise. -/
theorem compute_success (c : Config) (time packed reference deadline : Nat)
    (h : compute c time packed = .ok (reference, deadline)) :
    FrameSpec.Describes time c.genesis c.secondsPerSlot c.slotsPerEpoch
      (packed % 2^64) (packed / 2^64 % 2^64) reference deadline := by
  unfold compute at h
  dsimp only at h
  obtain ⟨elapsed, he, h⟩ := bind_success _ _ _ h
  obtain ⟨slot, hs, h⟩ := bind_success _ _ _ h
  obtain ⟨epoch, hep, h⟩ := bind_success _ _ _ h
  by_cases hinit : epoch < packed % 2^64
  · simp only [hinit, ↓reduceIte] at h
    change (Except.error initialEpochNotArrived : Except Bytes (Nat × Nat)) =
      .ok (reference, deadline) at h
    contradiction
  · simp only [hinit, ↓reduceIte, bind, Except.bind, pure, Except.pure] at h
    obtain ⟨difference, hd, h⟩ := bind_success _ _ _ h
    obtain ⟨index, hi, h⟩ := bind_success _ _ _ h
    obtain ⟨offset, ho, h⟩ := bind_success _ _ _ h
    obtain ⟨startEpoch, hse, h⟩ := bind_success _ _ _ h
    obtain ⟨startSlot, hss, h⟩ := bind_success _ _ _ h
    obtain ⟨frameSlots, hfs, h⟩ := bind_success _ _ _ h
    obtain ⟨nextSlot, hns, h⟩ := bind_success _ _ _ h
    obtain ⟨ref, hr, h⟩ := bind_success _ _ _ h
    obtain ⟨last, hl, h⟩ := bind_success _ _ _ h
    obtain ⟨rfl, htime⟩ := sub_success _ _ _ he
    obtain ⟨rfl, hseconds⟩ := divide_success _ _ _ hs
    obtain ⟨rfl, hslots⟩ := divide_success _ _ _ hep
    obtain ⟨rfl, _⟩ := sub_success _ _ _ hd
    obtain ⟨rfl, hepochs⟩ := divide_success _ _ _ hi
    obtain ⟨rfl, _⟩ := mul_success _ _ _ ho
    obtain ⟨rfl, _⟩ := add_success _ _ _ hse
    obtain ⟨rfl, _⟩ := mul_success _ _ _ hss
    obtain ⟨rfl, hspan⟩ := mul64_success _ _ _ hfs
    obtain ⟨rfl, hnext⟩ := add_success _ _ _ hns
    obtain ⟨rfl, hstart⟩ := sub_success _ _ _ hr
    obtain ⟨rfl, _⟩ := sub_success _ _ _ hl
    simp only [Except.ok.injEq, Prod.mk.injEq] at h
    refine ⟨_, _, _, htime,
      FrameSpec.quotient_of_div _ _ hseconds, FrameSpec.quotient_of_div _ _ hslots,
      by omega, FrameSpec.quotient_of_div _ _ hepochs, hspan, ?_⟩
    exact ⟨by omega, hnext, h.1.symm, h.2.symm⟩

end LidoSRv3.Audit.Source.TrioReserve1.Consensus
