#!/bin/bash

# EyC Post Saver. Electronicayciencia 2020-09-18
# Download post and images from my blog

# Yes, it is shell script. Problem?

FEEDFILE=feed.xml

set -e # check for errors
set -u # check for unbound var

MAINFILE=articulo.html
IMGDIR=img
TEMPLATEDIR=templates
WGET_CMD="wget -q"
INDEX=articulos.html


# Sanitize file names:
# IT%2Bvs%2BITNCP.png -> IT-vs-ITNCP.png
# Wave_packet_%2528dispersion%2529.gif -> Wave_packet_-dispersion-.gif
function url2file { echo $* | sed 's/%25/%/g; s/%../-/g'; }

# Convert Blog link to local directory
# http://electronicayciencia.blogspot.com/2018/10/la-presion-atmosferica-bmp280.html -> 2018/10/la-presion-atmosferica-bmp280
function url2entrydir { echo $* | cut -d '/' -f 4- | cut -d '.' -f 1; }

index=""

for id in $(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v '//atom:entry/atom:id')
do
	# Get the title
	title=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "/atom:feed/atom:entry[atom:id='$id']/atom:title")
	echo "Processing '$title'..."

	# Get entry directory
	url=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:entry[atom:id='$id']/atom:link[@rel='alternate']/@href")
	entrydir=$(url2entrydir $url)
	echo "    Directory: $entrydir"


	# Create dirs
	mkdir -p "$entrydir"
	mkdir -p "$entrydir/$IMGDIR"


	# Get raw content
	rawcontent=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:entry[atom:id='$id']/atom:content")

	# Unescape content
	content=$(echo $rawcontent | xmlstarlet unesc | sed 's/&nbsp;/ /g')
	htmlcontent="<div class='post-body entry-content'>$content</div>"

	# Correct some content's shit to please xmlstarlet
	htmlcontent=${htmlcontent//allowfullscreen>/allowfullscreen=\"true\">}

	# Add headers and foot
	header_top=$(cat $TEMPLATEDIR/header_top.html)
	header_bot=$(cat $TEMPLATEDIR/header_bottom.html)
	footer=$(cat $TEMPLATEDIR/footer.html)

	# Add title
	htmltitle="<h3 class='post-title entry-title'>$title</h3>"
	pagetitle="<title>$title</title>"

	# Add date
	fecha=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:feed/atom:entry[atom:id='$id']/atom:published")
	fechafmt=$(date +'%d-%m-%Y' -d $fecha)
	htmldate="<div class='post-date'>Publicado el $fechafmt.</div>"

	# Add tags (unorderer list)
	cats=$(cat $FEEDFILE | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:feed/atom:entry[atom:id='$id']/atom:category/@term")
	cats=$(echo $cats | sed 's| |</li><li>|g')
	htmltags="<div class='post-labels'>Etiquetas: <ul><li>$cats</li></ul></div>"

	# Mix up
	html=""
	html+=$header_top
	html+=$pagetitle
	html+=$header_bot
	html+=$htmltitle
	html+=$htmldate
	html+=$htmlcontent
	html+=$htmltags
	html+=$footer

	
	# Write HTML
	echo $html > "$entrydir/$MAINFILE"

	# Begin replacing works
	#   WIP: work in progress
	#   HTML: original file
	cp "$entrydir/$MAINFILE" "$entrydir/$MAINFILE.wip"

	# Download images (low res) (only blogspot)
	for url in $(cat $entrydir/$MAINFILE | xmlstarlet sel -H -t -v '//img[contains(@src,"blogspot")]/@src')
	do
		filename_remote=${url##*/}
		filename_local=$(url2file $filename_remote)

		echo "    Downloading (low res) $filename_local..."

		#$WGET_CMD "$url" -O "$entrydir/$IMGDIR/$filename_local"
		
		# replace link (xmlstarlet is far less tolerant)
		perl -pi -e "s|src=\"[^\"]+/$filename_remote\"|src=\"$IMGDIR/$filename_local\"|g" "$entrydir/$MAINFILE.wip"
	done


	# Download images (hi res) (only blogspot)
	for url in $(cat $entrydir/$MAINFILE | xmlstarlet sel -H -t -v '//img[contains(@src,"blogspot")]/@src/ancestor::a/@href')
	do
		filename_remote=${url##*/}
		filename_local=$(url2file $filename_remote)

		echo "    Downloading (hi res)  $filename_local..."

		# take original instead html version (remove -h from /sXXXX-h/ path)
		url=$(echo $url | sed 's|\(s[0-9]\+\)-h|\1|')

		#$WGET_CMD "$url" -O "$entrydir/$IMGDIR/$filename_local"

		# replace link (xmlstarlet is far less tolerant)
		perl -pi -e "s|href=\"[^\"]+/$filename_remote\"|href=\"$IMGDIR/$filename_local\"|g" "$entrydir/$MAINFILE.wip"
	done


	# Replace absolute links to other posts with its relative version
	# Change it if you change domain blog, of local entry directory
	perl -pi -e "s|https?://electronicayciencia.blogspot.com/(.*?).html|../../../\$1/$MAINFILE|g" "$entrydir/$MAINFILE.wip"

	# Remove footer feed message
	perl -pi -e 's|<div[^>]+blogger-post-footer.*?</div>||g' "$entrydir/$MAINFILE.wip"

	# Remove images fixed width and heigth
	perl -pi -e 's/(<img.*?)\s+width[^\s]+\s+(.*?>)/$1 $2/g' "$entrydir/$MAINFILE.wip"
	perl -pi -e 's/(<img.*?)\s+height[^\s]+\s+(.*?>)/$1 $2/g' "$entrydir/$MAINFILE.wip"
	
	# Remove iframes fixed width and heigth
	perl -pi -e 's/(<iframe.*?)\s+width[^\s]+\s+(.*?>)/$1 $2/g' "$entrydir/$MAINFILE.wip"
	perl -pi -e 's/(<iframe.*?)\s+height[^\s]+\s+(.*?>)/$1 $2/g' "$entrydir/$MAINFILE.wip"

	# Done replacing. File ready.
	mv -f "$entrydir/$MAINFILE.wip" "$entrydir/$MAINFILE"


	# Add to the index
	index+="<p><a class='index-entry' href="$entrydir/$MAINFILE">$title</a></p>"

#	exit

done

echo "<div class='index'>$index</div>" > $INDEX


