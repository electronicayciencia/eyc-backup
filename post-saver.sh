#!/bin/bash

# EyC Post Saver. Electronicayciencia 2020-09-18

# Download post and images from my blog
CONTENT=content1.html

DIR_IMG=img

mkdir -p $DIR_IMG

# Download low res images:
for url in $(cat $CONTENT | xmlstarlet sel -H -t -v '//img/@src')
do
  filename=${url##*/}
  echo "Downloading (low res) $filename..."

  wget -q "$url" -O "$DIR_IMG/$filename"
done


# Overwrite files with hi res when available
for url in $(cat $CONTENT | xmlstarlet sel -H -t -v '//img/@src/ancestor::a/@href')
do
  filename=${url##*/}
  echo "Downloading (hi res)  $filename..."

  # take original instead html version
  url=$(echo $url | sed 's|\(s[0-9]\+\)-h|\1|')

  wget -q "$url" -O "$DIR_IMG/$filename"
done
