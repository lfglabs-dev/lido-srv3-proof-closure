import audit.trio.deposit.Tests.Verity.LiveBeacon

/-! Throwaway probe: can the fixture prefix equation be checked by the kernel
instead of `native_decide`? Not part of the delivered target. -/
namespace audit.trio.deposit.Tests.Verity.LiveBeaconKernelProbe
open audit.trio.deposit.Tests.Verity.LiveBeacon

set_option maxRecDepth 16384
set_option maxHeartbeats 4000000

theorem prepared_eq_decide : preparedResult = (.ok prepared, transcript) := by decide
theorem prepared_eq_kernel : preparedResult = (.ok prepared, transcript) := by decide +kernel
theorem prepared_eq_rfl : preparedResult = (.ok prepared, transcript) := by rfl

end audit.trio.deposit.Tests.Verity.LiveBeaconKernelProbe
