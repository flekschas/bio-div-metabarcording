#!/bin/bash

DIR=$(echo "$1" | perl -nle 'm/(.+)\/([^\/]+)\.txt$/; print $1')
FILENAME=$(echo "$1" | perl -nle 'm/([^\/]+)\.txt$/; print $1')

sed 's/#Datasets/taxa/' < $1 > "$DIR/$FILENAME.tmp.txt"

rm $1
mv "$DIR/$FILENAME.tmp.txt" $1