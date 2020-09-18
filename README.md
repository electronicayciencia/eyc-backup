EyC Backup Script
=================

Download posts and images to tocal HTML files.

(sorry, some comments in spanish)

External commands
-----------------

 - xmlstarlet
 - wget
 - bash
 - perl



Parseo del feed
---------------

### Formatear doc

    xmlstarlet fo < electronicayciencia_feed_20200917.xml > feed.xml

### Seleccionar los títulos de todas las entradas

    cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v '/atom:feed/atom:entry/atom:title'

### Contar entradas

    cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v 'count(/atom:feed/atom:entry)'

### Seleccionar el título de la entrada 1

    cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v '/atom:feed/atom:entry[1]/atom:title'

### Seleccionar el título de una entrada cuyo Id es X

    cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" \
      -t -v '/atom:feed/atom:entry[atom:id="tag:blogger.com,1999:blog-1915800988134045998.post-3137022925002988466"]/atom:title'

O, también:

    cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" \
      -t -v '//atom:entry[atom:id="tag:blogger.com,1999:blog-1915800988134045998.post-3137022925002988466"]/atom:title'

### Contenido de una entrada particular en quoted HTML

    cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" \
	  -t -v '//atom:entry[atom:id="tag:blogger.com,1999:blog-1915800988134045998.post-3137022925002988466"]/atom:content' \
	  > content.raw

### Volcar contenido como HTML parseable:

    cat content.raw | \
	  xmlstarlet fo -D -R -H - | \
	  sed 's/&nbsp;/ /g' | \
	  xmlstarlet unesc | \
	  sed 's/&nbsp;/ /g' > content.html


### Buscar los videos

	cat content.html | xmlstarlet sel -H -t -v '//iframe[contains(@src, "youtube")]/@src'

### De una URL ($url), seleccionar el nombre final

    echo ${url##*/}

### Nombres normalizados

Los extraigo del link alternate:

    cat feed.xml |\
      xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v \
	  '/atom:feed/atom:entry/atom:link[@rel="alternate"]/@href'


    url=http://electronicayciencia.blogspot.com/2010/03/conversor-usb-rs232.html
    echo $url | cut -d '/' -f 4- | cut -d '.' -f 1
	# 2010/03/conversor-usb-rs232


Clases relevantes
-----------------

### Título

    <h3 class='post-title entry-title'>Sintetizador de frecuencias digital con PLL</h3>

### Contenido

    <div class='post-body entry-content'>
    ...
    </div>

### Foot (hacerlo invisible)

	<div class="blogger-post-footer">Las ecuaciones...</div>

### Etiquetas imágenes

    <td class="tr-caption" style="text-align: center;">


Plantillas
----------

Directorio /templates
 - /templates/header.html
 - /templates/footer.html

    header=$(cat templates/header.html)
    footer=$(cat templates/footer.html)
    content=$(xmlstarlet unesc < content82.raw)

    html=$(echo "$header $content $footer")



Imágenes
--------

### URL de las imágenes

Las imágenes tienen 2 URL, una reducida como src y la real en el link href.

Las imagenes reducidas (no las queremos para nada, pero son los tags IMG):

	cat content.html | xmlstarlet sel -H -t -v '//img/@src'

Las imágenes a tamaño real desde las reducidas:

	cat content.html | xmlstarlet sel -H -t -v '//img/@src/ancestor::a/@href'

Las imágenes más pequeñas no tienen versión original ni van dentro de un link.

Versión en HTML:

    http://4.bp.blogspot.com/_QF4k-mng6_A/S6eJByqfKZI/AAAAAAAAAAU/PN_WPKeqdz0/s1600-h/Imagen149.jpg

Versión en Imagen original (sin -h):

    http://4.bp.blogspot.com/_QF4k-mng6_A/S6eJByqfKZI/AAAAAAAAAAU/PN_WPKeqdz0/s1600/Imagen149.jpg

Sustituir la fuente de una imagen por la local:

    cat content82.html | xmlstarlet ed -u '//img[contains(@src, "/Imagen149.jpg")]/@src' -v 'img/Imagen149.jpg'


Cuando se parsea el contenido:
 - buscar urls dentro de img/src (low res)
 - descargar
 - buscar urls dentro de A ancestros de IMG (hi res)
 - eliminar el -h de los enlaces
 - descargar (sobrescribir anterior)




TODO
----

 - Fecha
 - Etiquetas
 - Ecuaciones
 - Código
 - estilo titulo
 - estilo image captions
 - tamaño imágenes


Problemas
---------

Cuando actualizo el link src de las fotos con xmlstarlet, los tags vacíos no se cierran bien. Algunas veces afecta al formato del texto. Prescindo de xmlstarlet para esta labor y usaré remplazo por rexeps de perl.


