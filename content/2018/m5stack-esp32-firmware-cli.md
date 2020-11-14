---
title: Install Latest MicroPython to M5Stack
date: 2018-01-27
tags:
    - Electronics
    - ESP32
    - MicroPython
photo: sergey-svechnikov-189224.jpg
---

[M5Stack](http://m5stack.com/) is an absolutely beautiful ESP32 based enclosure and development board. It has 320x240 TFT screen, three buttons, sd card slot, Grove I2C connector and can be powered with LiPo battery.

## Download the Micropython Firmware

You could download the MicroPython firmware from the [downloads page](http://micropython.org/download#esp32). But why bother when we have the commandline. First find the download link.

```shell
$ curl --silent http://micropython.org/download | grep "firmware/esp32" | gawk -F'<a +href="' -v RS='">' 'RT{print $2}'

http://micropython.org/resources/firmware/esp32-20180127-v1.9.3-240-ga275cb0f.bin
```

<!--more-->

```shell
$ lynx -listonly -dump https://micropython.org/download | grep "firmware/esp32" | sed 's/.*http/http/'

http://micropython.org/resources/firmware/esp32-20180127-v1.9.3-240-ga275cb0f.bin
```

When download link is known, download the firmware.

```shell
$ wget http://micropython.org/resources/firmware/esp32-20180127-v1.9.3-240-ga275cb0f.bin

--2018-01-27 20:05:26--  http://micropython.org/resources/firmware/esp32-20180127-v1.9.3-240-ga275cb0f.bin
Resolving micropython.org... 176.58.119.26
Connecting to micropython.org|176.58.119.26|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 935888 (914K) [application/octet-stream]
Saving to: ‘esp32-20180127-v1.9.3-240-ga275cb0f.bin’

esp32-20180127-v1.9 100%[===================>] 913.95K   284KB/s    in 3.2s

2018-01-27 20:05:30 (284 KB/s) - ‘esp32-20180127-v1.9.3-240-ga275cb0f.bin’ saved [935888/935888]
```

## Install the Tools

First make sure you have [esptool](https://github.com/espressif/esptool) installed.
This is the commandline tool which will be used for flashing. Both Python 2 and Python 3
versions should be ok.

```shell
$ pip2 install esptool

Collecting esptool
  Downloading esptool-2.2.1.tar.gz (70kB)
    100% |████████████████████████████████| 71kB 94kB/s
Requirement already satisfied: pyserial>=2.5 in /usr/local/lib/python2.7/site-packages (from esptool)
Requirement already satisfied: pyaes in /usr/local/lib/python2.7/site-packages (from esptool)
Requirement already satisfied: ecdsa in /usr/local/lib/python2.7/site-packages (from esptool)
Building wheels for collected packages: esptool
  Running setup.py bdist_wheel for esptool ... done
  Stored in directory: /Users/hello/Library/Caches/pip/wheels/e8/63/0f/01c12901098b6be9d1e7e3e5bc50ef92f1f44a45534095aefa
Successfully built esptool
Installing collected packages: esptool
Successfully installed esptool-2.2.1
```

## Erase the Flash

Connect the M5Stack to your computer with the provided USB cable. Make sure esptool can connect.

```shell
$ esptool.py --port /dev/cu.SLAB_USBtoUART --baud 115200 --after no_reset read_mac

esptool.py v2.1
Connecting........_
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
MAC: 30:ae:a4:04:f0:d4
Staying in bootloader.
```

If esptool connected successfully continue by erasing the flash. Erasing is not absolutely necessary, but usually a good idea to avoid random problems.

```shell
$ esptool.py --port /dev/cu.SLAB_USBtoUART  --baud 115200 --after no_reset erase_flash

esptool.py v2.1
Connecting......
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
Erasing flash (this may take a while)...
Chip erase completed successfully in 4.5s
Staying in bootloader.
```

## Flash the new Firmware

The Micropython binary contains bootloader, partition table and the firmare itself concatenated in one file. You should flash this file at offset `0x1000`. I use relatively low speed of `115200` for flashing. It takes bit longer but in my experience has less
problems.

```shell
$ esptool.py --port /dev/cu.SLAB_USBtoUART --baud 115200 write_flash --flash_mode dio --flash_freq 80m --flash_size detect 0x1000 esp32-20180127-v1.9.3-240-ga275cb0f.bin

esptool.py v2.1
Connecting......
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
Configuring flash size...
Auto-detected Flash size: 4MB
Flash params set to 0x022f
Compressed 935888 bytes to 587152...
Wrote 935888 bytes (587152 compressed) at 0x00001000 in 51.9 seconds (effective 144.4 kbit/s)...
Hash of data verified.

Leaving...
Hard resetting...
```

You should now have brand Micropython firmware running on your M5Stack.

## Make Sure Everything Works

After flashing connect to the serial REPL to make sure everything is ok. Press enter couple of times to see the prompt.

```shell
$ screen /dev/cu.SLAB_USBtoUART 115200
>>>
```

Picocom is also popular alternative for serial communication. You can install it from [Homebrew](https://brew.sh/).

```shell
$ brew install picocom
$ picocom -b 115200 /dev/cu.SLAB_USBtoUART
>>>
```

If you do not get the prompt try removing and reattaching the usb cable. After getting the
prompt you can use `uos` module the make sure you are running the latest version. With `gc` you can check available memory.

```shell
>>>
MicroPython v1.9.3-240-ga275cb0f on 2018-01-27; ESP32 module with ESP32
Type "help()" for more information.
>>> import gc
>>> gc.collect()
>>> gc.mem_free()
90208
>>> import uos
>>> uos.uname()
(sysname='esp32', nodename='esp32', release='1.9.3', version='v1.9.3-240-ga275cb0f on 2018-01-27', machine='ESP32 module with ESP32')
>>>
```

## Where to Buy?

You can find M5Stack from both Banggood and AliExpress. BangGood links below are affiliate links. I have had success ordering from both.

|   | Model | $ | € |
|---|---|---|---|
| AliExpress | [M5Stack Basic][1] | $35.00 | €28.60 |
| AliExpress | [M5Stack MPU9250][2] | $41.00 | €33.55 |
| AliExpress | [M5Stack MPU9250 4MB][3] | $43.00 | €35.20 |
| BangGood | [M5Stack Basic][4] | $32.99 | €26.90 |
| BangGood | [M5Stack MPU9250][5] | $42.35 | €34.50 |

[1]: https://www.aliexpress.com/item/M5Stack-Official-Stock-Offer-ESP32-Basic-Core-Development-Kit-Extensible-Micro-Control-Wifi-BLE-IoT-Prototype/32837164440.html

[2]: https://www.aliexpress.com/item/M5Stack-Official-ESP-32-ESP32-MPU9250-9Axies-Motion-Sensor-Core-Development-Kit-Extensible-Micro-Control-Module/32839068608.html

[3]: https://www.aliexpress.com/item/M5Stack-NEWEST-4M-PSRAM-ESP32-Development-Board-with-MPU9250-9DOF-Sensor-Color-LCD-for-Arduino-Micropython/32847906756.html

[4]: http://bit.ly/m5stack-basic
[5]: https://bit.ly/m5stack-9dof