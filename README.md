[Ir a listado de artículos del Blog Electronica Y Ciencia](articulos.html)


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
 - tidy



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


Categorías
----------

    cats=$(cat feed.xml | xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v '/atom:feed/atom:entry[atom:id="tag:blogger.com,1999:blog-1915800988134045998.post-3137022925002988466"]/atom:category/@term')

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

 - estilo Fecha
 - estilo Etiquetas
 - estilo Ecuaciones
 - estilo Código
 - estilo titulo
 - estilo image captions
 - tamaño imágenes
 - crear indice
 - añadir imagen y descripción en el indice
 - imagen de fondo

Problemas
---------

Cuando actualizo el link src de las fotos con xmlstarlet, los tags vacíos no se cierran bien. Algunas veces afecta al formato del texto. Prescindo de xmlstarlet para esta labor y usaré remplazo por rexeps de perl.

Imágenes embebidas desde spreadsheet no funcionan. De momento las omitimos.

resonancia-mecanica-con-copas-ii/articulo.html -> las imágenes salen más grandes de lo que son en realidad.

Al hacer el tidy:
2017/12/describiendo-un-protocolo-desconocido/articulo.html
"encontramos cadenas como: <em>Se<f1>or@s Buenas\nTardes</f1></em>. La ñ está codificada como f1, es"
el f1 era literal, no tendría que haberse usado como tag
Estaba en el original así. Lo corrijo. Falta volver a descargar el feed y verificar.

En 2013/03/la-distorsion-armonica-total-thd:
En 2010/07/difraccion-en-un-dvd:
 line 5 column 15645 - Error: <k> is not recognized!

En 2010/05/preamplificador-microfono-electret
  line 5 column 14481 - Error: <factor> is not recognized!

En 2016/12/el-bus-1-wire-bajo-nivel:
  line 5 column 1244 - Error: <break> is not recognized!
