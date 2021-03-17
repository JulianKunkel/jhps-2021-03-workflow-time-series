#!/bin/bash

for filename in *.xz; do
	echo "Decompressing ${filename}"
	xz -d "${filename}" 
done
