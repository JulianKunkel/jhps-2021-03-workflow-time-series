#!/bin/bash
pushd ./datasets
./decompress.sh
popd   
pushd ./evaluation
./decompress.sh
popd
