import Init

/-!
Independent mathematical proportional step. Unbounded Nat arithmetic; no source
scan, word helpers, or executor calls. The minimum open level is computed globally,
ties use the original array index, and all greater open levels bound the fill.
This is the proportional algorithm, separate from the repository's +1 algorithm.
Correspondence to the decoded word executor is not yet proved.
-/
namespace LidoSRv3.Audit.Source.TrioAlloc2.Spec

structure Row where
  allocation : Nat
  capacity : Nat
  deriving DecidableEq, Repr

structure Choice where
  index : Nat
  amount : Nat
  deriving DecidableEq, Repr

/-- An empty set has no minimum; no artificial word-sized sentinel. -/
def minimum (levels : List Nat) : Option Nat :=
  match levels with
  | [] => none
  | x :: xs => some (xs.foldl Nat.min x)

def choose (rows : List Row) (demand : Nat) : Option Choice := do
  if demand = 0 then none else do
    let openRows := rows.zipIdx |>.filter (fun entry => entry.1.allocation < entry.1.capacity)
    let level ← minimum (openRows.map (fun entry => entry.1.allocation))
    let tied := openRows.filter (fun entry => entry.1.allocation = level)
    let first ← tied.head?
    let higher := openRows.filter (fun entry => level < entry.1.allocation)
    let ceiling := (higher.map (fun entry => entry.1.allocation)).foldl Nat.min first.1.capacity
    let share := (demand + tied.length - 1) / tied.length
    some { index := first.2, amount := min share (ceiling - level) }

def step (rows : List Row) (demand : Nat) : Nat × List Row :=
  match choose rows demand with
  | none => (0, rows)
  | some choice =>
    (choice.amount, rows.zipIdx |>.map fun (row, index) =>
      if index = choice.index then { row with allocation := row.allocation + choice.amount }
      else row)

theorem choose_zero (rows : List Row) : choose rows 0 = none := by rfl

theorem step_zero (rows : List Row) : step rows 0 = (0, rows) := by rfl

theorem step_length (rows : List Row) (demand : Nat) :
    (step rows demand).2.length = rows.length := by
  unfold step
  split
  · rfl
  · simp

/-- Independent complete distribution relation. Its rules use mathematical
selection and row updates only. No executable-source success or fuel premise.
Existence and correspondence to the word loop remain separate obligations. -/
inductive Distributes : List Row → Nat → Nat → List Row → Prop where
  | stopped (rows : List Row) (demand : Nat) (h : choose rows demand = none) :
      Distributes rows demand 0 rows
  | advance (rows : List Row) (demand : Nat) (choice : Choice)
      (spent : Nat) (final : List Row)
      (selected : choose rows demand = some choice)
      (rest : Distributes (step rows demand).2 (demand - choice.amount) spent final) :
      Distributes rows demand (choice.amount + spent) final

theorem Distributes.preserves_length (h : Distributes rows demand spent final) :
    final.length = rows.length := by
  induction h with
  | stopped => rfl
  | advance rows demand choice spent final selected rest ih =>
    exact ih.trans (step_length rows demand)

theorem distributes_zero (rows : List Row) : Distributes rows 0 0 rows :=
  .stopped rows 0 (choose_zero rows)

end LidoSRv3.Audit.Source.TrioAlloc2.Spec
