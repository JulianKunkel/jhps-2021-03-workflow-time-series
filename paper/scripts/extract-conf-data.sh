#!/bin/bash

if [[ ! -e datasets/job_metadata_confidential.csv ]] ; then
  exit 0
fi

# This script extracts the actual usernames and job-informations
# As it is confidential information, we cannot include these metadata files

for I in $@ ; do
  DATA=$(grep $I datasets/job_metadata.csv | cut -d "," -f 7-)
  echo -n $I,
  if [[ "$DATA" == "" ]] ; then
    echo "No data found"
    continue
  fi
  grep $DATA datasets/job_metadata_confidential.csv | cut -d "," -f 1-5
done
