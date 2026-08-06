import LidoSRv3.Audit.Verity.SszTxSimulation

namespace LidoSRv3.Audit.Verity.Tests.SszTxSimulation

open LidoSRv3.Audit
open LidoSRv3.Audit.Verity.SszAbstractDigest
open LidoSRv3.Audit.Verity.SszTxSimulation

def baseInputs : Inputs :=
  { publicKey := zeros 48
    withdrawalCredentials := zeros 32
    signature := zeros 96
    amountLittleEndian := zeros 8 }

def matching : TxInputs :=
  { toInputs := baseInputs
    forkVersion := zeros 4
    expectedDepositDataRoot := (digestChain baseInputs).getLastD (zeros digestBytes) }

def mutant : TxInputs :=
  { matching with expectedDepositDataRoot := zeros 31 }

#guard runVerification matching == .accept
#guard runVerification mutant == .revertRootMismatch

def rollbackVector : Bool :=
  let tx := transactionObservation mutant (17 : Nat) 999 []
    { calls := [], ethMoves := [{ sender := 1, recipient := 2, amount := ⟨3⟩ }],
      logs := [{ emitter := 1, topic0 := 2, data := [3] }] }
  decide (tx.committedState = 17 ∧ tx.committedTrace.ethMoves = [] ∧
    tx.committedTrace.logs = [])

#guard rollbackVector

#check root_mutant_rejected
#check verification_failure_rolls_back
#check ssz_tx_simulation_correct

end LidoSRv3.Audit.Verity.Tests.SszTxSimulation
