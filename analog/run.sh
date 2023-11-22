#!/bin/bash

set -e

for I in {0..15}; do
    ngspice -b -r data/xorminator_source_$I.raw -o data/xorminator_source.log xorminator_source.sp
done
