---
title: Google Maps Without JavaScript
date: 2008-04-26
tags:
  - PHP
  - Maps
photo: whereami-headline-1400-2.png
---

![Static Maps](/img/2008/tartu.png)

We recently did a small Google Maps application for ERGO insurance. It consisted of submitting all their offices to Google Maps. KML export of office data was used to create map at [ERGO autoabi](http://kaskoabi.ergoaitab.ee) campaign site. First version used all JavaScript approach to create the sidebar and map on the page. I was not happy with it. Map page was empty for browsers with JavaScript disabled. Page also took too long to render. Two problems I could not ignore.

<!--more-->

Second version was mixture of PHP, JavaScript and new static maps API. Map now works without JavaScript. It renders much faster too. Check the [working demo](http://www.appelsiini.net/demo/google_maps_nojs/enabled.html) to see yourself.

### Importing KML

Google offers [GGeoXML](http://code.google.com/apis/maps/documentation/reference.html#GGeoXml) library for KML parsing. That I ditched in the beginning. It was impossible to create sidebar navigation with it. First I ended up using [EGeoXML](http://www.econym.demon.co.uk/googlemaps/egeoxml.htm). It got the job done but as I said earlier was too slow.

To speed things up I parsed KML files and outputted sidebar HTML with PHP. Simplified HTML and PHP below. Do not mind about \# hrefs. They will be replaced with something meaningfull later.

```php
<h3><a id="cityname" class="city" href="#">ERGO cityname</a></h3>
<ul>
    <li><a  class="office" href="#" id="marker-1">Office 1</a></li>
    <li><a  class="office" href="#" id="marker-2">Office 2</a></li>
    <li><a  class="office" href="#" id="marker-3">Office 3</a></li>
</ul>
```

``` php
$kml = array("tartu.kml", "parnu.kml");

/* Used in id's so we can later bind click to correct marker. */
$counter  = 0;
foreach($kml as $file) {
    $city = str_replace('.kml', '', $file);
    $xml  = $xml = simplexml_load_file($file, null, LIBXML_NOCDATA);

    /* Print cityname as headline. */
    printf('<h3><a id="%s" class="city" href="#">%s</a></h3>',
            $city, $xml->Document->name);
    foreach ($xml->Document->Placemark as $placemark) {
        $coordinates = $placemark->Point->coordinates;
        list($longtitude, $latitude, $discard) = explode(',', $coordinates, 3);

        /* Save parsed KML as simpler array. We output this as JSON later. */
        /* Save also id so we can match clicked link ad marker.            */
        $markers[] = array("latitude"    => $latitude,
                           "longtitude"  => $longtitude,
                           "name"        => (string)$placemark->name,
                           "description" => (string)$placemark->description,
                           "id"          => "marker-$counter");

        /* Print officename as link to single office. */
        printf('<li><a class="office" href="#" id="marker-%d">%s</a></li>',
                $latitude, $longtitude, $counter, $placemark->name);
        print "\n";
        $counter++;
    }
    print "</ul>\n";
}
```

### Putting Markers on Map With JavaScript

I gave the PHP parsed KML array back to JavaScript using JSON. Array is then looped passing data to <code>addMarker()</code> method. This method creates new marker, puts it on map and binds event to open new infowindow when marker is clicked. Simplified code below:

``` php
$(function() {

    /* Output parsed KML files as JSON */
    var markers     = <?php print json_encode($markers) ?>;
    var marker_hash = {};

    if (GBrowserIsCompatible()) {
        /* Init and center at Tartu. */
        var map = new GMap2(document.getElementById("map"));
        map.addControl(new GSmallMapControl());
        map.setCenter(new GLatLng(58.38133351447725, 24.516592025756836), 12);

        for (var i=0; i<markers.length; i++) {
            var current = markers[i];
            var marker  = addMarker(current);
            marker_hash[current.id] = {marker : marker};
        }
    }

    function addMarker(current) {
      var marker  = new GMarker(new GLatLng(current.latitude,
                                            current.longtitude));
      map.addOverlay(marker);
      GEvent.addListener(marker, 'click', function() {
          var html = '<h3>' + current.name + '</h3><p>' +
                     current.description + '</p>';
          marker.openInfoWindowHtml(html);
      });
      return marker;
    }

});
```

### Make It Work With JavaScript Challenged Browsers

Inside the map &lt;div&gt; there is an &lt;img&gt; tag which points to Google Static maps api. You can pass needed parameters in URL and Google generates map as static image. For example:

``` php
http://maps.google.com/staticmap?&zoom=12&size=688x300
&center=58.378700,26.731110&key=GOOGLE_API_KEY
```

Generates the following map:

<img src="http://maps.google.com/staticmap?&amp;zoom=12&amp;size=688x300&amp;center=58.378700,26.731110&amp;key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" alt="" class="hidden-xs img-thumbnail img-responsive" />

What we do here is really simple. In sidebar links we pass needed parameters in querystring. PHP then writes these parameters into &lt;img&gt; tag pointing to static maps api. Instead of <code>center</code> we pass <code>markers</code> parameter. It contains coordinates to one or more markers. Map api then centers map automatically. This comes especially handy when there is multiple markers.

For example link:

``` php
<a href="?markers=58.384933,24.499811,red|58.384731,24.507816,red|">
```

becomes the following img tag:

``` php
<img src="http://maps.google.com/staticmap?size=688x300
&markers=58.384933,24.499811,red|58.384731,24.507816,red|
&key=GOOGLE_API_KEY" />
```

which looks like this:

<img src="http://maps.google.com/staticmap?size=688x300&amp;markers=58.384933,24.499811,red%7C58.384731,24.507816,red%7C&amp;key=ABQIAAAASWfI7GkTRVrz1brU7GwV2BRb4tuXOrVDWXaYNDB1tYm76RuEyxQuEAfETfgIzoUG0VXo0yBFqfuU2g" alt="" class="hidden-xs img-thumbnail img-responsive" />

What we need to do is to update the code which generates sidebar html. I cut out lots of code for sake of clarity here. Important line is one with <code>printf()</code>.

``` php
foreach($kml as $file) {
    ...
    foreach ($xml->Document->Placemark as $placemark) {
        ...
        printf('<li><a  class="office" href="?zoom=14&markers=%s,%s,red"
        id="marker-%d">%s</a></li>', $latitude, $longtitude, $counter,
        $placemark->name);
        ...
    }
    ...
}
```

Each link now shows you map with single marker centered on map. Creating link for each city is requires one extra step. Each city contains multiple markers. Before creating the sidebar we loop through KML once to to build a querystring for <code>marker</code> parameter.

``` php
/* Prebuild querystring for all markers in a city. This is needed  */
/* to make a link which contains all markers in query string.      */
foreach($kml as $file) {
    $city = str_replace('.kml', '', $file);
    $temp = 'markers=';
    $xml = $xml = simplexml_load_file($file, null, LIBXML_NOCDATA);
    foreach ($xml->Document->Placemark as $placemark) {
        $coordinates = $placemark->Point->coordinates;
        list($longtitude, $latitude, $discard) = explode(',', $coordinates, 3);
        $temp .= sprintf('%s,%s,red|', $latitude, $longtitude);
    }
    $markers_string[$city] = $temp;
}
```

We also need to make small change code building the sidebar.

``` php
foreach($kml as $file) {
    ...
    /* Use prebuild querystring in city links. */
    printf('<h3><a id="%s" class="city" href="?%s">%s</a></h3>',
    $city, $markers_string[$city], $xml->Document->name);
    ...
}
```

Now we have working map with sidebar. Biggest difference is missing infowindows (bubbles). They would be perfectly doable but I left them out for a reason now.

You can find [source code](http://svn.appelsiini.net/viewvc/javascript/trunk/google_maps_nojs/) to the [working demo](http://www.appelsiini.net/demo/google_maps_nojs/enabled.html) from svn. There was couple of cosmetic things I did not describe here so check the source. ERGO Autoabi minisite still contains both [original](http://kaskoabi.ergoaitab.ee/kontorid-org.html) and [improved](http://kaskoabi.ergoaitab.ee/kontorid.html) versions of the map.

Static maps api is really great. I have only one complaint. Maximum size of 512x512 is a bit too limiting to my taste.

**UPDATE:** Google recently increased the maximum size of static map to 640x640. Thank you!

Related entries: [Google Maps Without JavaScript Part 2](/2008/google-maps-without-javascript-part-2/), [Clickable Markers With Google Static Maps](/2008/clickable-markers-with-google-static-maps/), [Infowindows With Google Static Maps](/2008/infowindows-with-google-static-maps/).
