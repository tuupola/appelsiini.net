---
title: Update Pycom WiPy Firmware From Commandline
date: 2017-09-24
tags:
    - Electronics
    - ESP32
    - MicroPython
photo: sergey-svechnikov-189224.jpg
---

[WiPy](https://pycom.io/product/wipy/) is a bit pricey but good quality ESP32
development board from [Pycom](https://pycom.io/). I got mine from
[Pimoroni](https://shop.pimoroni.com/products/pycom-wipy-2-0). Pycom does offer
their own firmware updater but for my taste it has too much magic going on. I
prefer to do things from commandline and I stay in control and to see exactly
what update is doing. Quick Googling did not reveal anything so here is my upgrade
procedure.

## Download the Latest Pycom Firmware

For starters we need to find the latest Pycom firmware. Links can be found
from their forums. Or you can just query the filename from their software
update service.

```text
$ curl "https://software.pycom.io/findupgrade?key=wipy.wipy%20with%20esp32&redirect=false&type=all"

{
  "key":"wipy.wipy with esp32",
  "file":"https://software.pycom.io/downloads/WiPy-1.7.10.b1.tar.gz",
  "version":"1.8.0.b1",
  "intVersion":71303297,
  "hash":"f6c30bf8b08c50d188f727822be320061ed7847b"
}
```

<!--more-->

At the time of writing the version number and file name do not seem to match.
The download itself works though.

```text
$ wget https://software.pycom.io/downloads/WiPy-1.7.10.b1.tar.gz
--2017-09-23 23:24:46--  https://software.pycom.io/downloads/WiPy-1.7.10.b1.tar.gz

Resolving software.pycom.io... 13.58.86.194
Connecting to software.pycom.io|13.58.86.194|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 781586 (763K) [application/octet-stream]
Saving to: 'WiPy-1.7.10.b1.tar.gz'

WiPy-1.7.10.b1.tar. 100%[=====================>] 763.27K   301KB/s   in 2.5s

2017-09-23 23:24:49 (301 KB/s) - 'WiPy-1.7.10.b1.tar.gz' saved [781586/781586]
```

Or you can just combine above to a single command.

```text
$ wget --content-disposition "https://software.pycom.io/findupgrade?key=wipy.wipy%20with%20esp32&redirect=true&type=all"

--2017-09-24 00:52:27--  https://software.pycom.io/findupgrade?key=wipy.wipy%20with%20esp32&redirect=true&type=all
Resolving software.pycom.io... 13.58.86.194
Connecting to software.pycom.io|13.58.86.194|:443... connected.
HTTP request sent, awaiting response... 302 Found
Location: https://software.pycom.io/downloads/WiPy-1.7.10.b1.tar.gz [following]
--2017-09-24 00:52:27--  https://software.pycom.io/downloads/WiPy-1.7.10.b1.tar.gz
Reusing existing connection to software.pycom.io:443.
HTTP request sent, awaiting response... 200 OK
Length: 781586 (763K) [application/octet-stream]
Saving to: 'WiPy-1.7.10.b1.tar.gz'

WiPy-1.7.10.b1.tar. 100%[=====================>] 763.27K   714KB/s   in 1.1s

2017-09-24 00:52:29 (714 KB/s) - 'WiPy-1.7.10.b1.tar.gz' saved [781586/781586]
```

After the firmware is downloaded, unpack the tarball to a temporary folder.

```text
$ mkdir temp
$ cd temp
$ tar -xzvf ../WiPy-1.7.10.b1.tar.gz

x bootloader.bin
x partitions.bin
x script
x wipy.bin
```

You are now almost ready for the flashing.

## Install the Tools

First make sure you have [esptool](https://github.com/espressif/esptool) installed.
This is the commandline tool which will be used for flashing. Both Python 2 and Python 3
versions should be ok.

```text
$ pip2 install esptool

Collecting esptool
Requirement already satisfied: pyaes in /usr/local/lib/python2.7/site-packages (from esptool)
Requirement already satisfied: ecdsa in /usr/local/lib/python2.7/site-packages (from esptool)
Requirement already satisfied: pyserial>=2.5 in /usr/local/lib/python2.7/site-packages (from esptool)
Installing collected packages: esptool
Successfully installed esptool-2.1
```

## Prepare the Board

Before flashing you must put the board to a programming mode. Disconnect USB to make sure
the board is not powered. Connect pin `G23` to `GND`. This is easiest to do if you
also have the [expansion board](https://shop.pimoroni.com/products/pycom-expansion-board-2-0). The pins are fourth from the top on the left and second from the top on the right side.

![Pycom expansion board](/img/pycom-expansion.png)

Connect the USB cable again.
Board should now boot to the programming mode. You can test this with esptool.

```text
$ esptool.py --port /dev/cu.usbserial* --after no_reset read_mac

esptool.py v2.1
Connecting....
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
MAC: 30:ae:a4:00:86:68
Staying in bootloader.
```

If you instead see something like below it means board is not in programming mode.

```text
$ esptool.py --port /dev/cu.usbserial* --after no_reset read_mac

esptool.py v2.1
Connecting........_____....._____....._____....._____....._____....._____....._____....._____....._____....._____

A fatal error occurred: Failed to connect to Espressif device: Invalid head of packet ('\x08')
```

If programming mode failed try again. With some board revisions it might help
if you hit the reset button once after booting.

## Flash the new Firmware

The tarball contains bootloader, partition table and the firmware itself.
Usually you do not update the bootloader and partition table. However for
completeness sake in this example I update everything.

The ESP32 bootloader lives at flash offset `0x1000`. I use relatively low speed
of `115200` for flashing. It takes bit longer but in my experience has less
problems.

```text
$ esptool.py --port /dev/cu.usbserial* --baud 115200 --after no_reset write_flash --flash_mode dio --flash_freq 80m --flash_size detect 0x1000 bootloader.bin

esptool.py v2.1
Connecting....
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
Configuring flash size...
Auto-detected Flash size: 4MB
Flash params set to 0x022f
Compressed 12896 bytes to 8144...
Wrote 12896 bytes (8144 compressed) at 0x00001000 in 0.7 seconds (effective 140.2 kbit/s)...
Hash of data verified.

Leaving...
Staying in bootloader.
```

After bootloader flash the partition table. It goes to to offset `0x8000`. Otherwise
command is the same.

```text
$ esptool.py --port /dev/cu.usbserial* --baud 115200 --after no_reset write_flash --flash_mode dio --flash_freq 80m --flash_size detect 0x8000 partitions.bin

esptool.py v2.1
Connecting....
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
Configuring flash size...
Auto-detected Flash size: 4MB
Compressed 3072 bytes to 145...
Wrote 3072 bytes (145 compressed) at 0x00008000 in 0.0 seconds (effective 766.0 kbit/s)...
Hash of data verified.

Leaving...
Staying in bootloader.
```

Finally flash to firmware itself. Offset is `0x10000`. Since the image is quite much
larger this command will take a while.

```text
$ esptool.py --port /dev/cu.usbserial* --baud 115200 --after no_reset write_flash --flash_mode dio --flash_freq 80m --flash_size detect 0x10000 wipy.bin

esptool.py v2.1
Connecting......
Detecting chip type... ESP32
Chip is ESP32D0WDQ6 (revision 0)
Uploading stub...
Running stub...
Stub running...
Configuring flash size...
Auto-detected Flash size: 4MB
Compressed 1286416 bytes to 771494...
Wrote 1286416 bytes (771494 compressed) at 0x00010000 in 68.6 seconds (effective 150.0 kbit/s)...
Hash of data verified.

Leaving...
Staying in bootloader.
```

You should now have brand new firmware running on your WiPy board.

## Make Sure Everything Works

After flashing is done disconnect the USB cable and remove the wire between
`G23` and `GND`. Connect USB cable again to boot the board and connect to the
serial REPL. Press enter couple of times to see the prompt.

```text
$ screen /dev/cu.usbserial* 115200
>>>
```

If you do not get the prompt try pressing the reset button. After getting the
prompt you can use `uos` module the make sure you are running the latest version.

```text
>>> import uos
>>> uos.uname()
(sysname='WiPy', nodename='WiPy', release='1.8.0.b1', version='v1.8.6-760-g90b72952 on 2017-09-01', machine='WiPy with ESP32')
```



