import LidoSRv3.Audit.Source.TrioAlloc1.CallTree

/-!
Kill-lines pinning `TrioAlloc1.CallTree` `evaluate` correspondence
identities for the pinned P-ALLOC-1 producer's call-tree
representation.
-/

namespace LidoSRv3.Tests.SourceTrioAlloc1CallTreeKillLines

open LidoSRv3.Audit.Source.TrioAlloc1

/-! ## `evaluate_bind` — restated (bind law for evaluate). -/

theorem evaluate_bind_restated {α β : Type}
    (oracle : StaticOracle) (first : CallTree.Program α)
    (next : α → CallTree.Program β) :
    CallTree.evaluate oracle (CallTree.bind first next) =
      bindExec (CallTree.evaluate oracle first)
        (fun value => CallTree.evaluate oracle (next value)) :=
  CallTree.evaluate_bind oracle first next

/-! ## `firstRow_correspondence` — restated. -/

theorem firstRow_correspondence_restated
    (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (i : Nat) (total : Word) :
    CallTree.evaluate oracle (CallTree.firstRow l s input i total) =
      firstRow l s oracle input i total :=
  CallTree.firstRow_correspondence l s oracle input i total

/-! ## `firstLoop_correspondence` — restated. -/

theorem firstLoop_correspondence_restated
    (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) (n i : Nat) (total : Word) :
    CallTree.evaluate oracle (CallTree.firstLoop l s input n i total) =
      firstLoop l s oracle input n i total :=
  CallTree.firstLoop_correspondence l s oracle input n i total

/-! ## `producer_correspondence` — restated. -/

theorem producer_correspondence_restated
    (l : Layout) (s : Storage) (oracle : StaticOracle)
    (input : CapacityInput) :
    CallTree.evaluate oracle (CallTree.producer l s input) =
      produce l s oracle input :=
  CallTree.producer_correspondence l s oracle input

end LidoSRv3.Tests.SourceTrioAlloc1CallTreeKillLines
