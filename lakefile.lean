import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"4369b1dfbc42c65ceb76a668f748e9336f0d948f"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[
    .andSubmodules `LidoSRv3,
    .one `LidoSRv3.Audit.Verity.AddressYulInterface,
    .one `LidoSRv3.Tests.AddressYulInterface
  ]
