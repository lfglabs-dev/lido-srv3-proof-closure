import LidoSRv3.Audit.Allocation

namespace LidoSRv3.Audit.MinFirst

/-!
An executable model of the pinned `MinFirstAllocationStrategy` control rule.
`Nat` is the proof-domain image of source `uint256` values. One loop iteration
allocates one validator, so `requested` is an exact sufficient fuel bound.
-/

structure Bucket where
  moduleId : Word
  active : Bool
  credentialType : CredentialType
  allocation : Nat
  capacity : Nat
  deriving DecidableEq, Repr

def Bucket.open (b : Bucket) : Bool :=
  b.active && decide (b.allocation < b.capacity)

/-- First least-filled open bucket. Strict comparison retains the left bucket
on equality, which is the source router-order tie break. -/
def candidate? : List Bucket → Option Bucket
  | [] => none
  | b :: bs =>
      match candidate? bs with
      | none => if b.open then some b else none
      | some later =>
          if b.open && decide (b.allocation ≤ later.allocation)
          then some b else some later

def incrementSelected (selected : Bucket) (b : Bucket) : Bucket :=
  if b.moduleId = selected.moduleId then
    { b with allocation := b.allocation + 1 }
  else b

def step (rows : List Bucket) : List Bucket :=
  match candidate? rows with
  | none => rows
  | some selected => rows.map (incrementSelected selected)

structure Run where
  rows : List Bucket
  spent : Nat
  deriving DecidableEq, Repr

def run : Nat → List Bucket → Run
  | 0, rows => ⟨rows, 0⟩
  | fuel + 1, rows =>
      match candidate? rows with
      | none => ⟨rows, 0⟩
      | some selected =>
          let tail := run fuel (rows.map (incrementSelected selected))
          ⟨tail.rows, tail.spent + 1⟩

def loop (fuel : Nat) (rows : List Bucket) : List Bucket :=
  (run fuel rows).rows

def allocate (requested : Nat) (rows : List Bucket) : List Bucket :=
  loop requested rows

def totalAllocated (requested : Nat) (rows : List Bucket) : Nat :=
  (run requested rows).spent

def fromRow (row : AllocationRow) : Bucket :=
  { moduleId := row.moduleId
    active := row.active
    credentialType := row.credentialType
    allocation := row.current.value
    capacity := row.capacity.value }

def fromSnapshot (snapshot : AllocationSnapshot) : List Bucket :=
  snapshot.rows.map fromRow

end LidoSRv3.Audit.MinFirst
