<!-- GENERATED from audit/invariants.yaml; NOT EDITABLE TRUTH. -->
# Reproduction commands

## SRV3-ALLOC-ORDER

```sh
lake env lean LidoSRv3/Audit/Trust.lean
```

## SRV3-ARITH-CHECKED

```sh
lake env lean LidoSRv3/Audit/Trust.lean
```

## SRV3-CONSOLIDATION-E2E

```sh
python3 scripts/audit_registry.py check
```

## SRV3-EVM-RUNTIME

```sh
python3 scripts/audit_registry.py check
```

## SRV3-LEGACY-ECON

```sh
lake build LidoSRv3
```

## SRV3-MINFIRST-BOUND

```sh
lake build LidoSRv3.Audit.Vectors
```

## SRV3-SHA256-PRECOMPILE

```sh
python3 scripts/audit_registry.py check
```

## SRV3-SOLIDITY-CORR

```sh
python3 scripts/audit_registry.py check
```

## SRV3-TX-REVERT

```sh
lake env lean LidoSRv3/Audit/Trust.lean
```

## SRV3-VERITY-431

```sh
python3 scripts/audit_registry.py check
```

## SRV3-YUL-COMP

```sh
python3 scripts/audit_registry.py check
```
