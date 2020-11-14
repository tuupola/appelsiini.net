---
title: Google Maps Without JavaScript Part 2
date: 2008-06-04
tags:
  - PHP
  - Maps
---

![Static Maps](/img/2008/tartu.png)

In&nbsp;[previous part](http://www.appelsiini.net/2008/5/google-maps-without-javascript) we made a Google Map with sidebar navigation which works even JavaScript turned off. Marker locations and sidebar were parsed from two KML files. [Beginning Google Maps Applications](http://googlemapsbook.com/) is a great book to learn about KML and Google Maps in general.

In this second part of tutorial I show you how to add zoom and pan controls. Again, they work without JavaScript. Be sure to read tutorial part one first. Also check the [live demo](http://www.appelsiini.net/demo/google_maps_nojs/enabled.html).

<!--more-->

Before going forward I would like to answer a question which has been asked more than once:

Q: *What is the point?*<br />
A: Two reasons. Websites should degrade gracefully. Page should still have understandable content even if JavaScript is turned off. Second reason is just because it is cool.

### Add controls to static map

First we add arrows and plus and minus images on a separate layer. This layer is positioned over the static map. I use Google provided images. Mapki has list of all [available images](http://mapki.com/wiki/Available_Images).

Note! In example code I use only filenames as source attribute. Full address would not fit to screen.

``` html
<div id="map" style="width:512px; height:300px">
  <img src="<?php print $current_map ?>" />
  <div id="controls">
    <a href=""><img src="north-mini.png" id="pan_up" /></a>
    <a href=""><img src="west-mini.png" id="pan_left" /></a>
    <a href=""><img src="east-mini.png" id="pan_right" /></a>
    <a href=""><img src="south-mini.png" id="pan_down" /></a>
    <a href=""><img src="zoom-plus-mini.png" id="zoom_in" /></a>
    <a href=""><img src="zoom-minus-mini.png" id="zoom_out" /></a>
  </div>
</div>
```

Did you notice the <code>$current\_map</code> variable? It is Google Static Maps address constructed with PHP. I use [Net_URL](http://pear.php.net/package/net_url) class to build the address. It makes altering the query string later much easier. Address for current static map is built with following code:

``` php
/* Build the URL's for Static Maps API. */
$url = new Net_URL('http://maps.google.com/staticmap');
$url->addQueryString('center',  $_GET['center']);
$url->addQueryString('zoom',    $_GET['zoom']);
$url->addQueryString('markers', $_GET['markers']);
$url->addQueryString('size',   '512x300');
$url->addQueryString('key',     $api_key);

$current_map = $url->getUrl();
```

### Make zoom buttons work

To make zoom buttons work we need to create two URL addresses. First with <code>zoom</code> parameter one smaller than current. Second with zoom level one larger than current. Maximum zoom level is 17. Minimum zoom level is 1.

``` php
/* Create query strings for + and - buttons. */
$url->addQueryString('zoom', min(17, $_GET['zoom'] + 1));
$zoom_in = $url->getQueryString();

$url->addQueryString('zoom', max(1, $_GET['zoom'] - 1));
$zoom_out = $url->getQueryString();
</code>
```

Note that we store only query string to <code>$zoom\_in</code> and <code>$zoom\_out</code> parameter. Full address is not needed. These query strings are then used as links for zoom in and zoom out controls.

``` html
<a href="?<?php print $zoom_in ?>"><img src="zoom-plus-mini.png" id="zoom_in" /></a>
<a href="?<?php print $zoom_out ?>"><img src="zoom-minus-mini.png" id="zoom_out"
```

### Make pan buttons work

Pan buttons are bit more trickier. Map is positioned using *center* parameter containing latitude and longitude. Lets assume we want to pan map 100 pixels right. For that we need to do following things.

1. Calculate current center longitude as pixels.
2. Add 100 pixels to it.
3. Calculate new pixel value as longitude.
4. Pass new longitude to Static Maps API in <code>center</code> parameter.

Latitude and longitude to pixels conversions are done using some [Mercator projection](http://en.wikipedia.org/wiki/Mercator_projection) magic. I do not claim I understand it. Quite frankly, I don't. Thanks to Bratliff from Google Maps API mailinglist who pointed me to some [JavaScript mercator code](http://www.polyarc.us/adjust.js). I used this as a basis and ported the functions to PHP.

Using the freshly created [Google Maps PHP class](https://github.com/tuupola/php_google_maps) we can calculate new latitudes and longitudes for each panning direction. Note! In example we move map 60 pixels vertically and 100 pixels horizontally.

``` php
list($lat, $lon) = explode(',', $_GET['center']);

/* Calculate new latitudes and longtitudes for each arrow. */
$lat_up    = Google_Maps::adjustLatByPixels($lat, -60,  $_GET['zoom']);
$lat_down  = Google_Maps::adjustLatByPixels($lat,  60,  $_GET['zoom']);
$lon_left  = Google_Maps::adjustLonByPixels($lon, -100, $_GET['zoom']);
$lon_right = Google_Maps::adjustLonByPixels($lon,  100, $_GET['zoom']);
```

Next we put new <code>center</code> parameter into query string. Each direction is stored into separate parameter.

``` php
/* Make query strings out of them. */
$url->addQueryString('center', "$lat_up,$lon");
$pan_up    = $url->getQueryString();

$url->addQueryString('center', "$lat_down,$lon");
$pan_down  = $url->getQueryString();

$url->addQueryString('center', "$lat,$lon_left");
$pan_left  = $url->getQueryString();

$url->addQueryString('center', "$lat,$lon_right");
$pan_right = $url->getQueryString();
```

These query strings are later used as links for panning controls.

``` php
<a href="?<?php print $pan_up ?>"><img src="north-mini.png" id="pan_up" /></a>
<a href="?<?php print $pan_left ?>"><img src="west-mini.png" id="pan_left" /></a>
<a href="?<?php print $pan_right ?>"><img src="east-mini.png" id="pan_right" /></a>
<a href="?<?php print $pan_down ?>"><img src="south-mini.png" id="pan_down" /></a>
```

Now we have non JavaScript map with working sidebar, zoom and panning. Info windows (bubbles) are still missing. Lets leave that for part 3. You can find source [code](http://svn.appelsiini.net/viewvc/javascript/trunk/google_maps_nojs/) to the [working demo](http://www.appelsiini.net/demo/google_maps_nojs/enabled.html) from svn.

Related entries: [Google Maps Without JavaScript Part 1](https://appelsiini.net/2008/google-maps-without-javascript/), [Clickable Markers With Google Static Maps](https://appelsiini.net/2008/clickable-markers-with-google-static-maps/), [Infowindows With Google Static Maps](https://appelsiini.net/2008/infowindows-with-google-static-maps/).
