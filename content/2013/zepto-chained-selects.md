---
title: Chained Selects for Zepto
date: 2013-10-27
tags:
    - JavaScript
photo: katie-chase-180320.jpg
---

New version of [Chained](http://www.appelsiini.net/projects/chained) mostly updates the remote version. Plugin now supports both [Zepto](http://zeptojs.com/) and [jQuery](http://jquery.com/). You can avoid initial AJAX requests by bootstrapping select values. You can configure extra values to be sent to server. Since plugin now accepts more configuration options new prettier syntax was implemented. Lastly support for [Bower](http://bower.io/) was added.

### Zepto support

Since plugin uses <code>:selected</code> you must also include Zepto [selector extension](https://github.com/madrobby/zepto/blob/master/src/selector.js). It is not included by default.

```html
<script src="zepto.js"></script>
<script src="zepto.selector.js"></script>
<script src="jquery.chained.js"></script>
```

After this you can use the plugin as you normally would.

### Bootstrapped selects

There are cases when you know values of the selects on page load. For example when linking directly to a saved order or a specific car model. When you know the values you can bootstrap the remote selects by giving the values in the options. This also avoids making the initial AJAX requests. If you have HTML code like below.

```html
<select id="mark" name="mark">
  <option value="">--</option>
  <option value="bmw" selected>BMW</option>
  <option value="audi">Audi</option>n
</select>
<select id="series" name="series">
  <option value="--">--</option>
</select>
```

To have BMW Series 3 selected by default you can bootstrap the select values.

```html
$("#series").remoteChained({
    parents : "#mark",
    url : "/api/series.json",
    bootstrap : {
        "--":"--",
        "series-3" : "3 series",
        "series-5" : "5 series",
        "series-6" : "6 series",
        "series-7" : "7 series",
        "selected" : "series-3"
    }
});
```

> **PRO TIP!** Note also the new prettier syntax in the example above. You can pass all configuration options in one hash.

### Send additional values

Sometimes you want to send more values than only the parent selects. Lets say you have select for transmission. Content of transmission select changes when user chooses new engine. However in your database possible different transmissions also depend on what series the car is. You have four different selects.


```html
<select id="mark" name="mark">
  <option value="">--</option>
  <option value="bmw" selected>BMW</option>
  <option value="audi">Audi</option>
</select>

<select id="series" name="series">
  <option value="--">--</option>
</select>

<select id="engine" name="engine">
  <option value="--">--</option>
</select>

<select id="transmission" name="transmission">
  <option value="--">--</option>
</select>
```

Then you could use the following JavaScript code to send values of both `#series` and `#engine` to server.

```javascript
$("#transmission").remoteChained({
    parents : "#engine",
    url : "/api/transmissions.json",
    depends : "#series"
});
```

> **PRO TIP!** Parent select values are always sent. You do not have include then in `depends` setting.

### Install

Download latest [minified](https://github.com/tuupola/jquery_chained/blob/master/jquery.chained.min.js) or remote version [minified](https://github.com/tuupola/jquery_chained/blob/master/jquery.chained.remote.min.js). You can also install with bower.

    $ bower install chained
