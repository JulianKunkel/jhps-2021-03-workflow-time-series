#!/bin/bash

for filename in *.xz; do
	echo "Decompressing ${filename}"
	tar -xJf "${filename}" 
done
