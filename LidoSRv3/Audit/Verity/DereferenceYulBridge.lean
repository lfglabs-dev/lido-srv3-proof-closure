import LidoSRv3.Audit.Source.DereferenceCorrespondence
import Compiler.Proofs.MappingSlot
import EvmYul.Yul.Ast

namespace LidoSRv3.Audit.Verity.DereferenceYulBridge

/-!
Bounded bridge to `EVMYulLean@f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`.
`RouterState.moduleStates` is a Solidity `mapping(uint256 => ModuleState)` and
`ModuleState.config.moduleAddress` is the low 160-bit member of its first word.
This bridge binds Verity's active Solidity mapping-location definition to the
typed EVMYulLean `SLOAD` AST.  It deliberately makes no compiler/runtime-EVM
equivalence claim.
-/

abbrev YulWord := EvmYul.UInt256
abbrev YulStmt := EvmYul.Yul.Ast.Stmt

def moduleConfigLocation (mappingBase moduleId : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation mappingBase moduleId 0

def dereferenceSload (mappingBase moduleId : Nat) : YulStmt :=
  .Let ["packedModuleConfig"]
    (some (.Call (.inl EvmYul.Operation.SLOAD)
      [.Lit (EvmYul.UInt256.ofNat (moduleConfigLocation mappingBase moduleId))]))

theorem bridge_uses_exact_mapping_location (mappingBase moduleId : Nat) :
    dereferenceSload mappingBase moduleId =
      .Let ["packedModuleConfig"]
        (some (.Call (.inl EvmYul.Operation.SLOAD)
          [.Lit (EvmYul.UInt256.ofNat
            (Compiler.Proofs.mappingSlotLocation mappingBase moduleId 0))])) := by
  rfl

end LidoSRv3.Audit.Verity.DereferenceYulBridge
