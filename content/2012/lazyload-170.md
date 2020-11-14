---
title: Lazy Load 1.7.0 Released
date: 2012-01-28
tags:
    - JavaScript
photo: kleber-varejao-filho-14626.jpg
---

Previous version of [Lazy Load](https://appelsiini.net/projects/lazyload/) gained traction pretty fast. Good patches were submitted to GitHub. This version of plugin mostly concentrates on speed optimization and event handlers.

### New Events

Two new events were added. Handler for `appear` event is called when image appears to viewport but before it is loaded.  Handler for `load` event is called when image is loaded. Both event handler receive two parameters. First parameter `elements_left` is numbers of images left to load. Second parameter `settings` is the settings passed to Lazy Load plugin. Inside both handlers `this` refers to the image dom element.

```javascript
$("img.lazy").lazyload({
    appear : function(elements_left, settings) {
        console.log(this, elements_left, settings);
    },
    load : function(elements_left, settings) {
        console.log(this, elements_left, settings);
    }
});
```

<!--more-->

### New Parameter

New parameter `data_attribute` was added. It allows custom naming of original image attribute.

```javascript
$("img.lazy").lazyload({
data_attribute  : "kitten"
});

<img src="/img/placeholder.gif" data-kitten="/img/real-image.png" width="640" height="480" />
```

### Renamed Parameter

Parameter `effectspeed` was renamed to `effect_speed`. Old version will work for couple of versions. This parameter has existed before but it was previously undocumented.

### Selectors

Viewport selectors got tuned up. Internally they are used to determine when image appears on screen. Speed up is around 25%. You can compare speed tests of [1.6.0](http://jsperf.com/lazyload-1-6-0) and [1.7.0](http://jsperf.com/lazyload-1-7-0). While you're at there click the *Run tests* button to help me collect better data. Some selector names were added and changed to match [Viewport Selectors plugin](http://www.appelsiini.net/projects/viewport).

```javascript
$("img:in-viewport").something();
$("img:below-the-fold").something();
$("img:above-the-top").something();
$("img:left-of-screen").something();
$("img:right-of-screen").something();
```

### Download

Latest [source](https://raw.github.com/tuupola/jquery_lazyload/master/jquery.lazyload.js) or [minified](https://raw.github.com/tuupola/jquery_lazyload/master/jquery.lazyload.min.js). Plugin has been tested with Safari 5.1, Firefox 3.6, Firefox 7.0, Firefox 8.0 on OSX and Firefox 3.0, Chrome 14 and IE 8 on Windows and Safari 5.1 on iOS 5 both iPhone and iPad.

