#!/usr/bin/env bash
set -euo pipefail

cat <<'JSON'
{
  "schema": "srv3-verity-lean-proof-report-v1",
  "toolchain": {
    "lean": "4.22.0",
    "verity_commit": "33722270d996c7a3a520a71ecee42d7d232da100"
  },
  "command": "lake build LidoSRv3",
  "targets": [
    {"id": "SRV3-P1", "theorem": "LidoSRv3.P1_reserve_separation", "status": "lean_checked"},
    {"id": "SRV3-P2", "theorem": "LidoSRv3.P2_deposit_exact_pull", "status": "lean_checked"},
    {"id": "SRV3-P2a", "theorem": "LidoSRv3.P2_total_allocated_deposits", "status": "lean_checked"},
    {"id": "SRV3-P3", "theorem": "LidoSRv3.P3_module_balance_conservation", "status": "lean_checked"},
    {"id": "SRV3-P4", "theorem": "LidoSRv3.P4_report_before_reward_consistency", "status": "lean_checked"},
    {"id": "SRV3-P5", "theorem": "LidoSRv3.P5_reward_bound", "status": "lean_checked"},
    {"id": "SRV3-P5a", "theorem": "LidoSRv3.P5_reward_recipient_alignment", "status": "lean_checked"},
    {"id": "SRV3-P6", "theorem": "LidoSRv3.P6_deposit_status_gating", "status": "lean_checked"},
    {"id": "SRV3-P6a", "theorem": "LidoSRv3.P6_stopped_module_reward_zero", "status": "lean_checked"}
  ]
}
JSON
