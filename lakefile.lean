import Lake
open Lake DSL

package «lido-srv3-proof-closure» where
  version := v!"0.1.0"

require verity from git
  "https://github.com/lfglabs-dev/verity.git"@"bfa13e715d2a11d476e5d90f9264e87676ff7594"

@[default_target]
lean_lib «LidoSRv3» where
  globs := #[
    .andSubmodules `LidoSRv3,
    .one `LidoSRv3.Audit.Verity.AddressYulInterface,
    .one `LidoSRv3.Tests.AddressYulInterface
  ]
