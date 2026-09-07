import LidoSRv3.Audit.Source.TrioReserve1.Live

/-! Pinned LidoLocator.sol constructor/getters. These addresses are immutable
deployment inputs, not replies assumed to succeed or mutable storage slots.
The source constructor requires these three bindings to be nonzero. Matching
that constructor/runtime configuration is an explicit deployment obligation.
-/
namespace LidoSRv3.Audit.Source.TrioReserve1.Locator
open Live

structure Config where
  queue : Address
  router : Address
  oracle : Address

def valid (c : Config) : Prop := c.queue.val ≠ 0 ∧ c.router.val ≠ 0 ∧ c.oracle.val ≠ 0

/-- Generated nonpayable no-argument getters. The exact four-byte calls issued
by Lido are covered; other selectors are delegated to the rest of the source. -/
def dispatch (locator : Address) (c : Config) (other : External) : External := fun req w =>
  let selected := if req.payload = encode 4 0x37d5fe99 then some c.queue
    else if req.payload = encode 4 0xef6c064c then some c.router
    else if req.payload = encode 4 0x5a2031f9 then some c.oracle
    else none
  if req.target = locator then
    match selected with
    | none => other req w
    | some value => if req.value.val = 0 then .success (encode 32 value.val) w else .rejected []
  else other req w

theorem queue_getter (locator : Address) (c : Config) (other : External)
    (caller : Address) (w : World) :
    dispatch locator c other ⟨caller, locator, word 0, encode 4 0x37d5fe99⟩ w =
      .success (encode 32 c.queue.val) w := by
  simp [dispatch, word, Verity.Core.Uint256.ofNat]

theorem router_getter (locator : Address) (c : Config) (other : External)
    (caller : Address) (w : World) :
    dispatch locator c other ⟨caller, locator, word 0, encode 4 0xef6c064c⟩ w =
      .success (encode 32 c.router.val) w := by
  have h : encode 4 0xef6c064c ≠ encode 4 0x37d5fe99 := by decide
  simp [dispatch, word, Verity.Core.Uint256.ofNat, h]

theorem oracle_getter (locator : Address) (c : Config) (other : External)
    (caller : Address) (w : World) :
    dispatch locator c other ⟨caller, locator, word 0, encode 4 0x5a2031f9⟩ w =
      .success (encode 32 c.oracle.val) w := by
  have hq : encode 4 0x5a2031f9 ≠ encode 4 0x37d5fe99 := by decide
  have hr : encode 4 0x5a2031f9 ≠ encode 4 0xef6c064c := by decide
  simp [dispatch, word, Verity.Core.Uint256.ofNat, hq, hr]

end LidoSRv3.Audit.Source.TrioReserve1.Locator
