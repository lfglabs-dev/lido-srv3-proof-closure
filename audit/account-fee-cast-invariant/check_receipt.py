#!/usr/bin/env python3
import argparse,hashlib,json,pathlib,subprocess
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=pathlib.Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--core',type=pathlib.Path,required=True);args=ap.parse_args()
r=json.loads((OUT/'receipt.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for p,h in r['artifacts'].items():assert sha(ROOT/p)==h,p
inputs=json.loads((OUT/'source-inputs.json').read_text())
for e in inputs['entries']:assert sha(ROOT/e['path'])==e['sha256'],e['path']
for name,pin in inputs['package_pins'].items():
 assert subprocess.check_output(['git','-C',str(ROOT/'.lake/packages'/name),'rev-parse','HEAD'],text=True).strip()==pin,name
assert subprocess.check_output(['git','-C',str(args.core),'rev-parse','HEAD'],text=True).strip()==r['core_pin']
for p,h in r['solidity_sources'].items():
 assert sha(args.core/p)==h,p
 body=subprocess.check_output(['git','-C',str(args.core),'show',r['core_pin']+':'+p])
 assert hashlib.sha256(body).hexdigest()==h,p
axioms=json.loads((OUT/'axioms.json').read_text());assert len(axioms)==13
assert all(set(a)<={'propext','Classical.choice','Quot.sound'} for a in axioms.values())
for log in ['build.log','public-build.log','tests.log']:
 assert 'error:' not in (OUT/log).read_text(),log
print(f"PASS: {len(r['artifacts'])} artifacts; 24 source identities; 11 pins; 13 axiom sets; 4 pinned Solidity files")
