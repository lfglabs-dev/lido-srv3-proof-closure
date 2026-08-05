import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"066f1bf5772ebc6cc218902b8f05ad70cbf36866"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[.andSubmodules `LidoSRv3]
