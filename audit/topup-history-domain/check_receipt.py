#!/usr/bin/env python3
import json,hashlib,subprocess
from pathlib import Path
here=Path(__file__).resolve().parent
root=here.parent.parent
rec=json.loads((here/'receipt.json').read_text());deps=json.loads((here/'dependency-inputs.json').read_text());errors=[];checks=0
for path,want in {**rec['validated_inputs'],**rec['evidence_hashes']}.items():
 checks+=1;p=root/path
 if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=want:errors.append(path)
for e in deps['package_source_closure']:
 checks+=1;p=root/e['path']
 if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=e['sha256']:errors.append(e['path'])
for path,want in rec['package_pins'].items():
 checks+=1
 if subprocess.check_output(['git','-C',str(root/path),'rev-parse','HEAD'],text=True).strip()!=want:errors.append('pin:'+path)
prefix=Path(subprocess.check_output(['lake','env','lean','--print-prefix'],cwd=root,text=True).strip())/'src/lean'
for path,want in deps['selected_core_sources'].items():
 checks+=1
 if hashlib.sha256((prefix/path).read_bytes()).hexdigest()!=want:errors.append('core:'+path)
print(json.dumps({'scope':'Source and pin comparisons only; no proof or EVM execution','checks':checks,'errors':errors},indent=2))
raise SystemExit(bool(errors))
