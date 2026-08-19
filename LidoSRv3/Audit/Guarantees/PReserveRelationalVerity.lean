import LidoSRv3.Audit.Guarantees.PReserveRelational
import LidoSRv3.Audit.Verity.ReserveRelationalTx

namespace LidoSRv3.Audit.Guarantees.PReserveRelational

/-- Headline composed closure theorem for P-RESERVE-RELATIONAL.  The executable
transaction decodes the requested batch ends from a denoted `uint256[]` memory
array and the queue economics from `mapUint` storage channels, journals each
prefinalized batch endpoint, persists the new locked ETH and last finalized
request id through `writeSlot`, and its committed/reverted observables are
exactly those of the independently stated pinned-source interpreter.

The executable plane implements the Solidity 0.8 checked `lockedEtherAmount +=
prefinalized`, which the unbounded `Nat` planes cannot express, so the
correspondence is stated where that accumulator stays inside one word.  The
complementary case is `verity_tx_reverts_on_locked_overflow`: the transaction
reverts there rather than committing a wrapped word. -/
theorem verity_tx_simulates_reserve_relational_spec
    (inputs : LidoSRv3.Audit.ReserveRelational.Inputs)
    (before : LidoSRv3.Audit.ReserveRelational.State)
    (state : Verity.ContractState)
    (h : LidoSRv3.Audit.Verity.ReserveRelationalTx.Decodes state inputs before)
    (hNoWrap : LidoSRv3.Audit.Verity.ReserveRelationalTx.NoLockedOverflow inputs before) :
    LidoSRv3.Audit.Verity.ReserveRelationalTx.observe
        ((LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize
          inputs.report.batchEnds.length inputs.report.useDiscount).run state) =
      LidoSRv3.Audit.Verity.ReserveRelationalTx.sourceView inputs before :=
  LidoSRv3.Audit.Verity.ReserveRelationalTx.verity_tx_simulates_pinned_source
    inputs before state h hNoWrap

/-- Checked-arithmetic closure: where the unbounded planes would commit a
locked-ETH accumulator wider than one word, the transaction reverts on the
exact pre-call snapshot.  No wrapped word is ever written. -/
theorem verity_tx_reverts_on_locked_overflow
    (count : Nat) (discount inject : Bool) (state : Verity.ContractState)
    (decoded : LidoSRv3.Audit.Verity.ReserveRelationalTx.Decoded)
    (ranges : List (Nat × Nat)) (eth shares : Nat) (range : Nat × Nat) (locked : Nat)
    (hCount : (count == 0) = false)
    (hDecode : LidoSRv3.Audit.Verity.ReserveRelationalTx.decode state count = some decoded)
    (hRun : LidoSRv3.Audit.Verity.ReserveRelationalTx.txRun decoded discount =
      some (ranges, eth, shares, range, locked))
    (hWrap : Verity.Core.MAX_UINT256 < locked) :
    (LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize count discount inject).run state =
      .revert "LOCKED_ETH_OVERFLOW" state :=
  LidoSRv3.Audit.Verity.ReserveRelationalTx.verity_tx_reverts_on_locked_overflow
    count discount inject state decoded ranges eth shares range locked hCount hDecode hRun hWrap

/-- The reserve slot is outside the transaction's read frame: writing it leaves
every finalization observable unchanged, including under an injected
post-write failure. -/
theorem verity_reserve_slot_is_not_read
    (count : Nat) (discount inject : Bool) (state : Verity.ContractState)
    (value : LidoSRv3.Audit.Verity.ReserveRelationalTx.Word) :
    LidoSRv3.Audit.Verity.ReserveRelationalTx.observe
        ((LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize count discount inject).run
          (state.writeSlot
            LidoSRv3.Audit.Verity.ReserveRelationalTx.depositsReserveSlot value)) =
      LidoSRv3.Audit.Verity.ReserveRelationalTx.observe
        ((LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize count discount inject).run
          state) :=
  LidoSRv3.Audit.Verity.ReserveRelationalTx.verity_reserve_slot_is_not_read
    count discount inject state value

/-- Executable-plane statement of the guarantee: contract worlds whose
decodings differ only in `depositsReserve` finalize identically. -/
theorem verity_reserve_does_not_change_finalization
    (inputs : LidoSRv3.Audit.ReserveRelational.Inputs)
    (left right : LidoSRv3.Audit.ReserveRelational.State)
    (stateLeft stateRight : Verity.ContractState)
    (hLeft : LidoSRv3.Audit.Verity.ReserveRelationalTx.Decodes stateLeft inputs left)
    (hRight : LidoSRv3.Audit.Verity.ReserveRelationalTx.Decodes stateRight inputs right)
    (h : LidoSRv3.Audit.ReserveRelational.differOnlyInReserve left right) :
    LidoSRv3.Audit.Verity.ReserveRelationalTx.observe
        ((LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize
          inputs.report.batchEnds.length inputs.report.useDiscount).run stateLeft) =
      LidoSRv3.Audit.Verity.ReserveRelationalTx.observe
        ((LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize
          inputs.report.batchEnds.length inputs.report.useDiscount).run stateRight) :=
  LidoSRv3.Audit.Verity.ReserveRelationalTx.verity_reserve_does_not_change_finalization
    inputs left right stateLeft stateRight hLeft hRight h

/-- Any failure, including one injected after the batch journal and both
finalization writes, returns the exact pre-transaction snapshot. -/
theorem verity_revert_restores_snapshot
    (count : Nat) (discount inject : Bool) (state rollback : Verity.ContractState)
    (reason : String)
    (h : (LidoSRv3.Audit.Verity.ReserveRelationalTx.finalize count discount inject).run state =
      .revert reason rollback) :
    rollback = state :=
  LidoSRv3.Audit.Verity.ReserveRelationalTx.revert_restores_snapshot
    count discount inject state rollback reason h

end LidoSRv3.Audit.Guarantees.PReserveRelational
