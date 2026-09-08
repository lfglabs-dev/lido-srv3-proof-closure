import audit.trio.deposit.Deposit

namespace audit.trio.deposit.Tests.Verity

open LidoSRv3.Audit.Source.TrioAlloc1
open LidoSRv3.Audit.Source.TrioComposition
open audit.trio.deposit

def config : Config := ⟨word 32, word 64⟩

def allocation : ParentOutput := ⟨word 64, [word 64], [word 64]⟩

def entry : State :=
  { routerBalance := 0
    lidoDepositable := 100
    lastDeposit := [0]
    committedCalls := [] }

def inputs (beaconOk : Nat → Bool) (depositSize : Nat := 32) : Inputs :=
  { moduleIndex := 0
    moduleAddress := ⟨0x100, by native_decide⟩
    lidoAddress := ⟨0x200, by native_decide⟩
    depositContract := ⟨0x300, by native_decide⟩
    actualKeys := 2
    depositSize := depositSize
    moduleCallOk := true
    lidoCallOk := true
    beaconCallOk := beaconOk }

def secondBeaconFails : Nat → Bool
  | 1 => false
  | _ => true

def isSecondBeaconFailure : Outcome → Bool
  | ⟨.error (.beaconCall 1), _, _⟩ => true
  | _ => false

def isSuccess : Outcome → Bool
  | ⟨.ok (), _, _⟩ => true
  | _ => false

def isBalanceAssertion : Outcome → Bool
  | ⟨.error .balanceAssertion, _, _⟩ => true
  | _ => false

#guard isSecondBeaconFailure (executeSuffix config allocation (inputs secondBeaconFails) entry)

#guard (executeSuffix config allocation (inputs secondBeaconFails) entry).state == entry

#guard (executeSuffix config allocation (inputs secondBeaconFails) entry).attempts.length == 4

#guard isSuccess (executeSuffix config allocation (inputs (fun _ => true)) entry)

#guard (executeSuffix config allocation (inputs (fun _ => true)) entry).state.routerBalance == 0

#guard (executeSuffix config allocation (inputs (fun _ => true)) entry).state.lidoDepositable == 36

/- A pull scale differing from the beacon value reaches the executable final
balance assertion and rolls the prior write, pull, and beacon calls back. -/
#guard isBalanceAssertion (executeSuffix config allocation (inputs (fun _ => true) 31) entry)

#guard (executeSuffix config allocation (inputs (fun _ => true) 31) entry).state == entry

example : LinksSource allocation config (inputs (fun _ => true) 31) := by
  refine ⟨word 64, by native_decide, by native_decide⟩

/-- `LinksSource` does not imply the 32-ether artifact identity. -/
example : ¬ ArtifactAssumptions (inputs (fun _ => true) 31) := by
  intro h
  have := h.A_DEPOSIT_32_ETHER
  change 31 = 32 * 10 ^ 18 at this
  omega

end audit.trio.deposit.Tests.Verity
