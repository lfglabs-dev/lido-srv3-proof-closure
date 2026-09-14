#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-}" in
  topup-source) test_script=scripts/test_topup_source_differential.sh ;;
  reserve-source) test_script=scripts/test_reserve_source_differential.sh ;;
  repository) test_script=repository ;;
  *) echo 'expected topup-source, reserve-source or repository' >&2; exit 2 ;;
esac

bash scripts/prepare_trio_validation.sh
export PATH="$PWD/.lake/trio-tools/foundry-v1.3.1:$PWD/.lake/trio-tools/ripgrep-14.1.1:$PATH"

# Select an explicit, checksum-pinned compiler in this private checkout. This
# avoids Foundry installing compilers into a shared runner's SVM directory.
# ARM64 uses the same upstream build repository selected by svm-rs for 0.8.25.
case "$(uname -m)" in
  aarch64|arm64)
    solc_url=https://raw.githubusercontent.com/nikitastupin/solc/2287d4326237172acf91ce42fd7ec18a67b7f512/linux/aarch64/solc-v0.8.25
    solc_digest=a23ef0c336c32b9b2d9ef5cbca0ef79b4b199606640d778522f027f64bc0e5cb
    ;;
  x86_64)
    solc_url=https://raw.githubusercontent.com/ethereum/solc-bin/gh-pages/linux-amd64/solc-linux-amd64-v0.8.25+commit.b61c2a91
    solc_digest=c42aada7a52057ddbed93ec011235e256c564c440b68dbaac5ae482babbb3d6d
    ;;
  *) echo 'unsupported compiler architecture' >&2; exit 1 ;;
esac
export FOUNDRY_SOLC="$PWD/.lake/trio-tools/solc-0.8.25"
if [[ ! -f "$FOUNDRY_SOLC" ]]; then
  curl --fail --location --retry 3 --connect-timeout 20 --max-time 300 \
    "$solc_url" --output "$FOUNDRY_SOLC.part"
  mv "$FOUNDRY_SOLC.part" "$FOUNDRY_SOLC"
fi
printf '%s  %s\n' "$solc_digest" "$FOUNDRY_SOLC" | sha256sum --check --strict
chmod u+x "$FOUNDRY_SOLC"
"$FOUNDRY_SOLC" --version
if [[ "$test_script" == repository ]]; then
  mkdir -p .lake/candidate-validation
  combined_status=0
  proof_report_ready=0
  if make prove 2>&1 | tee .lake/candidate-validation/prove.log; then
    echo 'CANDIDATE_MAKE_PROVE=PASS'
    proof_report_ready=1
  else
    combined_status=1
    echo 'CANDIDATE_MAKE_PROVE=FAIL'
  fi
  if make test 2>&1 | tee .lake/candidate-validation/test.log; then echo 'CANDIDATE_MAKE_TEST=PASS'; else
    combined_status=1
    echo 'CANDIDATE_MAKE_TEST=FAIL'
  fi
  if lake build LidoSRv3 LidoSRv3Audit LidoSRv3Test AccountAddressChecks 2>&1 | tee .lake/candidate-validation/libraries.log; then echo 'CANDIDATE_LIBRARIES=PASS'; else
    combined_status=1
    echo 'CANDIDATE_LIBRARIES=FAIL'
  fi
  echo 'CANDIDATE_GATE_DIAGNOSTICS_BEGIN'
  # Retain compiler failures and differential totals at the end of bounded
  # remote receipt tails, after verbose Trust axiom output.
  rg -n -A 5 '^error:|Traceback|failed:|AssertionError|Suite result:|^make:.*Error' \
    .lake/candidate-validation/{prove,test,libraries}.log | tail -160 || true
  echo 'CANDIDATE_GATE_DIAGNOSTICS_END'
  if [[ "$proof_report_ready" == 1 ]]; then
    echo 'CANDIDATE_PROOF_REPORT_BEGIN'
    cat proofs/logs/proof-report.json
    echo 'CANDIDATE_PROOF_REPORT_END'
  fi
  exit "$combined_status"
else
  bash "$test_script"
fi
