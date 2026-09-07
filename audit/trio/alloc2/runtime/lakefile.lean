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
    .one `audit.trio.alloc2.composition.LibraryABI, .one `audit.trio.alloc2.runtime.Library, .one `audit.trio.alloc2.runtime.Vectors]
