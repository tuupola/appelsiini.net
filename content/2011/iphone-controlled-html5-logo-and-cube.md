---
title: iPhone Controlled HTML5 Logo and Color Cube
date: 2011-02-02
tags:
    - Ruby
    - JavaScript
photo: printed-circuit-board.jpg
---

> *Heads up!* This article was written in 2011 and it exists mostly for historical purposes.

When Apple released iOS 4.2 end of last year I was on a boat trip to
Finland. For me the most interesting features were added to Safari
browser. I wanted to learn about WebSockets. New DeviceOrientation API
just begged to be abused. I had an idea to control the content of laptop
browser by tilting and rotating the phone. I had working but ugly code
before ship arrived to Helsinki.

> If you have short attention span go straight to the [HTML5 logo](https://appelsiini.net/demo/websocket/html5.html) demo.

[Code](https://github.com/tuupola/demo_code/tree/master/websocket) has
been sitting on my hard drive since. I cleaned it up during last couple
of days. Also added additional eye candy by using the
oh-so-hot-at-the-moment HTML5 logo.

<!--mode-->

### How Does It Look?

{{< vimeo 19451023 >}}

### How Does It Work?

First open demo page with your browser. Browser must support WebSockets.
If you are using Safari which also support CSS 3D transforms check
[HTML5 Logo](https://appelsiini.net/demo/websocket/html5.html) page.
If you are using Chrome try [Colour Cube](https://appelsiini.net/demo/websocket/cube.html) page. When you
open a demo page it generates a random PIN number and connects to a
WebSocket server. PIN number is used as part of channel name.

```javascript
var socket = new WebSocket("ws://ws.appelsiini.net:8080/iphone/" + pin);
```

Next open the [mobile page](https://appelsiini.net/demo/websocket/iphone.html) with you
iPhone or iPod. Enter PIN number from previous page and press connect.
Your mobile browser now connects to same WebSocket server.

```javascript
var socket = new WebSocket("ws://ws.appelsiini.net:8080/iphone/" + pin);
```

If the PIN numbers match your browsers are effectively paired. Mobile
browser then uses [DeviceOrientation API](http://goo.gl/lEYyx) do
determine iPhone orientation. When user tilts or turn the device new
orientation is sent via WebSocket to server. Server in turn sends the
same data to computer browser which is listening on same channel.

Every time [HTML5 Logo](https://appelsiini.net/demo/websocket/html5.html) page receives WebSocket message it animates the logo using CSS 3D transforms.

```javascript
socket.onmessage = function(event) {
    var payload = JSON.parse(event.data);
    $("#elevator").css("-webkit-transform", "rotateX(" + payload.data.x * -1 + "deg)");
    $("#aileron").css("-webkit-transform", "rotateZ(" + payload.data.y * 1 + "deg)");
    $("#pitch").css("-webkit-transform", "rotateY(" + payload.data.z * 1 + "deg)");
}
```

[Colour Cube](https://appelsiini.net/demo/websocket/cube.html) is
almost the same. Only difference is It uses
[Pre3d](http://deanm.github.com/pre3d/) JavaScript 3d rendering engine
to draw and animate the cube.

> Note! Spinning HTML5 logo is taken from [HTML5 demo](http://code.bocoup.com/html5logo-3d/) by [Boaz Sender](http://boazsender.com/). Color cube is taken
from [Pre3d demo gallery](http://deanm.github.com/pre3d/) by
[Dean McNamee](http://www.deanmcnamee.com/). I did not originally create
them. I just adapted them to connect and animate with iPhones.

### WebSocket Server

[WebSocket server](https://github.com/tuupola/em-websocket-server)
itself is simple Ruby script based on [Event
Machine](http://rubyeventmachine.com/) and
[em-websocket](https://github.com/igrigorik/em-websocket). I could have
used [Pusher](http://www.pusherapp.com/) which provides a hosted
service. However I wanted to use this as learning experience. Also if
this demo goes popular I might hit some message limits of Pusher.
