#!/usr/bin/env python3
"""Execute diagnostics, never add theorem axioms; no changes to package sources."""
from pathlib import Path
import json, subprocess, tempfile
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
P=ROOT/'.lake/packages/evmyul'
def run(args):
    print('COMMAND '+json.dumps(args),flush=True)
    subprocess.run(args,cwd=ROOT,check=True)
with tempfile.TemporaryDirectory(prefix='lido-topup-timing-ffi-') as directory:
    d=Path(directory);c=d/'ffi.c';lib=d/'ffi.dylib'
    setup=d/'ffi.setup.json'
    setup.write_text(json.dumps({'plugins':[],'package':'evmyul','options':{},'name':'EvmYul.FFI.ffi','isModule':False,'importArts':{},'dynlibs':[]}))
    run(['lake','env','lean','--root='+str(P),'--setup='+str(setup),'-c',str(c),str(P/'EvmYul/FFI/ffi.lean')])
    # Fresh native C objects using the platform C toolchain, then Lean wrappers.
    lean_prefix=subprocess.check_output(['lake','env','lean','--print-prefix'],cwd=ROOT,text=True).strip()
    objects=[]
    for i,source in enumerate([P/'EvmYul/FFI/ffi.c',P/'sha2/sha-256.c',P/'keccak256/sha3.c']):
        obj=d/('native'+str(i)+'.o');objects.append(str(obj))
        run(['cc','-fPIC','-I'+lean_prefix+'/include','-I'+str(P/'sha2'),'-I'+str(P/'keccak256'),'-c',str(source),'-o',str(obj)])
    run(['lake','env','leanc','-shared','-DLEAN_EXPORTING','-o',str(lib),str(c),*objects])
    run(['lake','env','lean','--load-dynlib='+str(lib),'audit/topup-timing-history/validation/diagnostics.lean'])
