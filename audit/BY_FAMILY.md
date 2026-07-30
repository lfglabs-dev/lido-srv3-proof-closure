<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->
# Invariants by family

## allocation

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-ALLOC-ORDER | P0 | PROVED | REL | LEAN | `LidoSRv3.Audit.valid_result_preserves_router_order` |
| SRV3-MINFIRST-BOUND | P0 | PROVED | ALG | LEAN | `LidoSRv3.Audit.MinFirst.totalAllocated_le_requested` |

## checked-arithmetic

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-ARITH-CHECKED | P0 | PROVED | ALG | LEAN | `LidoSRv3.Audit.Quantity.checkedDiv_zero` |

## consolidation

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-CONSOLIDATION-E2E | P0 | BLOCKED | E2E | INTERFACE | `—` |

## cryptography

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-SHA256-PRECOMPILE | STRETCH | STRETCH | CRYPTO | NATIVE-FFI | `—` |

## economic-accounting

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-LEGACY-ECON | P0 | REGRESSION | MODEL | LEAN | `LidoSRv3.P1_reserve_separation` |

## runtime-correspondence

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-EVM-RUNTIME | P0 | BLOCKED | EVM | EVMYULLEAN | `—` |

## source-correspondence

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-SOLIDITY-CORR | P0 | OPEN | SRC | VERITY | `—` |

## toolchain-readiness

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-VERITY-431 | P1 | DEV-431-READY | SRC | VERITY | `—` |

## transaction-semantics

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-TX-REVERT | P0 | PROVED | TX | LEAN | `LidoSRv3.Audit.revert_restores_state_value_and_logs` |

## yul-interface

| ID | Priority | Status | Layer | Engine | Theorem |
| --- | --- | --- | --- | --- | --- |
| SRV3-YUL-COMP | P1 | OPEN | YUL | EVMYULLEAN | `—` |
