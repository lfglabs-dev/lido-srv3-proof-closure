#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
cc -dynamiclib -Wl,-all_load .lake/packages/evmyul/.lake/build/lib/libleanffi.a \
  .lake/packages/evmyul/.lake/build/ir/EvmYul/FFI/ffi.c.o.export \
  -Wl,-undefined,dynamic_lookup -o audit/address-actual-consumer/libaddressffi.dylib
lake env lean --load-dynlib=./audit/address-actual-consumer/libaddressffi.dylib \
  --run audit/address-actual-consumer/RuntimeRegression.lean
