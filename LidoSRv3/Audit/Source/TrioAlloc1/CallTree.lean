import LidoSRv3.Audit.Source.TrioAlloc1.Execution

/-! Full producer as an explicit call tree. Unlike a completed transcript replay,
continuations decode each response and perform checked arithmetic before creating
the next call. This representation permits interpretation by a separate call VM. -/
namespace LidoSRv3.Audit.Source.TrioAlloc1
namespace CallTree

inductive Program (α : Type) where
  | done (result : Except Failure α)
  | call (request : CallRequest) (next : CallResponse → Program α)

def bind (first : Program α) (next : α → Program β) : Program β :=
  match first with
  | .done (.error reason) => .done (.error reason)
  | .done (.ok value) => next value
  | .call request rest => .call request fun response => bind (rest response) next

instance : Monad Program where
  pure value := .done (.ok value)
  bind := bind

def check (result : Except Failure α) : Program α := .done result

def call (request : CallRequest) : Program Bytes :=
  .call request fun response => .done (match response with
    | .returned bytes => .ok bytes
    | .reverted bytes => .error (.revertData bytes)
    | .exceptional => .error .exceptionalCall)

def evaluate (oracle : StaticOracle) : Program α → Execution α
  | .done result => fun before => (result, before)
  | .call request next => fun before =>
    let response := oracle before request
    evaluate oracle (next response) (before ++ [{ request, response }])

theorem evaluate_bind (oracle : StaticOracle) (first : Program α) (next : α → Program β) :
    evaluate oracle (bind first next) = bindExec (evaluate oracle first) (fun value => evaluate oracle (next value)) := by
  induction first with
  | done result => cases result <;> rfl
  | call request rest ih =>
    funext before
    simp only [bind, evaluate, bindExec]
    exact congrFun (ih (oracle before request)) _

@[simp] theorem evaluate_check (oracle : StaticOracle) (result : Except Failure α) :
    evaluate oracle (check result) = liftChecked result := by
  cases result <;> rfl

@[simp] theorem evaluate_call (oracle : StaticOracle) (request : CallRequest) :
    evaluate oracle (call request) = staticCall oracle request := by
  funext before
  simp only [call, evaluate, staticCall]
  cases oracle before request <;> rfl

@[simp] theorem evaluate_monad_bind (oracle : StaticOracle) (first : Program α)
    (next : α → Program β) :
    evaluate oracle (first >>= next) = (evaluate oracle first >>= fun value => evaluate oracle (next value)) :=
  evaluate_bind oracle first next

@[simp] theorem evaluate_pure (oracle : StaticOracle) (value : α) :
    evaluate oracle (pure value) = pureExec value := rfl

@[simp] theorem evaluate_ite (oracle : StaticOracle) (p : Prop) [Decidable p]
    (yes no : Program α) :
    evaluate oracle (if p then yes else no) = if p then evaluate oracle yes else evaluate oracle no := by
  split <;> rfl

def firstRow (l : Layout) (s : Storage) (input : CapacityInput)
    (i : Nat) (total : Word) : Program (CachedRow × Word) := do
  let stored := readModule l s i
  if stored.status.val ≥ 3 then check (.error (.panic (word 0x21)))
  else
    let bytes ← call { target := stored.identity.moduleAddress, payload := summaryPayload }
    let summary ← check (decodeSummary bytes)
    let active ← check (checkedSub summary.deposited.val (max summary.exited.val stored.accountingExited.val))
    let allocation ← if stored.wcType.val = 2 then do
      let stakeBytes ← call { target := stored.identity.moduleAddress, payload := stakePayload }
      let stake ← check (decodeStake stakeBytes)
      check (checkedCeilDiv stake input.config.maxEBType1)
      else pure active
    let total' ← check (checked (total.val + allocation.val))
    pure ({ stored, summary, active, allocation }, total')

def firstLoop (l : Layout) (s : Storage) (input : CapacityInput) :
    Nat → Nat → Word → Program (List CachedRow × Word)
  | 0, _, total => pure ([], total)
  | n+1, i, total => do
    let (row, total') ← firstRow l s input i total
    let (rows, finalTotal) ← firstLoop l s input n (i+1) total'
    pure (row :: rows, finalTotal)

def producer (l : Layout) (s : Storage) (input : CapacityInput) : Program CapacityOutput := do
  let (rows, total) ← firstLoop l s input (s (countSlot l)).val 0 input.depositsToAllocate
  let buckets ← check (secondLoop input total rows)
  pure (outputOfBuckets buckets)

theorem firstRow_correspondence (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) :
    evaluate oracle (firstRow l s input i total) =
      LidoSRv3.Audit.Source.TrioAlloc1.firstRow l s oracle input i total := by
  simp only [firstRow, LidoSRv3.Audit.Source.TrioAlloc1.firstRow,
    evaluate_ite, evaluate_monad_bind, evaluate_check, evaluate_call, evaluate_pure]
  rfl

theorem firstLoop_correspondence (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n i : Nat) (total : Word) :
    evaluate oracle (firstLoop l s input n i total) =
      LidoSRv3.Audit.Source.TrioAlloc1.firstLoop l s oracle input n i total := by
  induction n generalizing i total with
  | zero => rfl
  | succ n ih =>
    simp only [firstLoop, LidoSRv3.Audit.Source.TrioAlloc1.firstLoop,
      evaluate_monad_bind, firstRow_correspondence, ih, evaluate_pure]
    rfl

theorem producer_correspondence (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) :
    evaluate oracle (producer l s input) = produce l s oracle input := by
  simp only [producer, produce, evaluate_monad_bind, firstLoop_correspondence,
    evaluate_check, evaluate_pure]
  rfl

end CallTree
end LidoSRv3.Audit.Source.TrioAlloc1
