import LidoSRv3.Audit.Source.DereferenceCorrespondence
import Compiler.Proofs.MappingSlot
import EvmYul.Yul.Ast

namespace LidoSRv3.Audit.Verity.DereferenceYulBridge

/-!
Syntax-only interface note for `EVMYulLean@f7e4ee0dc8f8d5265ce822a937ab5be771f182e9`.
`RouterState.moduleStates` is a Solidity `mapping(uint256 => ModuleState)` and
`ModuleState.config.moduleAddress` is the low 160-bit member of its first word.
This file constructs the typed `SLOAD` AST using EVMYulLean's mapping helper.
It does *not* bind `ROUTER_STORAGE_POSITION`, a Solidity layout offset, Verity
storage, compiler output, emitted SLOAD execution, or runtime EVM semantics.
Those provenance links are OPEN; there is intentionally no `exact mapping
location` theorem here.
-/

abbrev YulWord := EvmYul.UInt256
abbrev YulStmt := EvmYul.Yul.Ast.Stmt

def abstractModuleConfigLocation (mappingBase moduleId : Nat) : Nat :=
  Compiler.Proofs.mappingSlotLocation mappingBase moduleId 0

def abstractDereferenceSload (mappingBase moduleId : Nat) : YulStmt :=
  .Let ["packedModuleConfig"]
    (some (.Call (.inl EvmYul.Operation.SLOAD)
      [.Lit (EvmYul.UInt256.ofNat (abstractModuleConfigLocation mappingBase moduleId))]))

end LidoSRv3.Audit.Verity.DereferenceYulBridge
