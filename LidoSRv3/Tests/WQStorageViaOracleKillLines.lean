import LidoSRv3.Audit.Source.WQStorageViaOracleSource

/-! # Kill-lines for `WQStorageViaOracleSource`

**Chantier 2 (Piste A, Thomas 2026-09-13) mutant kill-lines pinning
oracle-backed WithdrawalQueueStorage projections.** -/

namespace LidoSRv3.Tests.WQStorageViaOracleKillLines

open LidoSRv3.Audit.Source.WQStorageViaOracleSource
open LidoSRv3.Audit.Source.WithdrawalQueueMappingSource
open LidoSRv3.Audit.Source.MappingSlotViaOracleSource
open LidoSRv3.Audit.Source.KeccakConcreteCommitmentSource

private def testOracle : KeccakOracle :=
  { hash := fun n => n + 1
    determinism := fun _ _ h => by rw [h] }

/-- **Kill-line: realWQStorage projects to the real mapping storage.** -/
theorem realWQStorage_readRequest_at_witness
    (oracle : KeccakOracle) (qb cb u req : Nat) :
    readRequest (realWQStorage oracle qb cb u) req =
      (realMappingStorage oracle qb).slotAt req :=
  realWQStorage_readRequest_eq oracle qb cb u req

/-- **Kill-line: realWQStorage.readCheckpoint projects to the checkpoint
mapping.** -/
theorem realWQStorage_readCheckpoint_at_witness
    (oracle : KeccakOracle) (qb cb u hint : Nat) :
    readCheckpoint (realWQStorage oracle qb cb u) hint =
      (realMappingStorage oracle cb).slotAt hint :=
  realWQStorage_readCheckpoint_eq oracle qb cb u hint

/-- **Kill-line: realWQStorage carries the unfinalizedStETH
accumulator exactly.** -/
theorem realWQStorage_unfinalized_at_witness
    (oracle : KeccakOracle) (qb cb : Nat) (u : Nat) :
    unfinalizedStETHFromStorage (realWQStorage oracle qb cb u) = u :=
  realWQStorage_unfinalized_eq oracle qb cb u

/-- **Kill-line: realWQStorage at zero accumulator is zero.** -/
theorem realWQStorage_zero_witness :
    unfinalizedStETHFromStorage (realWQStorage testOracle 5 7 0) = 0 := rfl

#print axioms realWQStorage_readRequest_at_witness
#print axioms realWQStorage_readCheckpoint_at_witness
#print axioms realWQStorage_unfinalized_at_witness
#print axioms realWQStorage_zero_witness

end LidoSRv3.Tests.WQStorageViaOracleKillLines
