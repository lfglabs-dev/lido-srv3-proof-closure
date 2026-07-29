<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->
# Invariants by status

## PROVED

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-ALLOC-ORDER | P0 | PROVED | REL | LEAN | `LidoSRv3.Audit.valid_result_preserves_router_order` |
| SRV3-ARITH-CHECKED | P0 | PROVED | ALG | LEAN | `LidoSRv3.Audit.Quantity.checkedDiv_zero` |
| SRV3-MINFIRST-BOUND | P0 | PROVED | ALG | LEAN | `LidoSRv3.Audit.MinFirst.totalAllocated_le_requested` |
| SRV3-TX-REVERT | P0 | PROVED | TX | LEAN | `LidoSRv3.Audit.revert_restores_state_value_and_logs` |

## REGRESSION

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-LEGACY-ECON | P0 | REGRESSION | MODEL | LEAN | `LidoSRv3.P1_reserve_separation` |

## DEV-431-READY

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-VERITY-431 | P1 | DEV-431-READY | SRC | VERITY | `—` |

## OPEN

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-SOLIDITY-CORR | P0 | OPEN | SRC | VERITY | `—` |
| SRV3-YUL-COMP | P1 | OPEN | YUL | EVMYULLEAN | `—` |

## BLOCKED

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-CONSOLIDATION-E2E | P0 | BLOCKED | E2E | INTERFACE | `—` |
| SRV3-EVM-RUNTIME | P0 | BLOCKED | EVM | EVMYULLEAN | `—` |

## STRETCH

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-SHA256-PRECOMPILE | STRETCH | STRETCH | CRYPTO | NATIVE-FFI | `—` |

