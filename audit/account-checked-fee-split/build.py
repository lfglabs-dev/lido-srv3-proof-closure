#!/usr/bin/env python3
"""Build exact local candidates without changing root registration files."""
import pathlib, subprocess
ROOT=pathlib.Path(__file__).resolve().parents[2]
subprocess.run(['lake','build','LidoSRv3.Audit.Guarantees.PAccount1ActualFeeCasts','Tests.Verity.ReportFeeMintTest'],cwd=ROOT,check=True)
modules=[
('ReportFeeCheckedSplit','audit/trio/account-address/ReportFeeCheckedSplit.lean'),
('LidoSRv3.Audit.Guarantees.PAccount1CheckedFeeSplit','LidoSRv3/Audit/Guarantees/PAccount1CheckedFeeSplit.lean'),
('Tests.Verity.ReportFeeCheckedSplitTest','audit/trio/account-address/Tests/Verity/ReportFeeCheckedSplitTest.lean')]
for module,path in modules:
    out=pathlib.Path('.lake/build/lib/lean')/module.replace('.','/')
    (ROOT/out).parent.mkdir(parents=True,exist_ok=True)
    print('CHECK '+path,flush=True)
    subprocess.run(['lake','env','lean','-o',str(out)+'.olean','-i',str(out)+'.ilean',path],cwd=ROOT,check=True)
print('PASS: inherited targets plus all three new modules compiled; no global registration files changed.',flush=True)
