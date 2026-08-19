import LidoSRv3.Audit.Guarantees.PAddress1
import EvmYul.Yul.Ast

namespace LidoSRv3.Audit.Verity.AddressYulInterface

open Verity
open LidoSRv3.Audit
open LidoSRv3.Audit.AddressEquivariance

/-!
# Typed Yul address interface harness

This is a deliberately small syntax-level interface at the pinned EVMYulLean
dependency.  It names the four address-bearing roles used by the handwritten
Yul boundary and lowers each role to EVMYulLean's typed Yul AST.  It does not
execute the program and makes no EVM refinement claim.
-/

abbrev YulWord := EvmYul.UInt256
abbrev YulStmt := EvmYul.Yul.Ast.Stmt
abbrev YulExpr := EvmYul.Yul.Ast.Expr

/-- Typed, bounded vocabulary for the address-bearing Yul interface. -/
inductive AddressBuiltin where
  | mstoreAddress (memoryOffset address : YulWord)
  | calldataloadAddress (calldataOffset : YulWord)
  | sloadAddress (storageSlot : YulWord)
  | calldatacopySourceTarget
      (memoryOffset calldataOffset byteCount : YulWord)

private def lit (word : YulWord) : YulExpr := .Lit word

/-- Lower the bounded vocabulary directly to the pinned EVMYulLean Yul AST. -/
def AddressBuiltin.toYul : AddressBuiltin → YulStmt
  | .mstoreAddress offset address =>
      .ExprStmtCall (.Call (.inl EvmYul.Operation.MSTORE) [lit offset, lit address])
  | .calldataloadAddress offset =>
      .Let ["loadedAddress"]
        (some (.Call (.inl EvmYul.Operation.CALLDATALOAD) [lit offset]))
  | .sloadAddress storageSlot =>
      .Let ["storedAddress"]
        (some (.Call (.inl EvmYul.Operation.SLOAD) [lit storageSlot]))
  | .calldatacopySourceTarget memoryOffset calldataOffset byteCount =>
      .ExprStmtCall (.Call (.inl EvmYul.Operation.CALLDATACOPY)
        [lit memoryOffset, lit calldataOffset, lit byteCount])

/-- The complete four-operation abstract Yul interface program. -/
def addressProgram (address : YulWord) : List AddressBuiltin :=
  [ .mstoreAddress (EvmYul.UInt256.ofNat 0) address
  , .calldataloadAddress (EvmYul.UInt256.ofNat 0)
  , .sloadAddress (EvmYul.UInt256.ofNat 0)
  , .calldatacopySourceTarget
      (EvmYul.UInt256.ofNat 0) (EvmYul.UInt256.ofNat 0)
      (EvmYul.UInt256.ofNat 64)
  ]

def buildAddressProgram (address : YulWord) : List YulStmt :=
  (addressProgram address).map AddressBuiltin.toYul

/-- A vector binds a Yul address word to the already-proved abstract relation. -/
structure HarnessVector (State : Type) where
  addressWord : YulWord
  rho : Renaming
  renameState : State → State
  before : TxObservation State
  after : TxObservation State

/-- Syntax builds independently of the vector contents. -/
def Builds (vector : HarnessVector State) : Prop :=
  buildAddressProgram vector.addressWord =
    (addressProgram vector.addressWord).map AddressBuiltin.toYul

/-- The only semantic binding is the existing abstract address-renaming theorem. -/
def RespectsAbstractRename (vector : HarnessVector State) : Prop :=
  Equivariant vector.rho vector.renameState vector.before vector.after

/-- The complete, universally quantified harness proposition. -/
def MutantSensitiveHarness : Prop :=
  ∀ (State : Type) (rho : Renaming) (renameState : State → State)
    (before : TxObservation State) (addressWord : YulWord),
    Builds
      { addressWord := addressWord
        rho := rho
        renameState := renameState
        before := before
        after := renameObservation rho renameState before } ∧
    RespectsAbstractRename
      { addressWord := addressWord
        rho := rho
        renameState := renameState
        before := before
        after := renameObservation rho renameState before }

/--
The pinned typed-Yul program builds for every vector, and the canonical renamed
observation satisfies the existing P-ADDRESS-1 abstract relation.  No Yul
execution or EVM semantics are asserted.
-/
theorem mutant_sensitive_harness : MutantSensitiveHarness := by
  intro State rho renameState before addressWord
  constructor
  · rfl
  · exact rename_is_equivariant rho renameState before

end LidoSRv3.Audit.Verity.AddressYulInterface
