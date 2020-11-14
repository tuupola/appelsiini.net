---
title: Programming GD32V Longan Nano
date: 2020-11-14
draft: true
image: img/2020/bbb-cover-1.jpg
description: Lorem ipsum dolor sit amet.
tags:
    - Electronics
    - GD32V
    - HAGL
---

![Big Buck Bunny on ESP32](/img/2020/bbb-cover-1.jpg)

<!--more-->

## Nuclei SDK

For programming a GD32V series SoC best choice at the moment is the [Nuclei SDK](https://doc.nucleisys.com/nuclei_sdk/). It seems to be well maintained, exceptionally well structured and is quite easy to learn. Developing is done with your favourite text editor.

The SDK supports three differend real time operating systems: FreeRTOS, UCOSII and RT-Thread. Since Longan Nano has only 32KB SRAM you might want to stay baremetal instead.

Nuclei SDK does not support Longan Nano out of the box, but I am currently writing a patch which [adds support for Longan Nano boards](https://github.com/tuupola/nuclei-sdk/tree/longan-nano).

Basic hello world would look like the following.

```c
#include <stdio.h>

void main(void)
{
    printf("Hello world\r\n");
}
```

## Additional reading
