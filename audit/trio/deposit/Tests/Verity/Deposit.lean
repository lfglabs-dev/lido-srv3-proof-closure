import audit.trio.deposit.Deposit

namespace audit.trio.deposit.Tests.Verity
open LidoSRv3.Audit.Source
open TrioAlloc1 TrioComposition
open audit.trio.deposit

def layout : Layout where
  routerSlot := word 0
  keccak := fun bytes =>
    if bytes.length = 32 then word 100
    else if (decodeWord bytes 32).val = 2 then
      if (decodeWord bytes 0).val = 7 then word 300 else word 301
    else word 200

def storage : Storage := fun slot =>
  if slot.val = 1 then word 1
  else if slot.val = 100 then word 7
  else if slot.val = 200 then word (11 + 10000 * 2^192 + 2^232)
  else if slot.val = 300 then word 1
  else word 0

def config : Config := ⟨word 32, word 64⟩
def oracle : StaticOracle := fun _ _ =>
  .returned (encodeWord (word 0) ++ encodeWord (word 1) ++ encodeWord (word 5))
def limits : DepositLimits := ⟨8⟩

/-- This module succeeds only if the executor really sends the source-derived
cap `min(8, 64/32) = 2`. -/
def exactTargetModule : ObtainDepositData := fun target =>
  if target = 2 then .ok ⟨96⟩ else .error .exceptionalCall

def checkSuccess (result : Except DepositFailure DepositValues) : IO Unit :=
  match result with
  | .ok values => unless values == ⟨64, 2, 64, 32, 64⟩ do
      throw (IO.userError s!"wrong deposit values: {repr values}")
  | .error reason => throw (IO.userError s!"unexpected deposit failure: {repr reason}")

#eval checkSuccess (depositValuesABI layout storage oracle config (word 65) [] (word 7)
  limits exactTargetModule 32).1

/-- The selected cell is fixed by the one-based module-position lookup, not by
an arbitrary caller-provided array index. -/
def allocation : ParentOutput := ⟨word 64, [word 64], [word 96]⟩
def selection : SelectedAllocation layout storage allocation (word 7) where
  moduleIndex := word 0
  moduleIndex_eq := by rfl
  selected := word 64
  selected_eq := by rfl

example : allocation.allocated[selection.moduleIndex.val]? = some selection.selected :=
  selection.selected_eq

def misalignedModule : ObtainDepositData := fun _ => .ok { publicKeysBatchLength := 97 }
def checkFailure (wanted : DepositFailure)
    (result : Except DepositFailure DepositValues) : IO Unit :=
  match result with
  | .error actual => unless actual == wanted do
      throw (IO.userError s!"wrong deposit failure: {repr actual}")
  | .ok values => throw (IO.userError s!"unexpected deposit success: {repr values}")

#eval checkFailure .wrongPubkeyLength
  (depositValuesABI layout storage oracle config (word 65) [] (word 7)
    limits misalignedModule 32).1

def tooManyKeysModule : ObtainDepositData := fun _ => .ok { publicKeysBatchLength := 144 }
#eval checkFailure .moduleReturnExceedTarget
  (depositValuesABI layout storage oracle config (word 65) [] (word 7)
    limits tooManyKeysModule 32).1

-- A different registered ID cannot silently select cell zero.
#eval checkFailure (.moduleIndex (.panic (word 0x11)))
  (depositValuesABI layout storage oracle config (word 65) [] (word 8)
    limits exactTargetModule 32).1

example : PinnedConstructorAdmitted openConstructorCounterexample :=
  pinned_constructor_does_not_discharge_artifact_identities.1
example : ¬ ArtifactAssumptions openConstructorCounterexample :=
  pinned_constructor_does_not_discharge_artifact_identities.2

end audit.trio.deposit.Tests.Verity
