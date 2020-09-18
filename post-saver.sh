#!/bin/bash

# EyC Post Saver. Electronicayciencia 2020-09-18

# Download post and images from my blog


set -e

FEEDFILE=feed.xml
IMGDIR=img
TEMPLATEDIR=templates
WGET_CMD="wget -q"

for id in $(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v '//atom:entry/atom:id')
do

	# Get the title
	title=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "/atom:feed/atom:entry[atom:id='$id']/atom:title")
	echo "Processing '$title'..."

	# Get entry directory
	url=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:entry[atom:id='$id']/atom:link[@rel='alternate']/@href")
	entrydir=$(echo $url | cut -d '/' -f 4- | cut -d '.' -f 1)
	echo "    Dir: $entrydir"


	# Get raw content
	rawcontent=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:entry[atom:id='$id']/atom:content")

	# Unescape content
	content=$(echo $rawcontent | xmlstarlet unesc | sed 's/&nbsp;/ /g')
	
	# Add headers and foot
	header=$(cat $TEMPLATEDIR/header.html)
	footer=$(cat $TEMPLATEDIR/footer.html)

	# Add title
	htmltitle="<h3 class='post-title entry-title'>$title</h3>"

	# Mix up
	html="$header $htmltitle $content $footer"

	
	# Create dirs
	mkdir -p "$entrydir"
	mkdir -p "$entrydir/$IMGDIR"


	# Write HTML
	echo $html > "$entrydir/index.html"


	# Download images (low res)
	cp "$entrydir/index.html" "$entrydir/index.wip"

	for url in $(cat $entrydir/index.html | xmlstarlet sel -H -t -v '//img/@src')
	do
		filename=${url##*/}
		echo "    Downloading (low res) $filename..."

		$WGET_CMD "$url" -O "$entrydir/$IMGDIR/$filename"
		perl -pi -e "s|src=\"[^\"]+/$filename\"|src=\"$IMGDIR/$filename\"|g" "$entrydir/index.wip"
	done


	# Download images (hi res)
	for url in $(cat $entrydir/index.html | xmlstarlet sel -H -t -v '//img/@src/ancestor::a/@href')
	do
		filename=${url##*/}
		echo "    Downloading (hi res)  $filename..."

		# take original instead html version
		url=$(echo $url | sed 's|\(s[0-9]\+\)-h|\1|')

		$WGET_CMD "$url" -O "$entrydir/$IMGDIR/$filename"
		perl -pi -e "s|href=\"[^\"]+/$filename\"|href=\"$IMGDIR/$filename\"|g" "$entrydir/index.wip"
	done


	mv -f "$entrydir/index.wip" "$entrydir/index.html"


	exit
done


exit






