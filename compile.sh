#!/bin/sh

mkdir -p ./tmp
mkdir -p ./public

for file in $(ls ./content)
do
    file=$(basename $file .md)
    cmark-gfm --extension table ./content/$file.md > ./tmp/$file.html
    sed '/CONTENT/{
        s/CONTENT//g
        r tmp/'$file'.html
    }' template.html > ./public/$file.html
done
