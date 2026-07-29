import Lake
open Lake DSL

-- Audit-only proposed root. This is not the repository's active Lake configuration.
package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"68f560e66c5de6123061ce5ed60261be162673d1"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[.andSubmodules `LidoSRv3]
