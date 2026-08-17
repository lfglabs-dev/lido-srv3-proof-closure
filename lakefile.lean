import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"a97cfafefececbdea8212f37b99d3c7c480c8061"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[
    .andSubmodules `LidoSRv3,
    .one `LidoSRv3.Audit.Verity.AddressYulInterface,
    .one `LidoSRv3.Tests.AddressYulInterface
  ]
