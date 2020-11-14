---
title: How Does Led Matrix Work?
date: 2011-11-04
tags:
    - AVR
    - Electronics
photo: printed-circuit-board.jpg
---

Led matrices are fun toys. Who would not love blinkenlights? Electronics
is hard. Electronics is much harder than programming. I had hard time
trying to understand how do the led matrices work. What is best way to
learn something? Build one yourself.

### Structure of Led Matrix

In a matrix format LEDs are arranged in rows and columns. You can also
think of them as y and x coordinates. Lets assume we have 4x4 matrix.
Rows would be marked from A to D and columns from 1 to 4. Now we can
address each LED by row and column. Top left led would be (A,1). Bottom
down led would be (D,4).

Led matrices come in two flavors. Common-row anode (left) and common-row
cathode (right).

![Led matrices](https://appelsiini.net/attachments/4x4-1.png)

<!--more-->

Figure above shows the different configurations. The difference between
these two configurations is how you lit a led. With common-row anode
current sources (positive voltage) are attached to rows A..D and
currents sinks (negative voltage, ground) to columns 1..4. With
common-row cathode current sinks are attached to rows A..D and currents
sources to columns 1..4.

For example. To light bottom down led (D,4) of common cathode matrix you
would feed positive voltage to column 4 and connect row D to ground. For
sake of clarity I will using common-row cathode in examples for the rest
of this article.

### Building a LED Matrix

To build a 4x4 common-row cathode matrix you will need 16 LEDs, four
resistors, some headers and prototyping board. I started by gluing the
leds to prototyping board with epoxy glue. This way it is easier to have
LEDs beautifully aligned. When gluing the leds make sure long and short
legs are aligned the same way.

![Gluing led matrix](https://appelsiini.net/attachments/4x4-glue.jpg)

When glue is dry it is time to bend and solder. First bend all cathodes
to left as close to prototyping board as possible. Solder all cathodes
in each row together. When cathodes are ready, bend all anodes. Anodes
must not touch cathodes. I used piece of plastic tubing to help bending
the anodes to form a bridge above cathodes.

![Bending legs](https://appelsiini.net/attachments/4x4-bend.jpg)

Now solder together all anodes in each row. Solder the headers and
connect cathode rows directly to the header.

![Bottom](https://appelsiini.net/attachments/4x4-bottom.jpg)

Anode rows are connected to header with current limiting resistors.
Value of the resistor depends on the LED used. Check the LED datasheet
for forward voltage and current. [LED
calculator](http://led.linear1.org/1led.wiz) will help you finding out
correct resistor. Matrix is now ready for testing.

![Top](https://appelsiini.net/attachments/4x4-top.jpg)

### Addressing Single LED

Connecting ground to row A and positive voltage to column 1 will light
the top right LED (A,1).

![Single led lit](https://appelsiini.net/attachments/4x4-test-1.jpg)

Connecting ground to row D and positive voltage to column 4 will light
the bottom down LED (D,4).

![Single led lit](https://appelsiini.net/attachments/4x4-test-2.jpg)

Intuition would say lighting the both (A,1) and (D,4) at the same time
is just connecting all the four wires. This is not the case. There are
four LEDs which are lit. This is because current is also flowing through
(A,4) and (D,1).

![Four leds lit](https://appelsiini.net/attachments/4x4-test-3.jpg)

### Multiplexing and Persistence of Vision

Multiplexing can be used to display arbitrary patterns with led
matrices. Multiplexing is sometimes also called scanning. It scans rows
(usually from up to down) and lights needed leds only in one row at
time. Something like following:

1.  Start by having everything disconnected.
2.  Connect positive voltage all the needed columns.
3.  Connect row to ground. This lights the needed leds in the row.
4.  Disconnect the row and all columns.
5.  Do the same steps one by one to all rows and then start from the
    beginning.

Do this slowly and you would see blinking LED rows. Do it really fast
and human eye can see the whole pattern. Phenomenon is called
[persistence of vision](http://en.wikipedia.org/wiki/Persistence_of_vision).

### Draw a Pattern

Lets write some simple code for drawing a pattern on the matrix. Note!
Even though I am using Arduino board I do not use Arduino libraries nor
IDE for developing. I do however like the Arduino pin numbering scheme.
Functions <code>pin\_mode()</code> and <code>digital\_write()</code>
work exactly the same way as their Arduino equivalents.

We start by setting up the pins and default state for them.

```c
uint8_t column_pins[4] = { 2, 3, 4, 5 };
uint8_t row_pins[4]    = { 11, 10, 9, 8 };

static void init(void) {

    /* Turn all columns off by setting then low. */
    for (uint8_t x=0; x<4; x++) {
        pin_mode(column_pins[x], OUTPUT);
        digital_write(column_pins[x], LOW);
    }

    /* Turn all rows off by setting then high. */
    for (uint8_t y=0; y<4; y++) {
        pin_mode(row_pins[y], OUTPUT);
        digital_write(row_pins[y], HIGH);
    }
}
```

To display a pattern on matrix we use <code>draw()</code> function.
Bitmap is passed as two dimensional array. Delay is used only to
demonstrate persistence of vision.

```c
uint8_t pattern[4][4]  = {{1,0,0,1}, {0,1,0,0}, {0,0,1,0}, {1,0,0,1}};

void draw(uint8_t buffer[4][4], uint8_t delay) {

    for (uint8_t row=0; row<4; ++row) {
        /* Connect or disconnect columns as needed. */
        for (uint8_t column=0; column<4; ++column) {
            digital_write(column_pins[column], buffer[row][column]);
        }

        /* Turn on whole row. */
        digital_write(row_pins[row], LOW);

        _delay_ms(delay);

        /* Turn off whole row. */
        digital_write(row_pins[row], HIGH);
    }
}
```

To examine persistence of vision effect we draw the pattern with
different delays.

```c
uint8_t main(void) {

    init();

    /* With 100ms delay eye can see updating row by row. */
    for (uint8_t i=0; i<10; i++) {
        draw(pattern, 100);
    }

    /* With 10ms delay pattern appears but flickers. */
    for (uint16_t i=0; i<100; i++) {
        draw(pattern, 10);
    }

    /* Withoud delay solid pattern appears. */
    while (1) {
        draw(pattern, 1);
    }

    return 0;
}
```

Full code can be found from
[GitHub](https://github.com/tuupola/avr_demo/tree/master/4x4_matrix_part_1).
Check the output from video below.

{{< vimeo 31568410 >}}

### More Reading

[Circuit Skills: LED Matrix](http://blog.makezine.com/archive/2011/03/circuit-skills-led-matrix-sponsored-by-jameco-electronics.html) by Make Magazine. [Driving a LED with or Without a Resistor](http://tinkerlog.com/2009/04/05/driving-an-led-with-or-without-a-resistor/) by Alexander Weber. [Introduction to Driving LED Matrices (PDF)](http://www.avagotech.com/docs/5980-3132EN) technote by Avago Technologies. [Light Emitting Diodes (LEDs)](http://www.kpsec.freeuk.com/components/led.htm) by the Electronics Club.
