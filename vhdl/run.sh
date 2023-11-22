#!/bin/bash

set -e
cd "$( dirname "${BASH_SOURCE[0]}" )"

rm -rf build-tb
mkdir -p build-tb
cd build-tb

WORK="xorminator"
RTLFILES=(
    "xorminator_pck"
    "xorminator_internals_pck"
    "xorminator_lite"
    "xorminator_full"
    "xorminator_ctrl"
    "xorminator_source"
    "xorminator_postproc_lite"
    "xorminator_postproc_full"
    "xorminator_selftest_lite"
    "xorminator_selftest_full"
)
TBFILES=(
)
TESTBENCHES=(
    "xorminator_source_tb"
    "xorminator_lite_tb"
    "xorminator_full_tb"
)

echo "Processing RTL files ..."

echo "- Compiling unisim_stubs ..."
ghdl -a --work=unisim ../rtl/unisim_stubs.vhd

for FILE in "${RTLFILES[@]}"; do

    echo "- Compiling ${FILE} ..."
    ghdl -a --work=${WORK} ../rtl/${FILE}.vhd

done

echo "Processing TB files ..."

for FILE in "${TBFILES[@]}"; do

    echo "- Compiling ${FILE} ..."
    ghdl -a --work=${WORK} ../tb/${FILE}.vhd

done

echo "Processing testbenches ..."

for FILE in "${TESTBENCHES[@]}"; do

    echo "- Compiling ${FILE} ..."
    ghdl -a --work=${WORK} ../tb/${FILE}.vhd
    ghdl -e --work=${WORK} ${FILE}

    echo "- Running ${FILE} ..."
    ghdl -r --work=${WORK} ${FILE} --wave=${FILE}.ghw --ieee-asserts=disable-at-0

done
