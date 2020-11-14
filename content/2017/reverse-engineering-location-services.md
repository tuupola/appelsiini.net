---
title: Reverse Engineering Apple Location Services Protocol
date: 2017-05-10
tags:
    - Protocol Buffers
    - Geolocation
photo: martin-wessely-473.jpg
---

> Updates: Added new pdf link to the end (2017-05-11). Header is actually  length-prefix framed byte strings (2017-05-13).

While working on [Whereami](https://github.com/tuupola/whereami) I got interested on how Apple location services actually work. I know it is handled by `locationd` since [Little Snitch](https://www.obdev.at/products/littlesnitch/index.html) keeps blocking it. Usual way of inspecting traffic with proxychains did not work since macOS now has something called System Integrity Protection (SIP).

Alternative way was to setup [Charles](https://www.charlesproxy.com/) as MITM proxy for an iOS device. After looking at the traffic which was mostly the device phoning home I got what I needed - a location services request.

<!--more-->

## Location Services Request

The request itself is just `application/x-www-form-urlencode` with some binary data.

```text
POST /clls/wloc HTTP/1.1
Host: gs-loc.apple.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 97
Proxy-Connection: keep-alive
Accept: */*
User-Agent: locationd/1756.1.15 CFNetwork/711.5.6 Darwin/14.0.0
Accept-Language: en-us
Accept-Encoding: gzip, deflate
Connection: keep-alive
```

```text
00000000: 00 01 00 05 65 6e 5f 55 53 00 13 63 6f 6d 2e 61  ....en_US..com.a
00000010: 70 70 6c 65 2e 6c 6f 63 61 74 69 6f 6e 64 00 0c  pple.locationd..
00000020: 38 2e 34 2e 31 2e 31 32 48 33 32 31 00 00 00 01  8.4.1.12H321....
00000030: 00 00 00 2d 12 13 0a 11 62 34 3a 35 64 3a 35 30  ...-....b4:5d:50
00000040: 3a 39 34 3a 33 39 3a 62 33 12 12 0a 10 39 38 3a  :94:39:b3....98:
00000050: 31 3a 61 37 3a 65 36 3a 38 35 3a 37 30 18 00 20  1:a7:e6:85:70..
00000060: 64                                               d
```

Since data does not have gzip header `0x1f8b` my second guess was [protocol buffers](https://developers.google.com/protocol-buffers/). After all it is all the rage now and all the cool guys are using it. Let's try to decode.

```text
$ xxd -r request.hex | protoc --decode_raw
Failed to parse input.
```

That did not work. Maybe there is something extra in the request. Logic says the mac addresses should be part of the data. Let's try to decode them. They are the blue part of the hex dump.

<pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-shell" data-lang="shell">00000000: 00 01 00 05 65 6e 5f 55 53 00 13 63 6f 6d 2e 61  ....en_US..com.a
00000010: 70 70 6c 65 2e 6c 6f 63 61 74 69 6f 6e 64 00 0c  pple.locationd..
00000020: 38 2e 34 2e 31 2e 31 32 48 33 32 31 00 00 00 01  8.4.1.12H321....
00000030: 00 00 00 2d 12 13 0a 11 <span style="color:#66d9ef">62 34 3a 35 64 3a 35 30</span>  ...-....<span style="color:#66d9ef">b4:5d:50</span>
00000040: <span style="color:#66d9ef">3a 39 34 3a 33 39 3a 62 33 12 12 0a 10 39 38 3a  :94:39:b3....98:</span>
00000050: <span style="color:#66d9ef">31 3a 61 37 3a 65 36 3a 38 35 3a 37 30 <span style="color:#66d9ef">18 00 20</span>  1:a7:e6:85:70</span>..
00000060: 64                                               d</code></pre>

``` shell
$ xxd -r request2.hex | protoc --decode_raw
Failed to parse input.
```

Nope. Top part looks like a header. Let's try to remove the header instead.

<pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-shell" data-lang="shell">00000000: <span style="color:#e6db74">00 01 00 05 65 6e 5f 55 53 00 13 63 6f 6d 2e 61  ....en_US..com.a</span>
00000010: <span style="color:#e6db74">70 70 6c 65 2e 6c 6f 63 61 74 69 6f 6e 64 00 0c  pple.locationd..</span>
00000020: <span style="color:#e6db74">38 2e 34 2e 31 2e 31 32 48 33 32 31 00 00 00 01  8.4.1.12H321....</span>
00000030: <span style="color:#e6db74">00 00 00 2d 12 13 0a 11</span> <span style="color:#66d9ef">62 34 3a 35 64 3a 35 30</span>  <span style="color:#e6db74">...-....</span><span style="color:#66d9ef">b4:5d:50</span>
00000040: <span style="color:#66d9ef">3a 39 34 3a 33 39 3a 62 33 12 12 0a 10 39 38 3a  :94:39:b3....98:</span>
00000050: <span style="color:#66d9ef">31 3a 61 37 3a 65 36 3a 38 35 3a 37 30 18 00 20  1:a7:e6:85:70..</span>
00000060: <span style="color:#66d9ef">64                                               d</span></code></pre>

``` shell
$ xxd -r request3.hex | protoc --decode_raw
Failed to parse input.
```

Still no go.

After trial and erroring for a while I decided to brute force it by removing bytes one by one from the beginning to see if it decodes. Here is a bit polished version of that script.

```shell
#!/bin/bash
# Try to decode hidden protocol buffers message from binary

size=$(wc -c < $1)

for ((i=1; i<=$size; i++))
do
    dd if=$1 bs=1 skip=$i | protoc --decode_raw
    if [[ $? == 0 ]]
    then
        printf "\n"
        read -p "Removed $i bytes, continue? [Yy] " -n 1 -r
        printf "\n\n"
        if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
            exit 0
        fi
    fi
done
```

[protomower.sh](https://gist.github.com/tuupola/4dd26664e52c2fffd5bede658e84cb3b)

```text
$ ./protomower.sh request.bin
```

Running it first three matches seemed like false positives. There was output but some data was garbled. Fourth one feels legit.

<pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-shell" data-lang="shell">45+0 records in
45+0 records out
45 bytes transferred in 0.000063 secs (714938 bytes/sec)
<span style="color:#66d9ef">2 {
  1: "b4:5d:50:94:39:b3"
}
2 {
  1: "98:1:a7:e6:85:70"
}
3: 0
4: 100</span>

Removed 52 bytes, continue? [Yy]</code></pre>

Seems like my original idea was quite close. Yellow part is the removed bytes. Blue part is the successfully decoded protocol buffers message.

<pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-shell" data-lang="shell">00000000: <span style="color:#e6db74">00 01 00 05 65 6e 5f 55 53 00 13 63 6f 6d 2e 61  ....en_US..com.a</span>
00000010: <span style="color:#e6db74">70 70 6c 65 2e 6c 6f 63 61 74 69 6f 6e 64 00 0c  pple.locationd..</span>
00000020: <span style="color:#e6db74">38 2e 34 2e 31 2e 31 32 48 33 32 31 00 00 00 01  8.4.1.12H321....</span>
00000030: <span style="color:#e6db74">00 00 00 2d</span> <span style="color:#66d9ef">12 13 0a 11 62 34 3a 35 64 3a 35 30</span>  <span style="color:#e6db74">...-....</span><span style="color:#66d9ef">b4:5d:50</span>
00000040: <span style="color:#66d9ef">3a 39 34 3a 33 39 3a 62 33 12 12 0a 10 39 38 3a  :94:39:b3....98:</span>
00000050: <span style="color:#66d9ef">31 3a 61 37 3a 65 36 3a 38 35 3a 37 30 18 00 20  1:a7:e6:85:70..</span>
00000060: <span style="color:#66d9ef">64                                               d</span></code></pre>

This means request message has four different type of data. In protocol buffers lingo each data type is called a tag. This message has four tags.

* `1` is a string which contains a mac address. This is most likely a wifi router mac address.
* `2` is an embedded message which contains `1` as the value. Think of this as a struct or an object.
* `3` and `4` are integers. Meaning of them is unknown to me. Maybe age since router was last seen or signal to noise ratio.

To prove the hypothesis let try to make a request with different mac addresses. I used a hex editor to edit the binary request file and did a POST request with curl.

<pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-shell" data-lang="shell">00000000: <span style="color:#e6db74">00 01 00 05 65 6E 5F 55 53 00 13 63 6F 6D 2E 61  ....en_US..com.a</span>
00000010: <span style="color:#e6db74">70 70 6c 65 2e 6c 6f 63 61 74 69 6f 6e 64 00 0c  pple.locationd..</span>
00000020: <span style="color:#e6db74">38 2e 34 2e 31 2e 31 32 48 33 32 31 00 00 00 01  8.4.1.12H321....</span>
00000030: <span style="color:#e6db74">00 00 00 2d</span> <span style="color:#66d9ef">12 13 0a 11 36 34 3a 64 38 3a 31 34  ...-....64:d8:14
00000040: <span style="color:#66d9ef">3a 37 32 3a 36 30 3a 30 63 12 13 0a 11 31 30 3a  :72:60:0c....10:</span>
00000050: <span style="color:#66d9ef">62 64 3a 31 38 3a 35 66 3a 65 39 3a 38 33 18 00  bd:18:5f:e9:83..</span>
00000060: <span style="color:#66d9ef">20 64                                                d</span></code></pre>

```text
$ curl https://gs-loc.apple.com/clls/wloc --include --request POST --data-binary @request2.bin

HTTP/1.1 400 Bad Request
Date: Sun, 07 May 2017 06:26:06 GMT
Cneonction: Close
Content-Type: text/plain
X-RID: 62904d6c-fe93-47d5-b579-548f9c83297c
Content-Length: 11

Bad Request
```

No go. What went wrong?

Looking at the dump you can see message is now one byte longer. So there must be a checksum somewhere. This one is pretty obvious. `0x2d` is 45 in decimal and the original message was 45 bytes long. New message is 46 bytes long which would be `0x2e` in hex. I would also bet the variable is a 16 bit integer ie. `0x002e`.

<pre style="color:#f8f8f2;background-color:#272822;-moz-tab-size:4;-o-tab-size:4;tab-size:4"><code class="language-shell" data-lang="shell">00000000: <span style="color:#e6db74">00 01 00 05 65 6E 5F 55 53 00 13 63 6F 6D 2E 61  ....en_US..com.a</span>
00000010: <span style="color:#e6db74">70 70 6c 65 2e 6c 6f 63 61 74 69 6f 6e 64 00 0c  pple.locationd..</span>
00000020: <span style="color:#e6db74">38 2e 34 2e 31 2e 31 32 48 33 32 31 00 00 00 01  8.4.1.12H321....</span>
00000030: <span style="color:#e6db74">00 00</span> <span style="color: #ff5555">00 2e</span> <span style="color:#66d9ef">12 13 0a 11 36 34 3a 64 38 3a 31 34  ...-....64:d8:14
00000040: <span style="color:#66d9ef">3a 37 32 3a 36 30 3a 30 63 12 13 0a 11 31 30 3a  :72:60:0c....10:</span>
00000050: <span style="color:#66d9ef">62 64 3a 31 38 3a 35 66 3a 65 39 3a 38 33 18 00  bd:18:5f:e9:83..</span>
00000060: <span style="color:#66d9ef">20 64                                             d</span></code></pre>

```text
$ curl https://gs-loc.apple.com/clls/wloc --include --request POST --data-binary @request3.bin

HTTP/1.1 200 OK
X-RID: bb3cc16a-6680-4019-b5d0-fb52e8c8bd5a
Content-Type: text/plain
Content-Length: 4948
```

Success. Now we know the format of request.

```text
[header][size][message]
```

Header itself can be dissected furthrer. I originally though these were just magical ASCII control code. However reader in reddit [guided me](https://www.reddit.com/r/programming/comments/6abmlo/reverse_engineering_apple_location_services/dhdiwre/) to correct direction. These seem to be length-prefix framed byte strings. I still think `0x0001` indicates start of header though. It also looks like header is null terminated `0x0000`.

```text
NUL SOH      /* 0x0001 start of header */
[length]     /* length of the locale string in bytes */
[locale]     /* en_US */
[length]     /* length of the identifier string in bytes */
[identifier] /* com.apple.locationd */
[length]     /* length of the version string in bytes
[version]    /* 8.4.1.12H321 ie. ios version and build */
NUL NUL      /* 0x0000 end of header */
NUL SOH      /* 0x0001 start of header */
NUL NUL      /* 0x0000 end of header */
```

I am not sure what the last four bytes mean. Maybe it is a placeholder for second header which is just currently empty.

## Location Services Response

The response itself is quite large.

```text
00000000: 00 01 00 00 00 01 00 00 13 4a 12 40 0a 10 36 34  .........J.@..64
00000010: 3a 64 38 3a 31 34 3a 37 32 3a 36 30 3a 63 12 2c  :d8:14:72:60:c.,
00000020: 08 80 98 f7 f8 bc ff ff ff ff 01 10 80 98 f7 f8  ................
00000030: bc ff ff ff ff 01 18 ff ff ff ff ff ff ff ff ff  ................
00000040: 01 28 ff ff ff ff ff ff ff ff ff 01 12 30 0a 11  .(...........0..
00000050: 31 30 3a 62 64 3a 31 38 3a 35 66 3a 65 39 3a 38  10:bd:18:5f:e9:8
00000060: 33 12 18 08 a1 a9 d3 40 10 a0 8c db de 26 18 39  3......@.....&.9
00000070: 20 00 28 11 30 08 58 3c 60 ec 01 a8 01 06 12 2e   .(.0.X<`.......
00000080: 0a 0f 30 3a 31 65 3a 31 33 3a 37 3a 39 30 3a 64  ..0:1e:13:7:90:d
...
000012F0: 01 01 12 2f 0a 10 30 3a 32 61 3a 31 30 3a 65 65  .../..0:2a:10:ee
00001300: 3a 35 30 3a 61 34 12 18 08 c0 a3 d5 40 10 b7 c1  :50:a4......@...
00001310: c8 de 26 18 2b 20 00 28 14 30 0e 58 3e 60 e8 01  ..&.+ .(.0.X>`..
00001320: a8 01 0b 12 2f 0a 10 30 3a 31 31 3a 32 31 3a 63  ..../..0:11:21:c
00001330: 63 3a 35 36 3a 33 32 12 18 08 8d ec c9 40 10 91  c:56:32......@..
00001340: 95 cf de 26 18 61 20 00 28 14 30 0f 58 3f 60 c3  ...&.a .(.0.X?`.
00001350: 1a a8 01 01                                        ....
```

Lets try our poor mans brute forcing again. It works again. Decoded output is approximately 1400 lines long.

```text
$ ./protomower.sh response.bin
```

```text
2 {
  1: "64:d8:14:72:60:c"
  2 {
    1: 18446744055709551616
    2: 18446744055709551616
    3: 18446744073709551615
    5: 18446744073709551615
  }
}
2 {
  1: "10:bd:18:5f:e9:83"
  2 {
    1: 135582881
    2: 10399172128
    3: 57
    4: 0
    5: 17
    6: 8
    11: 60
    12: 236
  }
  21: 6
}
...

Removed 10 bytes, continue? [Yy]
```

First one is bit confusing. `18446744073709551615` is `0xfffffffffffffff` ie maximum unsigned 64 bit value. This probably means mac address was not found. I have no idea what to think about `18446744055709551616` ie. `0xfffffffbcf1dcc00`

Rest of the results are more clear.

* `2-1` is the mac address
* `2-2-1` is the latitude `135582881 * pow(10, -8) = 1.35544532`
* `2-2-2` is the longitude `10399172128 * pow(10, -8) = 103.99172128`
* `2-2-3` looks like the location accuracy
* `2-21` probably the wifi channel

What puzzled me first is why I get 101 results. Then it occurred me that it is 100 successful results. First two are the mac addresses I sent. Rest of them are mac addresses which are in close vicinity to the ones I submitted.

## But Still Why 100 Results?

My guess is Apple offloads the [trilateration](https://en.wikipedia.org/wiki/Trilateration) calculations to client. Instead of doing expensive calculations for everyone just return bunch of access points and their coordinates.

If at least three of those are actually visible to the client [core location](https://developer.apple.com/reference/corelocation) can use the signal level as distance. When you have three coordinates and their distance to target location you can calculate target location with reasonable accuracy.

Below are the access points location services returned while requesting location in Changi.

<img src="https://appelsiini.net/img/changi-access-points.jpg" alt="" class="img-thumbnail img-fluid" />

Having information of hundred access points around you also reduces the need of contacting the location services server again. As long as core location has coordinates of three visible access points it can calculate the location accurately. This can be done even when offline as long as wifi is turned on.

## So What Can I Do with This?

You could write userland core location support for programming language which does not do it natively. Although there are [easier ways](https://pypi.python.org/pypi/pyobjc-framework-CoreLocation/) to achieve the [same thing](https://github.com/evanphx/lost/tree/master/ext/lost).

More interesting would be to write your own location services server to help with some creative debugging of your location enabled apps.

## Additional Reading

[Application à l’analyse des données de géolocalisation envoyées par un smartphone](https://fxaguessy.fr/resources/pdf-articles/Rapport-PFE-interception-SSL-analyse-localisation-smatphones.pdf) by François-Xavier Aguessy and Côme Demoustier. I do not read french but this paper has some  `.proto` file examples and Python code which helped me to get started. Protocol seems to have changed since the paper was published though.

[Vulnerability Analysis and Countermeasures for WiFi-based Location Services and Application](http://cacr.uwaterloo.ca/techreports/2014/cacr2014-25.pdf) by Jun Liang (Roy) Feng and Guang Gong is good reading in general to understand how WiFi based positioning works.

[Gaussian Processes for Signal Strength-Based
Location Estimation](http://www.roboticsproceedings.org/rss02/p39.pdf) by Brian Ferris, Dirk Hahnel and Dieter Fox. I do not understand half of the mathematics. However this paper gives good insight of the problems indoor WiFi positioning has.

Discussion in [Reddit](https://www.reddit.com/r/programming/comments/6abmlo/reverse_engineering_apple_location_services/) and [Hacker News](https://news.ycombinator.com/item?id=14306748).