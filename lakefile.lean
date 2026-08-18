import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"a063bfc869735045354ebc3862ca08859da0f56e"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[
    .andSubmodules `LidoSRv3,
    .one `LidoSRv3.Audit.Verity.AddressYulInterface,
    .one `LidoSRv3.Tests.AddressYulInterface
  ]
