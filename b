#!/usr/bin/env bash
TARGETCPU=`fpc -iTP | head -n1`
TARGETOS=`fpc -iTO | head -n1`
FULLTARGET=$TARGETCPU-$TARGETOS
rm build-stamp.$FULLTARGET
make all NOWPOCYCLE=1
