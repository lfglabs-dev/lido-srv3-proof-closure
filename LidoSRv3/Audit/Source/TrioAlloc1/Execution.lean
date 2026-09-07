import LidoSRv3.Audit.Source.TrioAlloc1.Storage

/-!
Source-shaped helper execution, with an adversarial static-call transcript.
The observer is ghost state: it is never placed in router storage. Callee behavior
can depend on the full prior transcript; failures retain attempted calls.
Compiler/memory allocation and callback realization remain separate obligations.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc1

structure CallRequest where
  target : Address
  payload : Bytes
  deriving DecidableEq, Repr

inductive CallResponse where
  | returned (data : Bytes)
  | reverted (data : Bytes)
  | exceptional
  deriving DecidableEq, Repr

structure CallObservation where
  request : CallRequest
  response : CallResponse
  deriving DecidableEq, Repr

abbrev Transcript := List CallObservation
abbrev StaticOracle := Transcript → CallRequest → CallResponse
abbrev Execution (α : Type) := Transcript → Except Failure α × Transcript

def pureExec (a : α) : Execution α := fun t => (.ok a, t)
def failExec (e : Failure) : Execution α := fun t => (.error e, t)
def bindExec (a : Execution α) (f : α → Execution β) : Execution β := fun t =>
  match a t with
  | (.error e, t') => (.error e, t')
  | (.ok value, t') => f value t'

instance : Monad Execution where
  pure := pureExec
  bind := bindExec

def liftChecked (a : Except Failure α) : Execution α := fun t => (a, t)

def checked (n : Nat) : Except Failure Word :=
  if h : n < 2^256 then .ok ⟨n, h⟩ else .error (.panic (word 0x11))
def checkedSub (a b : Nat) : Except Failure Word :=
  if b ≤ a then checked (a-b) else .error (.panic (word 0x11))
def checkedDiv (a b : Word) : Except Failure Word :=
  if b.val = 0 then .error (.panic (word 0x12)) else .ok (word (a.val / b.val))

/-- OZ 5.2 Math.ceilDiv checks a zero divisor even when its numerator is zero. -/
def checkedCeilDiv (a b : Word) : Except Failure Word :=
  if b.val = 0 then .error (.panic (word 0x12))
  else if a.val = 0 then .ok (word 0)
  else checked ((a.val - 1) / b.val + 1)

def summaryPayload : Bytes := [byte 0x9a, byte 0xbd, byte 0xdf, byte 0x09]
def stakePayload : Bytes := [byte 0x0c, byte 0x85, byte 0x2f, byte 0x5c]

def staticCall (oracle : StaticOracle) (request : CallRequest) : Execution Bytes := fun t =>
  let response := oracle t request
  let t' := t ++ [{ request, response }]
  match response with
  | .returned bytes => (.ok bytes, t')
  | .reverted bytes => (.error (.revertData bytes), t')
  | .exceptional => (.error .exceptionalCall, t')

def decodeWord (bytes : Bytes) (offset : Nat) : Word :=
  word (((bytes.drop offset).take 32).foldl (fun n b => n*256+b.val) 0)

structure Summary where
  exited : Word
  deposited : Word
  depositable : Word
  deriving DecidableEq, Repr

def decodeSummary (bytes : Bytes) : Except Failure Summary :=
  if bytes.length < 96 then .error .decoderFailure
  else .ok { exited := decodeWord bytes 0, deposited := decodeWord bytes 32,
             depositable := decodeWord bytes 64 }

def decodeStake (bytes : Bytes) : Except Failure Word :=
  if bytes.length < 32 then .error .decoderFailure else .ok (decodeWord bytes 0)

structure CachedRow where
  stored : StoredModule
  summary : Summary
  active : Word
  allocation : Word
  deriving DecidableEq, Repr

/-- One source iteration, including arithmetic before the next external call. -/
def firstRow (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) : Execution (CachedRow × Word) := do
  let stored := readModule l s i
  -- Copying the storage enum into the memory struct validates its range.
  if stored.status.val ≥ 3 then
    failExec (.panic (word 0x21))
  else
    let bytes ← staticCall oracle { target := stored.identity.moduleAddress, payload := summaryPayload }
    let summary ← liftChecked (decodeSummary bytes)
    let active ← liftChecked (checkedSub summary.deposited.val
      (max summary.exited.val stored.accountingExited.val))
    let allocation ← if stored.wcType.val = 2 then do
      let stakeBytes ← staticCall oracle { target := stored.identity.moduleAddress, payload := stakePayload }
      let stake ← liftChecked (decodeStake stakeBytes)
      liftChecked (checkedCeilDiv stake input.config.maxEBType1)
      else pure active
    let total' ← liftChecked (checked (total.val + allocation.val))
    pure ({ stored, summary, active, allocation }, total')

def firstLoop (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) : Nat → Nat → Word → Execution (List CachedRow × Word)
  | 0, _, total => pure ([], total)
  | n+1, i, total => do
    let (row, total') ← firstRow l s oracle input i total
    let (rows, finalTotal) ← firstLoop l s oracle input n (i+1) total'
    pure (row :: rows, finalTotal)

def rowCapacity (input : CapacityInput) (total : Word) (row : CachedRow) :
    Except Failure Word := do
  if row.stored.status.val ≠ 0 then pure row.allocation
  else
    let available ← if input.isTopUp && row.stored.wcType.val == 2 then do
      let product ← checked (row.active.val * input.config.maxEBType2.val)
      checkedDiv product input.config.maxEBType1
      else checked (row.allocation.val + row.summary.depositable.val)
    let product ← checked (row.stored.share.val * total.val)
    let target := product.val / 10000
    pure (word (min target available.val))

structure Bucket where
  row : CachedRow
  capacity : Word

def secondLoop (input : CapacityInput) (total : Word) :
    List CachedRow → Except Failure (List Bucket)
  | [] => .ok []
  | row :: rows => do
    let capacity ← rowCapacity input total row
    let rest ← secondLoop input total rows
    pure ({ row, capacity } :: rest)

def outputOfBuckets (buckets : List Bucket) : CapacityOutput where
  identities := buckets.map fun b => b.row.stored.identity
  allocations := buckets.map fun b => b.row.allocation
  capacities := buckets.map fun b => b.capacity
  allocations_length := by simp
  capacities_length := by simp

/-- Executes the internal helper; the public zero-count/division guard is upstream. -/
def produce (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) : Execution CapacityOutput := do
  let count := (s (countSlot l)).val
  let (rows, total) ← firstLoop l s oracle input count 0 input.depositsToAllocate
  let buckets ← liftChecked (secondLoop input total rows)
  pure (outputOfBuckets buckets)

/-- Consumer equal-length premise is constructed for every successful execution. -/
theorem producer_lengths (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (before after : Transcript) (output : CapacityOutput)
    (_h : produce l s oracle input before = (.ok output, after)) :
    output.allocations.length = output.capacities.length := output_lengths_equal output

end LidoSRv3.Audit.Source.TrioAlloc1
