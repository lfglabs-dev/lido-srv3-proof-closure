import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"1348e19634b52ffd8f2ceaf5c1a21dc7b7a076d6"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[.andSubmodules `LidoSRv3]
