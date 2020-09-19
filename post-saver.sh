#!/bin/bash

# EyC Post Saver. Electronicayciencia 2020-09-18
# Download post and images from my blog

# Yes, it is shell script. Problem?

FEEDFILE=feed.xml

set -e

IMGDIR=img
TEMPLATEDIR=templates
WGET_CMD="wget -q"


# Sanitize file names:
# IT%2Bvs%2BITNCP.png -> IT-vs-ITNCP.png
# Wave_packet_%2528dispersion%2529.gif -> Wave_packet_-dispersion-.gif
function url2file { echo $* | sed 's/%25/%/g; s/%../-/g'; }


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

	# Add date
	fecha=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:feed/atom:entry[atom:id='$id']/atom:published")
	fechafmt=$(date +'%d-%m-%Y' -d $fecha)
	htmldate="<div class='post-date'>$fechafmt</div>"

	# Add tags (unorderer list)
	cats=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:feed/atom:entry[atom:id='$id']/atom:category/@term")
	cats=$(echo $cats | sed 's| |</li><li>|g')
	htmltags="<div class='post-tags'><ul><li>$cats</li></ul></div>"

	# Mix up
	html="$header $htmltitle $htmldate $htmltags $content $footer"

	
	# Create dirs
	mkdir -p "$entrydir"
	mkdir -p "$entrydir/$IMGDIR"


	# Write HTML
	echo $html > "$entrydir/index.html"


	# Download images (low res)
	cp "$entrydir/index.html" "$entrydir/index.wip"

	for url in $(cat $entrydir/index.html | xmlstarlet sel -H -t -v '//img/@src')
	do
		filename_remote=${url##*/}
		filename_local=$(url2file $filename_remote)

		echo "    Downloading (low res) $filename_local..."

		$WGET_CMD "$url" -O "$entrydir/$IMGDIR/$filename_local"
		
		# replace link (xmlstarlet is far less tolerant)
		perl -pi -e "s|src=\"[^\"]+/$filename_remote\"|src=\"$IMGDIR/$filename_local\"|g" "$entrydir/index.wip"
	done


	# Download images (hi res)
	for url in $(cat $entrydir/index.html | xmlstarlet sel -H -t -v '//img/@src/ancestor::a/@href')
	do
		filename_remote=${url##*/}
		filename_local=$(url2file $filename_remote)

		echo "    Downloading (hi res)  $filename_local..."

		# take original instead html version (remove -h from /sXXXX-h/ path)
		url=$(echo $url | sed 's|\(s[0-9]\+\)-h|\1|')

		$WGET_CMD "$url" -O "$entrydir/$IMGDIR/$filename_local"

		# replace link (xmlstarlet is far less tolerant)
		perl -pi -e "s|href=\"[^\"]+/$filename_remote\"|href=\"$IMGDIR/$filename_local\"|g" "$entrydir/index.wip"
	done


	mv -f "$entrydir/index.wip" "$entrydir/index.html"

done



