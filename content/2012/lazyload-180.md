---
title: Lazy Load Bugfix Release
date: 2012-08-03
tags:
    - JavaScript
photo: kleber-varejao-filho-14626.jpg
---

This version of [Lazy Load](https://appelsiini.net/projects/lazyload/) is just a bugfix release. Minor release number bump is there because I pulled a new feature in last minute and I did not want to mess up my git branching. Bugfix usually does not normally warrant for the minor bump.

### Bugs fixed

Plugin now works correctly when using many instances and they have different container.

```javascript
$("#column-1 img").lazyload({ container: $("#column-1") });
$("#column-2 img").lazyload({ container: $("#column-2") });
$("#column-3 img").lazyload({ container: $("#column-3") });
```

<!--more-->

### Download

Latest [source](https://raw.github.com/tuupola/jquery_lazyload/master/jquery.lazyload.js) or [minified](https://raw.github.com/tuupola/jquery_lazyload/master/jquery.lazyload.min.js). Plugin has been tested with Safari 5.1, Safari 6, Chrome 20, Firefox 12 on OSX and Chrome 20, IE 8 and IE 9 on Windows and Safari 5.1 on iOS 5 both iPhone and iPad.
