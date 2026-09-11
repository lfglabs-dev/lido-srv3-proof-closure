import LidoSRv3.Tests.AddressRequestCalls

/-! Executable cross-checks only: the literals below come directly from the
pinned Solidity preimages, independently of the model's slot definitions. -/
open LidoSRv3.Audit.Source.AddressRequestCalls
open LidoSRv3.Audit.Source.TrioReserve1.Live
open LidoSRv3.Audit.Verity.AddressClaimBatchTx
open LidoSRv3.Tests.AddressRequestCalls

#eval diagnostics

def repairedDiagnostics : IO Unit := do
  let correctId := 0x8ee26abbbdf533de3953ccf2204279e845eecb5ab51f8398522746e4ea068041
  let correctReport := 0x6825d6bead7081b4d1ac062bbb771f0e4ade13182688453e79955a721d58c4dd
  let wrongId := 0x8ee26abbbdf5335e3953ccf2204a79e845eecb5ab51f8398526746e4ea068041
  let wrongReport := 0x6825d6bead788134d1ac062bbb7f1f0e4a9e13182688453e79955a721d58c45d
  let core := initial.core.writeSlot correctId 7
  let core := core.writeSlot correctReport 99
  let core := core.writeSlot wrongId 22
  let core := core.writeSlot wrongReport 77
  let state : World := { initial with core := core }
  let result := runRequest acceptsFalse staticTen ctx 2 100 0 state
  let checks := [
    ("correct physical last-ID wins over wrong-slot decoy", result.outcome == Except.ok 8),
    ("correct physical report timestamp consumed", (requestMetadataWord result.world.core 8).val / 2^208 % 2^40 == 99),
    ("obsolete wrong-ID location is not written", (result.world.core.readSlot wrongId).val == 22),
    ("correct physical last-ID updated", (result.world.core.readSlot correctId).val == 8)]
  for (name, passed) in checks do
    if passed then IO.println ("EXEC PASS: " ++ name)
    else throw (IO.userError ("EXEC FAIL: " ++ name))

#eval repairedDiagnostics
