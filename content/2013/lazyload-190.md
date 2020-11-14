---
title: Lazy Load with CSS Backgound Image Support
date: 2013-10-15
tags:
    - JavaScript
photo: kleber-varejao-filho-14626.jpg
---

You can now [lazyload CSS background images](http://www.appelsiini.net/projects/lazyload/enabled_background.html). Bind the plugin to non image element and it will automatically change the <code>background-image</code> style attribute when element is scrolled into view. You can also use effects.

```html
<div class="lazy" data-original="img/bmw_m1_hood.jpg" style="background-image: url('img/grey.gif'); width: 765px; height: 574px;"></div>

$("div.lazy").lazyload({
    effect : "fadeIn"
});
```

<!--more-->

### Optional placeholder image

The placeholder image is now optional. If you omit it plugin will use the default which is data uri grey png. One less http request to make.

```html
<img class="lazy" data-original="img/example.jpg" width="765" height="574">

$("img.lazy").lazyload();
```

### Download

Latest [source](https://raw.github.com/tuupola/jquery_lazyload/master/jquery.lazyload.js) or [minified](https://raw.github.com/tuupola/jquery_lazyload/master/jquery.lazyload.min.js). Plugin has been tested with Safari 6, Chrome 30, Firefox 24 on OSX and IE8, IE9, IE10, IE11, Chrome 28 on Windows and Mobile Safari on iOS 7.02 and 6.1.3. Full [changelog in GitHub](https://github.com/tuupola/jquery_lazyload#changelog).