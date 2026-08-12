namespace LidoSRv3.Audit.Common

/-!
Common semantic units. The phantom parameter makes unit mismatches ill-typed;
the representation is intentionally independent of any particular source model.
-/

inductive WeiUnit
  deriving DecidableEq, Repr
inductive GweiUnit
  deriving DecidableEq, Repr
inductive ValidatorUnit
  deriving DecidableEq, Repr
inductive BasisPointUnit
  deriving DecidableEq, Repr

structure Amount (unit : Type) where
  value : Nat
  deriving DecidableEq, Repr

abbrev Wei := Amount WeiUnit
abbrev Gwei := Amount GweiUnit
abbrev Validators := Amount ValidatorUnit
abbrev BasisPoints := Amount BasisPointUnit

namespace Amount

def zero : Amount unit := ⟨0⟩
def add (a b : Amount unit) : Amount unit := ⟨a.value + b.value⟩

end Amount

end LidoSRv3.Audit.Common
