import Lake
open Lake DSL

package trioDeposit where
  srcDir := "../../.."

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"e977aaad6e1a9e92e0132d41b3d33a14135a4d46"

@[default_target]
lean_lib TrioDeposit where
  globs := #[
    .submodules `audit.trio.deposit,
    .submodules `LidoSRv3.Audit.Source.TrioAlloc1,
    .submodules `LidoSRv3.Audit.Source.TrioAlloc2,
    .submodules `LidoSRv3.Audit.Source.TrioComposition
  ]
