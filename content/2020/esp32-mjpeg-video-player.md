---
title: Creating a Videoplayer for ESP32
date: 2020-05-25
image: img/2020/bbb-cover-1.jpg
description: Playing video files is quite resource heavy. Let's see how ESP32 can handle this.
tags:
    - Electronics
    - ESP32
    - HAGL
---

![Big Buck Bunny on ESP32](/img/2020/bbb-cover-1.jpg)

One of the things which makes embedded programming so interesting is that you are constantly dealing with restricted resources. Playing video files is quite resource heavy. Let's see how ESP32 can handle this. If you have short attention span [here is a video](https://vimeo.com/409435420) instead.

<!--more-->

## RAW RGB565

The easiest compression is no compression at all. Embedded displays are often configured to have RGB565 pixel format. This gives a good compromise between number of colors and bytes needed for one frame.

Raw video means each frame is consecutively stored in a file. There is no compression. There is no file header containing meta. Following code reads the first frame of such video.

To keeps the example code simple I am using an [SD card helper component](https://github.com/tuupola/esp_video/tree/master/components/esp_sdcard) to initialise the SD card.

```c
FILE *fp;
const size_t FRAME_SIZE = 320 * 180 * 2;
uint8_t *buffer = malloc(FRAME_SIZE);

sdcard_init();

fp = fopen("/sdcard/video.raw", "rb");
fread(buffer, FRAME_SIZE, 1, fp);
fclose(fp);
```

All frames can be read in a loop.

```c
FILE *fp;
const size_t FRAME_SIZE = 320 * 180 * 2;
uint8_t *buffer = malloc(FRAME_SIZE);

fp = fopen("/sdcard/video.raw", "rb");

while (fread(buffer, FRAME_SIZE, 1, fp)) {
    printf("Read a frame.\n");
};

fclose(fp);
```

This is still not interesting since nothing is displayed. You could blit the frame one by one to the display. Better still the `buffer` could be a pointer directly to the framebuffer or back buffer.

I am using graphics library called [HAGL](https://github.com/tuupola/hagl). It gives you a pointer to the back buffer when initialising the display. The back buffer also has to be flushed to the display.

I am also adding an [fps counter](https://github.com/tuupola/hagl/blob/master/include/fps.h) to see how well our video player is working.

```c
FILE *fp;
const size_t FRAME_SIZE = 320 * 180 * 2;
bitmap_t *hagl;

hagl = hagl_init();
sdcard_init();

fp = fopen("/sdcard/video.raw", "rb");

while (fread(hagl->buffer, FRAME_SIZE, 1, fp)) {
    hagl_flush();
    printf("%.*f FPS\n", 1, fps());
};

fclose(fp);
```

### Avoid the SD card bottleneck

The results are surprising bad. The video plays at only about 6 fps. The culprit seems to be newlibs [default buffer size](https://github.com/espressif/esp-idf/issues/3249#issuecomment-480678830) which causes files to be read in 128 byte chunks. Easy fix is to replace `fread()` with  `read()`.

Note that while `fread()` above returns number of frames read, `read()` here returns number of bytes read.

```c
FILE *fp;
const size_t FRAME_SIZE = 320 * 180 * 2;
bitmap_t *hagl;

hagl = hagl_init();
sdcard_init();

fp = fopen("/sdcard/video.raw", "rb");

while (read(fileno(fp), hagl->buffer, FRAME_SIZE)) {
    hagl_flush();
    printf("%.*f FPS\n", 1, fps());
};

fclose(fp);
```

Results are now much better. The raw video can be played at approximately 10 fps. Consecutively calling `printf()` slows things down. Removing it would allow 12 fps playback. Things can still be sped up by moving the display flushing to second ESP32 core.

That would make the example code too complicated for this article so we are good for now. See the [ESP32 videoplayer](https://github.com/tuupola/esp_video) repository to see how it was done.

First part of this video shows the RGB565 player on a TTGO T4.

{{< vimeo 409435420 >}}

## Motion JPEG

Motion JPEG or MJPEG is an intraframe video compression format. Each frame is compressed and stored separately as a JPG image. In laymans terms MJPEG is multiple JPG files concatenated into one bigger video file.

### Uncompressing JPG images

MJPEG video is just a bunch of JPG files. If the device can uncompress JPG files it should be able to play MJPEG videos. Most embedded libraries I have seen piggypack on the [Tiny JPEG Decompressor](http://www.elm-chan.org/fsw/tjpgd/00index.html). It needs to be provided with two functions: one for [reading a file](http://www.elm-chan.org/fsw/tjpgd/en/input.html) and one for [outputting the pixels](http://www.elm-chan.org/fsw/tjpgd/en/output.html).

Purpose of reader function is to either read bytes into buffer or skip bytes from the file pointer. If `buffer` is `NULL` function will fast forward the pointer `size` bytes.

```c
uint16_t tjpgd_data_reader(JDEC *decoder, uint8_t *buffer, uint16_t size)
{
    FILE *fp = (FILE *)decoder->device;

    if (buffer) {
        /* Read bytes from input stream. */
        return read(fileno(fp), buffer, size);
    } else {
        /* Skip bytes from input stream. */
        if (lseek(fileno(fp), size, SEEK_CUR) > 0) {
            return size;
        }
        /* Seek failed, causes TJPGD to abort. */
        return 0;
    }
}
```

Writer function receives the uncompressed image in 8x8 blocks. Here I use HAGL provided blit function to blit that block into the display. You could also a putpixel function for the same purpose.

```c
uint16_t tjpgd_data_writer(JDEC* decoder, void* bitmap, JRECT* rectangle)
{
    uint8_t width = (rectangle->right - rectangle->left) + 1;
    uint8_t height = (rectangle->bottom - rectangle->top) + 1;

    /* Create a HAGL bitmap from the uncompressed block. */
    bitmap_t block = {
        .width = width,
        .height = height,
        .depth = DISPLAY_DEPTH,
    };

    bitmap_init(&block, (uint8_t *)bitmap);

    /* Blit the block to the display. */
    hagl_blit(rectangle->left, rectangle->top + 30, &block);

    return 1;
}
```

Putting things together this is how you would display a JPG image.

```c
uint8_t work[3100];
FILE *fp;
JDEC decoder;
JRESULT result;

sdcard_init();

fp = fopen("/sdcard/image.jpg", "rb");

result = jd_prepare(&decoder, tjpgd_data_reader, work, 3100, fp);
if (JDR_OK == result) {
    jd_decomp(&decoder, tjpgd_data_writer, 0);
};

hagl_flush();
fclose(fp);
```

### Uncompressing MJPEG videos

So in theory to play an MJPEG file we should be able to just open the file and then read the JPG frames one by one.

```c
uint8_t work[3100];
JDEC decoder;
JRESULT result;
FILE *fp;

hagl_init();
sdcard_init();

fp = fopen("/sdcard/video.mjpeg", "rb");

while (1) {
    /* Prepare next frame. */
    result = jd_prepare(&decoder, tjpgd_data_reader, work, 3100, fp);

    if (JDR_OK == result) {
        jd_decomp(&decoder, tjpgd_data_writer, 0);
        /* Frame ready, flush it to the display. */
        hagl_flush();
        printf("%.*f FPS\n", 1, fps());
    } else {
        printf("Prepare failed!\n");
    }
};

fclose(fp);
```

However there is a problem. It only reads the first frame and then spits out prepare failed errors. The problem here is the `tjpgd_data_reader()` function. It reads the compressed data in 512 byte blocks. This means most of the time file pointer is advanced past the `EOI` (end of image) marker into the territory of the next frame.

When reading the next frame file pointer is already past the image header and TJPGD fails to read the image meta. Simple solution here is to rewind the filepointer back to the next byte after `EOI` marker.

```c
static uint16_t tjpgd_data_reader_new(JDEC *decoder, uint8_t *buffer, uint16_t size)
{
    FILE *fp = (FILE *)decoder->device;
    uint16_t bytes = 0;
    const uint16_t EOI = 0xffd9;
    uint8_t *match;

    if (buffer) {
        /* Read bytes from input stream. */
        bytes = read(fileno(fp), buffer, size);

        /* Search for EOI. */
        match = memmem(buffer, size, &EOI, 2);

        if (match) {
            /* Rewind back to previous EOI + 1. */
            int16_t offset = match - buffer;
            int16_t rewind = offset - size + 1;
            lseek(fileno(fp), rewind, SEEK_CUR);
            bytes += rewind;
        }

        return bytes;
    } else {
        /* Skip bytes from input stream. */
        if (lseek(fileno(fp), size, SEEK_CUR) > 0) {
            return size;
        }
        /* Seek failed, causes TJPGD to abort. */
        return 0;
    }
}
```

With this fix we now have a working MJPEG player. It is not the fastest. The above code is capable of playing 320x240 video with 6.5 fps. Again offloading display flushing to second ESP32 core would speed things up to 8 fps. See the [ESP32 videoplayer](https://github.com/tuupola/esp_video) repository to see how it was done.


Second part of this video starting at 00:45 shows the MJPEG player on a TTGO T4.

{{< vimeo 409435420 >}}

## Additional reading
