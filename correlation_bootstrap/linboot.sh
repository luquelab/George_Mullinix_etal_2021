#!/usr/bin/env bash

dir=$(pwd)
file_in=$1
cd ../docker
make run-linboot $dir/$file_in 0.05
for f in $(ls $file_in*); do
	cp $f $dir;
done

