---
title: Simple Static Maps With PHP
date: 2008-10-10
tags:
    - PHP
    - Maps
---

> *Heads up!* This article was written in 2008 and it exists mostly for historical purposes.

![Static Maps](/img/2008/staticmap.gif)

Lately I have been playing with Google Static Maps API a lot. Writing the same things again and again is tedious job. I decided to put the code together as one clean extendable package. Writing object oriented interface for generating URL is trivial. Real meat is having working [zoom and pan controls](http://www.appelsiini.net/projects/php_google_maps/controls.html) on static map ~~with just 9 lines of code~~ (demo now includes also clickable markers and infowindows).

<!--more-->

[Code](http://github.com/tuupola/php_google_maps/tree/master) is still alpha quality. API might change any time. But here is a quick walkthrough of current features. We will build the map you see above step by step.

### Create a Map Object

Map object is created using `Google_Maps::create('static')` factory method. If no markers are set you also need to set the center of the map.

```php
require_once 'Google/Maps.php';

$map = Google_Maps::create('static');

$map->setSize('540x300');
$map->setCenter(new Google_Maps_Coordinate('58.368488', '26.768908'));
$map->setZoom(8);
$map->setKey(API_KEY);
```

<img src="http://maps.google.com/staticmap?center=58.368488%2C26.768908&zoom=8&markers=&size=540x300&key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" width="540" height="300" alt="" /><br /><br />

### Add some markers

Location on map can be in two ways. Latitude and longitude represented by <i>Google\_Maps\_Coordinate</i> object. Or pixel x and pixel y location represented by <i>Google\_Maps\_Point</i> object. You can use both when creating a marker.

```php
$coord_1 = new Google_Maps_Coordinate('58.378700', '26.731110');
$coord_2 = new Google_Maps_Coordinate('58.368488', '26.768908');
$coord_3 = new Google_Maps_Coordinate('58.268488', '26.768908');

$marker_1 = new Google_Maps_Marker($coord_1);
$marker_2 = new Google_Maps_Marker($coord_2);
$marker_3 = new Google_Maps_Marker($coord_3);

$marker_1->setColor('green');
$marker_2->setColor('blue');
$marker_3->setColor('orange');

$map->setMarkers(array($marker_1, $marker_2, $marker_3));
```

<img src="http://maps.google.com/staticmap?center=58.368488%2C26.768908&zoom=8&markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cblue%7C58.268488%2C26.768908%2Corange%7C&size=540x300&key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" width="540" height="300" alt="" />
<br /><br />

### Automatically Calculate Zoom and Center

Google Static Maps API can automatically calculate zoom and center for you. However there is no way to know what zoom level it chose. If you need to know automatically calculated zoom and center use <i>$map-&gt;zoomToFit()</i> method.

Here we also add new marker using pixel coordinates. Note that we also clear the center of the map we set in the beginning. This allows map to recenter the map according to markers on the map.

```php
$point_1  = new Google_Maps_Point('308107197', '160958681');
$marker_4 = new Google_Maps_Marker($point_1);
$map->setCenter(false);
$map->addMarker($marker_4);
$map->zoomToFit();
```

<img src="http://maps.google.com/staticmap?center=58.319541032213%2C26.717725334168&zoom=10&markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cblue%7C58.268488%2C26.768908%2Corange%7C58.262488128851%2C26.601975336671%2C%7C&size=540x300&key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" width="540" height="300" alt="" /><br /><br />

### Show Marker Bounds

Sometimes you need to be able to visually see bounding box where all the markers fit in.

``` php
$map->showMarkerBounds();
```

<img src="http://maps.google.com/staticmap?center=58.319541032213%2C26.717725334168&zoom=10&markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cblue%7C58.268488%2C26.768908%2Corange%7C58.262488128851%2C26.601975336671%2C%7C&path=58.378700%2C26.601975336671%7C58.378700%2C26.768908%7C58.262488128851%2C26.768908%7C58.262488128851%2C26.601975336671%7C58.378700%2C26.601975336671%7C&size=540x300&key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" width="540" height="300" alt="" /><br /><br />

### Show Map Bounds at Chosen Zoom Level

You can also calculate and show map bounds at any zoom level. Example below displays map bounds at zoom level 8. Map itself is at zoom level 7.

```php
$map->setZoom(7);
$map_bounds = $map->getBounds(8);
$map->setPath($map_bounds->getPath());
```

<img src="http://maps.google.com/staticmap?center=58.319541032213%2C26.717725334168&zoom=7&markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cblue%7C58.268488%2C26.768908%2Corange%7C58.262488128851%2C26.601975336671%2C%7C&path=58.749635911828%2C25.234571099281%7C58.749635911828%2C28.200879693031%7C57.884150180108%2C28.200879693031%7C57.884150180108%2C25.234571099281%7C58.749635911828%2C25.234571099281%7C&size=540x300&key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" width="540" height="300" alt="" /><br /><br />

### Where's the Source?

If you want to play around with code you can get from <a href="http://github.com/tuupola/php_google_maps/tree">github</a>. Patches, improvements and suggestion are welcome.

```text
$ git clone git://github.com/tuupola/php_google_maps.git
$ wget http://github.com/tuupola/php_google_maps/zipball/master
```

Related entries: [Infowindows With Google Static Maps](https://appelsiini.net/2008//infowindows-with-google-static-maps/), [Clickable Markers With Google Static Maps](https://appelsiini.net/2008//clickable-markers-with-google-static-maps/).
