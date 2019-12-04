#!/bin/bash
INTERVALS=$1
PROBABILITIES=$2
paste $INTERVALS $PROBABILITIES > unsorted.bedGraph
sort -k1,1 -k2,2n unsorted.bedGraph > sorted.bedGraph
rm unsorted.bedGraph