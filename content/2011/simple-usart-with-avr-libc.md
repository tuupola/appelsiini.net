---
title: Simple Serial Communications With AVR libc
date: 2011-11-19
tags:
    - AVR
    - Electronics
photo: jayphen-simpson-2116.jpg
---

I like to use various Arduino boards for AVR development. What I do not
like are the Arduino libraries. They are often just
[wrappers around libc functions](https://github.com/arduino/Arduino/tree/master/libraries/EEPROM)
or [rewrites of functions libc already provides](https://github.com/arduino/Arduino/blob/master/hardware/arduino/cores/arduino/Print.cpp).
Serial communications is one good example. Arduino provides you with its
own implementation of <code>Serial.print()</code>,
<code>Serial.println()</code> and <code>Serial.read()</code> methods. At
the same time AVR Libc has proven <code>printf()</code>,
<code>puts()</code> and <code>getchar()</code> functions. This article
explains easy implementation of libc functions used for serial
communications.

<!--more-->

> **If you do not have much experience in programming it is probably
better to stick with Arduino libraries.** They are good at hiding
some of the confusing features of embedded programming. However changes
are you grow out of them after few projects. Atmel datasheets are not as
confusing as they first appear. You might also want to check the
[finished code](https://github.com/tuupola/avr_demo/tree/master/blog/simple_usart)
of this article.

### Configuring UART

AVR microcontrollers have three control and status registers. Register
<code>UCSR0A</code> mostly contains status data. <code>UCSR0B</code> and
<code>UCSR0C</code> contain all the configuration settings. See the
[tables in the end of article](#registers) for all possible values.

AVR Libc provides [helper macros for baud rate
calculations](http://www.nongnu.org/avr-libc/user-manual/group__util__setbaud.html).
Header file requires <code>F\_CPU</code> and <code>BAUD</code> to be
defined. After including the header file <code>UBRRL\_VALUE</code>,
<code>UBRRH\_VALUE</code> and <code>USE\_2X</code> are defined. First
two are used to set UART speed. Last one is used to determine if UART
has to be configured to run in double speed mode with given baud rate.

<code>UCSZ20</code> <code>UCSZ01</code> and <code>UCSZ00</code> control
the data size. Possible sizes are 5-bit (000), 6-bit (001), 7-bit (010),
8-bit (011) and 9-bit (111). Most common used data size is 8-bit.

With above bits we can set most common configuration: no parity, 8 data
bits, 1 stop bit.

```c
#define F_CPU 16000000UL
#define BAUD 9600

#include <util/setbaud.h>

void uart_init(void) {
    UBRR0H = UBRRH_VALUE;
    UBRR0L = UBRRL_VALUE;

#if USE_2X
    UCSR0A |= _BV(U2X0);
#else
    UCSR0A &= ~(_BV(U2X0));
#endif

    UCSR0C = _BV(UCSZ01) | _BV(UCSZ00); /* 8-bit data */
    UCSR0B = _BV(RXEN0) | _BV(TXEN0);   /* Enable RX and TX */
}
```

### Writing and Reading From UART

You can transmit data to UART by writing a byte to USART Data Register
<code>UDR0</code>. First you have to make sure UART is ready to transmit
new data. You can wait until USART Data Register Empty <code>UDRE</code>
flag is set. Alternatively you can wait after each byte to transmission
be ready. USART Transmit Complete <code>TXC0</code> is set when
transmission is ready.

 ```c
void uart_putchar(char c) {
    loop_until_bit_is_set(UCSR0A, UDRE0); /* Wait until data register empty. */
    UDR0 = c;
}

void uart_putchar(char c) {
    UDR0 = c;
    loop_until_bit_is_set(UCSR0A, TXC0); /* Wait until transmission ready. */
}
```

You can receive data from UART by reading a byte from USART Data
Register <code>UDR0</code>. USART Receive Complete <code>RXC0</code>
flag is set if to unread data exists in data register.

```c
char uart_getchar(void) {
    loop_until_bit_is_set(UCSR0A, RXC0); /* Wait until data exists. */
    return UDR0;
}
```

### Redirecting STDIN and STDOUT to UART

[FDEV\_SETUP\_STREAM](http://www.nongnu.org/avr-libc/user-manual/group__avr__stdio.html)
macro can be used to setup a buffer which is valid for stdio operations.
Initialized buffer will be of type <code>FILE</code>. You can define
separate buffers for input and output. Alternatively you can define only
one buffer which works for both input and output. First and second
parameters are names of the functions which will be called when data is
either read from or written to the buffer.

```c
FILE uart_output = FDEV_SETUP_STREAM(uart_putchar, NULL, _FDEV_SETUP_WRITE);
FILE uart_input = FDEV_SETUP_STREAM(NULL, uart_getchar, _FDEV_SETUP_READ);

FILE uart_io FDEV_SETUP_STREAM(uart_putchar, uart_getchar, _FDEV_SETUP_RW);
```

To prepare our <code>uart\_putchar</code> and <code>uart\_getchar</code>
function to be used with streams we have to change the definition a bit.
To properly format output we also force adding a carriage return after
newline has been sent.

```c
void uart_putchar(char c, FILE *stream) {
    if (c == '\n') {
        uart_putchar('\r', stream);
    }
    loop_until_bit_is_set(UCSR0A, UDRE0);
    UDR0 = c;
}

char uart_getchar(FILE *stream) {
    loop_until_bit_is_set(UCSR0A, RXC0); /* Wait until data exists. */
    return UDR0;
}
```

Now we can redirect both STDIN and STDOUT to UART. This enables us to
use AVR Libc provided functions to read and write to serial port.

```c
int main(void) {

    uart_init();
    stdout = &uart_output;
    stdin  = &uart_input;

    char input;

    while(1) {
        puts("Hello world!");
        input = getchar();
        printf("You wrote %c\n", input);
    }

    return 0;
}
```

<a name="registers"></a>

### Control and Status Registers

<table class="table table-hover table-bordered table-striped">
<thead>
<tr>
<th>
UCSR0A Bit #

</th>
<th>
Name

</th>
<th>
Description

</th>
</tr>
</thead>
<tbody>
<tr>
<td>
bit 7

</td>
<td>
<code>RXC0</code>

</td>
<td>
USART Receive Complete. Set when data is available and the data register
has not be read yet.

</td>
</tr>
<tr>
<td>
bit 6

</td>
<td>
<code>TXC0</code>

</td>
<td>
USART Transmit Complete. Set when all data has transmitted.

</td>
</tr>
<tr>
<td>
bit 5

</td>
<td>
<code>UDRE0</code>

</td>
<td>
USART Data Register Empty. Set when the <code>UDR0</code> register is
empty and new data can be transmitted.

</td>
</tr>
<tr>
<td>
bit 4

</td>
<td>
<code>FE0</code>

</td>
<td>
Frame Error. Set when next byte in the <code>UDR0</code> register has a
framing error.

</td>
</tr>
<tr>
<td>
bit 3

</td>
<td>
<code>DOR0</code>

</td>
<td>
Data OverRun. Set when the <code>UDR0</code> was not read before the
next frame arrived.

</td>
</tr>
<tr>
<td>
bit 2

</td>
<td>
<code>UPE0</code>

</td>
<td>
USART Parity Error. Set when next frame in the <code>UDR0</code> has a
parity error.

</td>
</tr>
<tr>
<td>
bit 1

</td>
<td>
<code>U2X0</code>

</td>
<td>
USART Double Transmission Speed. When set decreases the bit time by half
doubling the speed.

</td>
</tr>
<tr>
<td>
bit 0

</td>
<td>
<code>MPCM0</code>

</td>
<td>
Multi-processor Communication Mode. When set incoming data is ignored if
no addressing information is provided.

</td>
</tr>
</tbody>
</table>
<table class="table table-hover table-bordered table-striped">
<thead>
<tr>
<th>
UCSR0B Bit #

</th>
<th>
Name

</th>
<th>
Description

</th>
</tr>
</thead>
<tbody>
<tr>
<td>
bit 7

</td>
<td>
<code>RXCIE0</code>

</td>
<td>
RX Complete Interrupt Enable. Set to allow receive complete interrupts.

</td>
</tr>
<tr>
<td>
bit 6

</td>
<td>
<code>TXCIE0</code>

</td>
<td>
TX Complete Interrupt Enable. Set to allow transmission complete
interrupts.

</td>
</tr>
<tr>
<td>
bit 5

</td>
<td>
<code>UDRIE0</code>

</td>
<td>
USART Data Register Empty Interrupt Enable. Set to allow data register
empty interrupts.

</td>
</tr>
<tr>
<td>
bit 4

</td>
<td>
<code>RXEN0</code>

</td>
<td>
Receiver Enable. Set to enable receiver.

</td>
</tr>
<tr>
<td>
bit 3

</td>
<td>
<code>TXEN0</code>

</td>
<td>
Transmitter enable. Set to enable transmitter.

</td>
</tr>
<tr>
<td>
bit 2

</td>
<td>
<code>UCSZ20</code>

</td>
<td>
USART Character Size 0. Used together with <code>UCSZ01</code> and
<code>UCSZ00</code> to set data frame size. Available sizes are 5-bit
(000), 6-bit (001), 7-bit (010), 8-bit (011) and 9-bit (111).

</td>
</tr>
<tr>
<td>
bit 1

</td>
<td>
<code>RXB80</code>

</td>
<td>
Receive Data Bit 8. When using 8 bit transmission the 8th bit received.

</td>
</tr>
<tr>
<td>
bit 0

</td>
<td>
<code>TXB80</code>

</td>
<td>
Transmit Data Bit 8. When using 8 bit transmission the 8th bit to be
submitted.

</td>
</tr>
</tbody>
</table>
<table class="table table-hover table-bordered table-striped">
<thead>
<tr>
<th>
UCSR0C Bit #

</th>
<th>
Name

</th>
<th>
Description

</th>
</tr>
</thead>
<tbody>
<tr>
<td>
bit 7
bit 6
</td>
<td>
</td>
<td>
USART Mode Select 1 and 0. <code>UMSEL01</code> and <code>UMSEL00</code>
combined select the operating mode. Available modes are asynchronous
(00), synchronous (01) and master SPI (11).
</td>
</tr>
<tr>
<td>
bit 5
bit 4

</td>
<td>
<code>UPM01</code>
<code>UPM00</code>
</td>
<td>
USART Parity Mode 1 and 0. <code>UPM01</code> and <code>UPM00</code>
select the parity. Available modes are none (00), even (10) and odd
(11).

</td>
</tr>
<tr>
<td>
bit 3

</td>
<td>
<code>USBS0</code>

</td>
<td>
USART Stop Bit Select. Set to select 1 stop bit. Unset to select 2 stop
bits.

</td>
</tr>
<tr>
<td>
bit 2
bit 1
</td>
<td>
<code>UCSZ01</code>
<code>UCSZ00</code>

</td>
<td>
USART Character Size 1 and 0. Used together with with
<code>UCSZ20</code> to set data frame size. Available sizes are 5-bit
(000), 6-bit (001), 7-bit (010), 8-bit (011) and 9-bit (111).

</td>
</tr>
<tr>
<td>
bit 0

</td>
<td>
<code>UCPOL0</code>

</td>
<td>
USART Clock Polarity. Set to transmit on falling edge and sample on
rising edge. Unset to transmit on rising edge and sample on falling
edge.

</td>
</tr>
</tbody>
</table>

### More Reading

[Full source code](https://github.com/tuupola/avr_demo/tree/master/blog/simple_usart)
of this article. [USART entry in QEEWiki](https://sites.google.com/site/qeewiki/books/avr-guide/usart) by
Q. [Serial Communication Using AVR Microcontroller USART](http://www.engineersgarage.com/embedded/avr-microcontroller-projects/serial-communication-atmega16-usart)
by Engineers Garage. [Serial Communication Notes](http://www.cs.mun.ca/~rod/Winter2007/4723/notes/serial/serial.html)
by Rod Byrne.

<div class="alert alert-info">
<b>Want to improve your understanding of electronics?</b> Try the <a data-category="Udemy" data-action="Basic Electronics for Arduino Makers" data-label="Bottom Alert" href="https://click.linksynergy.com/deeplink?id=sTps5OcxYdc&mid=39197&murl=https%3A%2F%2Fwww.udemy.com%2Fbasic-electronics%2F">Basic Electronics for Arduino Makers</a> video course from Udemy.