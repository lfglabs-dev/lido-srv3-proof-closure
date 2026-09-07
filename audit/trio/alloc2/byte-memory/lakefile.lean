import Lake
open Lake DSL
package trioAlloc2ByteMemory where
  srcDir := "../../../.."
@[default_target]
lean_lib TrioAlloc2ByteMemory where
  globs := #[.submodules `LidoSRv3.Audit.Source.TrioAlloc1,
    .submodules `LidoSRv3.Audit.Source.TrioAlloc2,
    .one `audit.trio.alloc2.composition.Composition,
    .one `audit.trio.alloc2.composition.MemoryWrite,
    .one `audit.trio.alloc2.composition.IndexedMemory,
    .one `audit.trio.alloc2.composition.ByteMemory,
    .one `audit.trio.alloc2.composition.ByteIndexed,
    .one `audit.trio.alloc2.composition.ByteVectors]
