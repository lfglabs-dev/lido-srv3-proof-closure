import Lake
open Lake DSL
package trioAlloc2ByteABI where
  srcDir := "../../../.."
require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"e977aaad6e1a9e92e0132d41b3d33a14135a4d46"
@[default_target]
lean_lib TrioAlloc2ByteABI where
  globs := #[.submodules `LidoSRv3.Audit.Source.TrioAlloc1,
    .submodules `LidoSRv3.Audit.Source.TrioAlloc2,
    .one `audit.trio.alloc2.composition.Composition,
    .one `audit.trio.alloc2.composition.MemoryWrite,
    .one `audit.trio.alloc2.composition.IndexedMemory,
    .one `audit.trio.alloc2.composition.ByteMemory,
    .one `audit.trio.alloc2.composition.ByteIndexed,
    .one `audit.trio.alloc2.composition.ByteInitialize,
    .one `audit.trio.alloc2.composition.ByteFrame,
    .one `audit.trio.alloc2.composition.ByteProducer,
    .one `audit.trio.alloc2.runtime.ByteMemory,
    .one `audit.trio.alloc2.runtime.ByteLoop,
    .one `audit.trio.alloc2.runtime.ByteInitialize,
    .one `audit.trio.alloc2.runtime.ByteVectors,
    .one `audit.trio.alloc2.composition.LibraryABI,
    .one `audit.trio.alloc2.runtime.ByteABI,
    .one `audit.trio.alloc2.runtime.ByteABIProducer,
    .one `audit.trio.alloc2.runtime.ByteABIVectors,
    .one `audit.trio.alloc2.runtime.ByteABIFrame,
    .one `audit.trio.alloc2.composition.ProducerMemory,
    .one `audit.trio.alloc2.composition.AllocationMemoryBridge,
    .one `audit.trio.alloc2.composition.MemoryExtent,
    .one `audit.trio.alloc2.runtime.ByteCoverage]
