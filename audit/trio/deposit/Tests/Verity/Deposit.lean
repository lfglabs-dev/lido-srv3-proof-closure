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
def twoKeyData : ModuleDepositData :=
  ⟨List.replicate 96 (byte 1), List.replicate 192 (byte 2)⟩

/-- This module succeeds only if the executor really sends the source-derived
cap `min(8, 64/32) = 2`. -/
def exactTargetModule : ObtainDepositData := fun target =>
  if target = 2 then .ok twoKeyData else .error .exceptionalCall

def exactWithdrawal : WithdrawDepositableEther := fun amount seeds =>
  if amount = word 64 ∧ seeds = word 2 then .ok () else .error .exceptionalCall

def checkSuccess (result : Except DepositFailure DepositExecution) : IO Unit :=
  match result with
  | .ok execution => unless execution ==
      ⟨word 7, word 32, twoKeyData, ⟨64, 2, 64, 32, 64⟩,
        some ⟨word 64, word 2⟩⟩ do
      throw (IO.userError s!"wrong deposit execution: {repr execution}")
  | .error reason => throw (IO.userError s!"unexpected deposit failure: {repr reason}")

def successfulExecution : DepositExecution :=
  ⟨word 7, word 32, twoKeyData, ⟨64, 2, 64, 32, 64⟩,
    some ⟨word 64, word 2⟩⟩
def successfulRun := depositValuesABI layout storage oracle config (word 65) [] (word 7)
  limits exactTargetModule 32 exactWithdrawal
def successfulAfter : Transcript := successfulRun.2
theorem successfulRun_eq : successfulRun = (.ok successfulExecution, successfulAfter) := by
  native_decide

#eval checkSuccess (depositValuesABI layout storage oracle config (word 65) [] (word 7)
  limits exactTargetModule 32 exactWithdrawal).1

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

def misalignedModule : ObtainDepositData := fun _ =>
  .ok ⟨List.replicate 97 (byte 1), []⟩
def checkFailure (wanted : DepositFailure)
    (result : Except DepositFailure DepositExecution) : IO Unit :=
  match result with
  | .error actual => unless actual == wanted do
      throw (IO.userError s!"wrong deposit failure: {repr actual}")
  | .ok values => throw (IO.userError s!"unexpected deposit success: {repr values}")

#eval checkFailure .wrongPubkeyLength
  (depositValuesABI layout storage oracle config (word 65) [] (word 7)
    limits misalignedModule 32 exactWithdrawal).1

def tooManyKeysModule : ObtainDepositData := fun _ =>
  .ok ⟨List.replicate 144 (byte 1), List.replicate 288 (byte 2)⟩
#eval checkFailure .moduleReturnExceedTarget
  (depositValuesABI layout storage oracle config (word 65) [] (word 7)
    limits tooManyKeysModule 32 exactWithdrawal).1

-- A different registered ID cannot silently select cell zero.
#eval checkFailure (.moduleIndex (.panic (word 0x11)))
  (depositValuesABI layout storage oracle config (word 65) [] (word 8)
    limits exactTargetModule 32 exactWithdrawal).1

/-- This module call reaches StakingRouter.sol:978 with a zero derived key
count. The hostile withdrawal must not be observed: line 978 returns before
the Lido call at line 983. -/
def zeroKeysModule : ObtainDepositData := fun target =>
  if target = 2 then .ok ⟨[], []⟩ else .error .exceptionalCall

def hostileWithdrawal : WithdrawDepositableEther := fun _ _ => .error .exceptionalCall

def checkZeroKeysReturn (result : Except DepositFailure DepositExecution) : IO Unit :=
  match result with
  | .ok execution => unless execution ==
      ⟨word 7, word 32, ⟨[], []⟩, ⟨64, 0, 0, 32, 0⟩, none⟩ do
      throw (IO.userError s!"zero-key path called Lido or returned wrong values: {repr execution}")
  | .error reason => throw (IO.userError s!"zero-key path unexpectedly failed: {repr reason}")

#eval checkZeroKeysReturn
  (depositValuesABI layout storage oracle config (word 65) [] (word 7)
    limits zeroKeysModule 32 hostileWithdrawal).1

/-- This live callback accepts only the source ABI tuple
`(actualKeys * maxEBType1, actualKeys)`. It rejects any arbitrary seed word. -/
def rejectArbitrarySeeds : WithdrawDepositableEther := fun amount seeds =>
  if amount = word 64 ∧ seeds = word 2 then .ok () else .error .exceptionalCall

#eval checkSuccess (depositValuesABI layout storage oracle config (word 65) [] (word 7)
  limits exactTargetModule 32 rejectArbitrarySeeds).1

example : PinnedConstructorAdmitted openConstructorCounterexample :=
  pinned_constructor_does_not_discharge_artifact_identities.1
example : ¬ ArtifactAssumptions openConstructorCounterexample :=
  pinned_constructor_does_not_discharge_artifact_identities.2

end audit.trio.deposit.Tests.Verity
