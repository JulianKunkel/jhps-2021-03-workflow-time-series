#!/bin/bash

# call me from the parent directory

echo "This script performs the complete analysis steps, it must be called from the workdir root"

CLEAN=0 # Set to 0 to make some update

mkdir fig
./scripts/plot-job-timelines-ks.py 4296426,5024292,7488914 fig/job,fig/job,fig/job

for I in datasets/job_similarities_*.csv ; do
  rm *.png *.pdf
  echo "processing $I"
	set -x
	./scripts/plot.R $I > description.txt 2>&1
	set +x
  I=${I##datasets/}
  OUT=fig/${I%%.csv}-out
  mkdir $OUT
  if [[ $CLEAN != "0" ]] ; then
    rm $OUT/*
  fi
  mv description.txt *.png *.pdf jobs-*.txt $OUT
done

# analyze performance data

for I in datasets/progress_*.csv ; do
  OUT=fig/$(basename ${I%%.csv}-out)
  ./scripts/plot-performance.R $I $OUT
done
