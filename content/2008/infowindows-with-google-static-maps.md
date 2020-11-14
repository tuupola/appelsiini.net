---
title: Infowindows With Google Static Maps
date: 2008-09-13
tags:
  - PHP
  - Maps
photo: whereami-headline-1400-2.png
---

> *Heads up!* This article was written in 2008 and it exists mostly for historical purposes.

![Static Maps](/img/2008/static_with_bubble.png)

Previously I showed you how to make a [Google Static Map with clickable markers](https://appelsiini.net/2008/clickable-markers-with-google-static-maps). Several people emailed me to ask how to show infowindow (or infobubble) when marker is clicked. Technique I explain below still needs JavaScript. It is used to open the infowindow. I use jQuery library in the examples.

Image above is just a screenshot. There is a separate page for [working demo](http://www.appelsiini.net/demo/google_maps_nojs/imagemap.html). Full [source code](http://svn.appelsiini.net/viewvc/javascript/trunk/google_maps_nojs/) is also available.

<!--more-->

### Infowindow HTML

First thing we need is HTML code for the infowindow. I wanted it look exactly the same as in Google Maps. I opened a random map and copied the HTML using FireBug inspect console.


![Static Maps](/img/2008/firebug_google_map.png)

I removed all unneseccary code and moved CSS to separate file. Resulting [HTML](http://www.appelsiini.net/demo/google_maps_nojs/bubble.html) is quite simple. Now we have an empty infowindow ready for use.

![Static Maps](/img/2008/google_bubble.png)

### Infowindow Content

In this example we have three green markers. Green markers should open infowindow when clicked. We could write full HTML code for three infowindows. In our case it is unneseccary. We will have separate content div but share rest of infowindow code between markers. This way there will be less HTML code on the page.

```html
<div id="bubble">
  ...
  <div id="content_0" class="bubble content"></div>
  <div id="content_1" class="bubble content"></div>
  <div id="content_2" class="bubble content"></div>
</div>
```

Later when marker is clicked we should figure out which marker it is and choose one content div to display. Other content divs will be hidden.

### Which Marker Was Clicked?

Each content div has unique id. We can inject same id to image map we generate. Lets put the id into *name* attribute of each link.

```html
<map name="marker_map">
  <area shape="circle" coords="75,103,12" href="#" name="content_0">
  <area shape="circle" coords="122,105,12" href="#" name="content_1">
  <area shape="circle" coords="149,125,12" href="#" name="content_2">
</map>
```

For this we need to alter imagemap generating code. This code we made in [previous part](/2008/clickable-markers-with-google-static-maps) of this tutorial.

```php
$counter = 0;
$imagemap = '<map name="marker_map">';
foreach ($marker_array as $marker) {
    ...
    $marker_y = $center_offset_y + $delta_y - 20;
    $imagemap .= sprintf('<area shape="circle" coords="%d,%d,12" href="#"
                          name="content_%d">',
                          $marker_x, $marker_y, $counter);
    $counter++;
}
$imagemap .= '</map>';
```

Now we have matching id and name between imagemap and content divs. Last thing to do is open the infowindow.

### Opening the Infowindow

When page with static map loads infowindow is hidden by default. We will listen for *click* events in imagemap areas.

```javascript
$(function() {
    $('map area').bind('click', function(event) {
        /* Here be the dragons. */
    });
});
```

When marker is clicked following things need to be done:

- Previous infowindow (if any) should be hidden.
- Content with same *id* as markers *name* should be shown.
- Infowindow should be repositioned over clicked marker and then shown.

We take a small shortcut here. We do not calculate infowindow position using markers coordinates. Instead we use coordinates received from *click* event. This is not exactly the same as marker position but close enough. However you can see how infowindow appears in different places if you move your mouse a bit and click one marker several times.

```javascript
$(function() {
    $('map area').bind('click', function(event) {

        /* Hide previous infowindow. */
        $('div.bubble.content').hide();

        /* Show content div with same id as markers name. */
        var id = '#' + $(this).attr('name');
        $(id).show();

        /* Calculate infowindow position and show it. */
        var bubble_left = event.pageX - 160;
        var bubble_top  = event.pageY - 200;
        $('#bubble').css({left: bubble_left, top: bubble_top}).show();

        return false;
    });

    $('#bubble img.close').bind('click', function(event) {
        $('#bubble').hide();
    });
});
```

Notice the last three lines? They close the infobubble when cross icon on top right corner is clicked.

### What next?

If you have simple map combining Static Maps API an JavaScript infobubble is a blazing fast technique. What if JavaScript is not available at all? Don't worry. That we will fix next time. In mean while let's play around with the [working demo](http://www.appelsiini.net/demo/google_maps_nojs/imagemap.html).

Related entries: [Clickable Markers With Google Static Maps](/2008/clickable-markers-with-google-static-maps/), [Google Maps Without JavaScript](/2008/google-maps-without-javascript/), [Google Maps Without JavaScript Part 2](/2008/google-maps-without-javascript-part-2/).
