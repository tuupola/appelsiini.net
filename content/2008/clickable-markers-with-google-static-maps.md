---
title: Clickable Markers With Google Static Maps
date: 2008-07-13
tags:
  - PHP
  - Maps
---

>*Heads up!* This article was written in 2008 and it exists mostly for historical purposes.

<img src="http://maps.google.com/staticmap?center=58.3756113333%2C26.7547026667&amp;zoom=13&amp;markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cgreen%7C58.379646%2C26.764090%2Cgreen&amp;size=640x300&amp;key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" alt="" class="hidden-xs img-thumbnail img-responsive" />

Static map is one big image. Markers are embedded inside the image. You can not use traditional <code>&lt;a href="#"></code> tags around separate markers. Binding <code>onclick</code> event to separate marker images wont work either. There are no separate markers. Just one large image.

With imagemaps you can specify arbitary areas inside an image which links to given url. Area can be circle, rectangle or polygon. Simple imagemap could look like following:

<!--more-->

```html
<map name="marker_map">
  <area shape="circle" coords="75,103,12" href="#">
  <area shape="circle" coords="122,105,12" href="#">
</map>
```

With imagemaps we can create clickable markers for Google Static Maps. We need to position an imagemap area over each marker. Problem is how to calculate x and y pixel coordinates for each marker.

For this tutorial lets start with with static map you see above. It is created with following PHP code.

```php
require_once 'Net/URL.php';
require_once 'Google/Maps.php';

$map_width  = 512;
$map_height = 300;
$map_size   = $map_width . 'x' . $map_height;
$zoom       = 13;
$markers    = '58.378700,26.731110,green|58.368488,26.768908,green|
               58.379646,26.764090,green';

$api_key = trim(file_get_contents('api_key.txt'));

/* Build the URL's for Static Maps API. */
$url = new Net_URL('http://maps.google.com/staticmap');
$url->addQueryString('center',  $center);
$url->addQueryString('zoom',    $zoom);
$url->addQueryString('markers', $markers);
$url->addQueryString('size',    $map_size);
$url->addQueryString('key',     $api_key);
$demo_map = $url->getUrl();
```

### Calculating Pixel Coordinates for Markers

For imagemap we need to know where markers are located in static map image. To calculate pixel location of marker we need to know the following things:

1. Latitude and longitude of the center of the map.
2. Current zoom level.
3. Size of the static map in pixels.

Static Maps API can automatically calculate needed zoom level and center position of the map. However there is no way of receiving this information back. Instead we have to calculate center latitude and longitude ourselves.

### Calculating Map Center

There are several ways of calculating geographic center of two or more points on earth surface. First is to calculate geographic midpoint in cartesian coordinates. Second is to find center of distance. Center of distance is point which has smallest possible distance from all given points. Both these methods give accurate results but require pretty complex calculations.

Easiest way to find map center is to use average latitude and longitude of all given markers. Result is close enough approximation for our needs.

```php
/* Calculate average lat and lon of markers. */
$marker_array = explode('|', $markers);
foreach ($marker_array as $marker) {
    list($lat, $lon, $col) = explode(',', $marker);
    $lat_sum += $lat;
    $lon_sum += $lon;
}
$lat_avg = $lat_sum / count($marker_array);
$lon_avg = $lon_sum / count($marker_array);

/* Set map to calculated center. */
$url->addQueryString('center',  $center);
```

