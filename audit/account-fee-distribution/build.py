#!/usr/bin/env python3
from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[2]
subprocess.run(['lake','build','LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit','Tests.Verity.ReportFeeCheckedSplitTest'],cwd=ROOT,check=True)
for module,path in [
('FeeDistribution','audit/trio/account-address/FeeDistribution.lean'),
('ReportFeeDistribution','audit/trio/account-address/ReportFeeDistribution.lean'),
('LidoSRv3.Audit.Guarantees.PAccount1FeeDistribution','LidoSRv3/Audit/Guarantees/PAccount1FeeDistribution.lean'),
('Tests.Verity.ReportFeeDistributionTest','audit/trio/account-address/Tests/Verity/ReportFeeDistributionTest.lean')]:
    out=Path('.lake/build/lib/lean')/module.replace('.','/');(ROOT/out).parent.mkdir(parents=True,exist_ok=True)
    print('CHECK '+path,flush=True)
    subprocess.run(['lake','env','lean','-o',str(out)+'.olean','-i',str(out)+'.ilean',path],cwd=ROOT,check=True)
print('PASS: existing prerequisites and four new modules; no registration file edits.',flush=True)
