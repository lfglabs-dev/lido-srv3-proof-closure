import Lake
open Lake DSL
package trioAlloc2Runtime where
  srcDir := "../../../.."
require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"e977aaad6e1a9e92e0132d41b3d33a14135a4d46"
@[default_target]
lean_lib TrioAlloc2Runtime where
  globs := #[.submodules `LidoSRv3.Audit.Source.TrioAlloc1,
    .submodules `LidoSRv3.Audit.Source.TrioAlloc2,
    .one `audit.trio.alloc2.composition.Composition,
    .one `audit.trio.alloc2.composition.LibraryABI,
    .one `audit.trio.alloc2.composition.MemoryExtent,
    .one `audit.trio.alloc2.composition.AllocationMemoryBridge,
    .one `audit.trio.alloc2.composition.MemoryVectors,
    .one `audit.trio.alloc2.composition.LibraryABIVectors,
    .one `audit.trio.alloc2.composition.Parent,
    .one `audit.trio.alloc2.composition.ParentPostconditions,
    .one `audit.trio.alloc2.composition.ParentErrors,
    .one `audit.trio.alloc2.composition.ParentInversion,
    .one `audit.trio.alloc2.composition.ProducerMemory,
    .one `audit.trio.alloc2.composition.ProducerMemoryVectors,
    .one `audit.trio.alloc2.composition.ParentVectors, .one `audit.trio.alloc2.runtime.Library, .one `audit.trio.alloc2.runtime.Vectors]