We also have to convert center latitude and longitude to pixel coordinates in world map. For this we use previously created [Google\_Maps PHP class](https://github.com/tuupola/php_google_maps).

```php
/* Calculate center as pixel coordinates in world map. */
$center_x = Google_Maps::LonToX($lon_avg);
$center_y = Google_Maps::LatToY($lat_avg);
```

While were at it lets also calculate center as pixel coordinates in map image. This is really easy. We only need to divide image width and height by two.

```php
/* Calculate center as pixel coordinates in image. */
$center_offset_x = round(512 / 2);
$center_offset_y = round(300 / 2);
```

Now we know three things about demo map center. Latitude and longitude coordinates are 58.3756113333,26.7547026667. This equals to 308334961,160637460 in world map pixel coordinates. Which in turn equals 256,150 in image pixels coordinates.

To prove our point let's add a blue marker in our calculated center of map.

```php
$markers .= sprintf('|%s,%s,blue', $lat_avg, $lon_avg);
$url->addQueryString('markers', $markers);

$map_with_center = $url->getUrl();
```

<img src="http://maps.google.com/staticmap?center=58.3756113333%2C26.7547026667&amp;zoom=13&amp;markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cgreen%7C58.379646%2C26.764090%2Cgreen%7C58.3756113333%2C26.7547026667%2Cblue&amp;size=640x300&amp;key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" alt="" class="hidden-xs img-thumbnail img-responsive" />

We still need to make markers clickable...

### Calculating Marker Pixel Positions

For each marker we know their latitude and longitude. To find their location on map image following calculations have to be done.

1. Convert latitude and longitude to pixel x and y coordinates.
2. Calculate difference between above and map center x and y coordinates.
3. Convert above difference to match current zoom level.
4. Add above difference to center pixel coordinates in image.

PHP code below does all above. Note how shift right operator &gt;&gt; is used to convert the difference between center and marker pixel coordinates for current zoom. Maximum zoom is 21. Variable <code>$zoom</code> is the current zoom level. For zoom level 13 we would be doing <code>delta &gt;&gt; (21-13)</code> which equals <code>delta &gt;&gt; 8</code> which equals <code>delta / 2^8</code> which in turn equals <code>delta / 256</code>.

```php
foreach ($marker_array as $marker) {
   list($lat, $lon, $col) = explode(',', $marker);
   $target_y = Google_Maps::LatToY($lat);
   $target_x = Google_Maps::LonToX($lon);
   $delta_x  = ($target_x - $center_x) >> (21 - $zoom);
   $delta_y  = ($target_y - $center_y) >> (21 - $zoom);
   $marker_x = $center_offset_x + $delta_x;
   $marker_y = $center_offset_y + $delta_y;
}
```

### Generate Imagemap for Markers

Now we know marker pixel locations on static map. This enables us to generate imagemap for them. We will create clickable circles with radius of 12 pixels. Lets modify code we just wrote. Note that calculated marker location points to markers foot. We want the round head of marker be clickable. That is done by adjusting y coordinate with -20 pixels.

```php
$imagemap = '<map name="marker_map">';
foreach ($marker_array as $marker) {
  ...
  $marker_y = $center_offset_y + $delta_y - 20;
  $imagemap .= sprintf('<area shape="circle" coords="%d,%d,12" href="#">',
                        $marker_x, $marker_y);
}
$imagemap .= '</map>';
```

For demo's sake lets also add some jQuery code to notify us when marker is clicked.

```php
$(function() {
    $('map area').bind('click', function() {
        alert('You clicked on marker.');
        return false;
    });
});
```

<img src="http://maps.google.com/staticmap?center=58.3756113333%2C26.7547026667&zoom=13&markers=58.378700%2C26.731110%2Cgreen%7C58.368488%2C26.768908%2Cgreen%7C58.379646%2C26.764090%2Cgreen%7C58.3756113333%2C26.7547026667%2Cblue&size=512x300&key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" usemap="#marker_map" />

<map name="marker_map" id="marker_map">
<area shape="circle" coords="118,95,12" href="#">
<area shape="circle" coords="338,209,12" href="#">
<area shape="circle" coords="310,85,12" href="#">
</map>

Click on green markers.

### Conclusion

It takes a bit work but you can have clickable markers with static map. Yes I used JavaScript to indicate when marker was clicked. But that was not the point. Static maps are usually faster to load than full Google Map JavaScript API. You can also create [gracefully degrading Google Map](http://www.appelsiini.net/demo/google_maps_nojs/enabled.html) for those users with JavaScript disabled. Ability to click marker also gives you ability to open infobubble without JavaScript. That is left for the next part on series of blog posts about Google Maps.

You can find [source code](http://svn.appelsiini.net/viewvc/javascript/trunk/google_maps_nojs/) to the [working demo](http://www.appelsiini.net/demo/google_maps_nojs/imagemap.html) from svn.

Related entries: [Google Maps Without JavaScript Part 1](https://appelsiini.net/2008/google-maps-without-javascript), [Google Maps Without JavaScript Part 2](https://www.appelsiini.net/2008/google-maps-without-javascript-part-2), [Infowindows With Google Static Maps](https://www.appelsiini.net/2008/infowindows-with-google-static-maps).

