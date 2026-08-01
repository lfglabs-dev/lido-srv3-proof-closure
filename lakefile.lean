import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"d2d4a18a4d7021adcd90d4b03e619affe506dd54"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[.andSubmodules `LidoSRv3]
