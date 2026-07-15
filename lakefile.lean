import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"538c4a9ce2baa25b56062bdc727eb0191ad9e67f"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[.andSubmodules `LidoSRv3]
