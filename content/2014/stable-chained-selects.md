---
title: Chained Selects Stable Release
date: 2014-10-10
tags:
    - JavaScript
photo: katie-chase-180320.jpg
---

[Chained](https://github.com/tuupola/jquery_chained) is now stable and in feature freeze. In 2.x version class support will be removed. Next major version will use data attributes will be used instead. After all, it is 2014 already!

### Legacy syntax removed

Stable version removes legacy syntax. It is not 100% compatible with 0.9.x branch. You must pass all options to remote version as JavaScript object. Example of all possible options below.

```javascript
$("#series").remoteChained({
    parents : "#mark",
    url : "/api/series.json",
    depends : "#series",
    loading : "Loading.",
    bootstrap : {
        "" : "--",
        "series-3" : "3 series",
        "series-5" : "5 series",
        "series-6" : "6 series",
        "series-7" : "7 series",
        "selected" : "series-3"
    }
});
```

<!--more-->

Class based version does not have any configuration. You only need to pass parent selector.

```javascript
$("#engine").chained("#series, #model");
```

### Chaining to non select inputs

You can now also chain to other inputs than selects. Usual case would be hidden or text.

```html
<input id="mark" name="mark" value="audi">
<select id="series" name="series">
    <option value="">--</option>
</select>

$("#series").remoteChained({
    parents : "#mark",
    url : "/api/series.json"
});
```

### Three different JSON formats

Plugin now accepts three different JSON formats. Pass either JavaScript object containing value – text pairs for each option.

```javascript
{
    "" : "--",
    "series-1" : "1 series",
    "series-3" : "3 series",
    "series-5" : "5 series",
    "series-6" : "6 series",
    "series-7" : "7 series",
    "selected" : "series-6"
}
```

If you need to be able to sort entries on server side use array of arrays…

```javascript
[
    [ "", "--" ],
    [ "series-1", "1 series" ],
    [ "series-3", "3 series" ],
    [ "series-5", "5 series" ],
    [ "series-6", "6 series" ],
    [ "series-7", "7 series" ],
    [ "selected", "series-6" ]
]
```

… or array of objects.

```javascript
[
    { "" : "--" },
    { "series-1" : "1 series" },
    { "series-3" : "3 series" },
    { "series-5" : "5 series" },
    { "series-6" : "6 series" },
    { "series-7" : "7 series" },
    { "selected" : "series-6" }
]
```

### Install

Download latest [minified](https://github.com/tuupola/jquery_chained/blob/master/jquery.chained.min.js) or remote version [minified](https://github.com/tuupola/jquery_chained/blob/master/jquery.chained.remote.min.js). You can also install with bower.

```text
$ bower install chained
```
