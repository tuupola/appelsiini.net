---
title: How to Use 595 Shift Register?
headline: Driving 595 Shift Registers
date: 2012-01-02
tags:
  - AVR
  - Electronics
photo: printed-circuit-board.jpg
---

595 series shift registers come in many flavors. SN74HC595 is the most usual. [TPIC6B595](http://www.adafruit.com/products/457) is similar but can be used with more power hungry applications. Pin layouts are different but they all operate in the same way.

Shift register is controlled with three pins. They are usually called `DATA`, `LATCH` and ` CLOCK`. Chip manufacturers have different names. See the table below for two examples from Texas Instruments.

<!--more-->

<table class="table table-hover table-bordered table-striped">
  <thead>
    <tr>
      <th></th>
      <th>74HC595</th>
      <th>TPIC6B595</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>DATA</td>
      <td>SER</td>
      <td>SER IN</td>
    </tr>
    <tr>
      <td>LATCH</td>
      <td>RCLK</td>
      <td>RCK</td>
    </tr>
    <tr>
      <td>CLOCK</td>
      <td>SRCLK</td>
      <td>SRCK</td>
    </tr>
  </tbody>
</table>

`CLOCK` is an constant high - low signal used to synchronize data transfer. Each time `CLOCK` goes high two things happen. Current value in shift register gets shifted left by one. Last bit is dropped out. First bit will be set to current value of `DATA`. To write a byte to shift register this has to happen eight times in a loop.

```c
#define LATCH   B0
#define CLOCK   B1
#define DATA    B2

void shift_out(uint8_t data) {
    for(uint8_t i = 0; i < 8; i++) {
        /* Write bit to data port. */
        if (0 == (data & _BV(7 - i))) {
            digital_write(DATA, LOW);
        } else {
            digital_write(DATA, HIGH);
        }

        /* Pulse clock input to write next bit. */
        digital_write(CLOCK, LOW);
        digital_write(CLOCK, HIGH);
    }
}
````

After calling `shift_out()` the shift register internally contains new value. To update output pins you must pull `LATCH` high. This is sometimes called latching on pulsing the latch. Note that it is not enough to hold `LATCH` high. Data transfer happens on transition from low to high. This is also called rising edge. Code for a [led binary counter](http://vimeo.com/34472869) from 0 to 65535 would look like the following:

```c
int main(void) {

    for(uint16_t i = 0; i < 0xffff; i++) {
        /* Shift high byte first to shift registers. */
        shift_out(i >> 8);
        shift_out(i & 0xff);

        /* Pulse latch to transfer data from shift registers */
        /* to storage registers. */
        digital_write(LATCH, LOW);
        digital_write(LATCH, HIGH);

        _delay_ms(50);
    }

    return 0;
}
```

The technique above is called bit banging. Bit banging is a technique for serial communications using software instead of dedicated hardware. Good thing is it is cheap to implement. Bad thing is it wastes processing time. Luckily most AVR chips provide an alternative.

### Serial Peripheral Interface Bus

The Serial Peripheral Interface Bus or SPI is a synchronous serial data connection. It provides hardware implementation of the clock pulse and writing data serially. SPI terminology differs from bit banging a bit. You can use SPI with three pins only. If you also want to read value back from the slave device you must use fourth pin. This is what `MISO` is used for.

<table class="table table-hover table-bordered table-striped">
  <thead>
    <tr>
      <th>Bit Bang</th>
      <th>SPI</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>DATA</td>
      <td>MOSI</td>
      <td>Master Out Slave In</td>
    </tr>
    <tr>
      <td>LATCH</td>
      <td>SS</td>
      <td>Slave Select</td>
    </tr>
    <tr>
      <td>CLOCK</td>
      <td>SCLK</td>
      <td>Serial Clock</td>
    </tr>
    <tr>
      <td>-</td>
      <td>MISO</td>
      <td>Master In Slave Out</td>
    </tr>
  </tbody>
</table>

Before you can use SPI it must be configured. Main things to do are setting the device to work as master and the data order. Most of the time this is enough. Configuration is done by setting the appropriate bit in the SPI Control Register `SPCR`. For all configurable options see the <a href="#spcr">Control and Status Registers</a> table. When using SPI you cannot use any arbitrary pins. Instead read your datasheet to find out which pins your microcontroller uses for SPI. Values below are for ATmega32U4 which is used in both [Adafruit ATmega32U4 Breakout Board](http://www.adafruit.com/products/296) and [Teensy USB Development Board](http://www.pjrc.com/teensy/).

```c
#define SS   B0
#define SCLK B1
#define MOSI B2
#define MISO B3

void spi_init(void) {
    pin_mode(SCLK, OUTPUT);
    pin_mode(MOSI, OUTPUT);
    pin_mode(SS, OUTPUT); /* Should be output in Master mode. */

    SPCR &= ~(_BV(DORD)); /* MSB first. */
    SPCR |= _BV(MSTR);    /* Act as master. */
    SPCR |= _BV(SPE);     /* Enable SPI. */
}
```

After SPI is configured reading and writing to it is easy. When byte is written to SPI Data Register `SPDR` it will be transmitted to slave. Received bytes (if any) are written to hardware receive buffer. Reading `SPDR` will return the data in receive buffer.

```c
uint8_t spi_transfer(volatile uint8_t data) {
    SPDR = data;
    loop_until_bit_is_set(SPSR, SPIF);
    return SPDR;
}
```

Why `spi_transfer()` and not separate `spi_read()` and `spi_write()` functions? Internally both master and slave are 8-bit shift registers (do not confuse this with the TPIC6B595 shift register used in article). One bit is shifted from the master to the slave and from the slave to the master simultaneously in one serial clock cycle. After eight `SLCK` pulses data has been exchanged between master and slave. Slave never sends data to master by itself. Master always must write something to slave.

Main program is essentially the same as when using `shift_out()` function. Since we do not read anything back we can just ignore return value of `spi_transfer()` call.

```c
int main(void) {

    spi_init();

    for(uint16_t i = 0; i < 0xffff; i++) {
        /* Shift high byte first to shift registers. */
        spi_transfer(i >> 8);
        spi_transfer(i & 0xff);

        /* Pulse latch to transfer data from shift registers */
        /* to storage registers. */
        digital_write(SPI_SS, LOW);
        digital_write(SPI_SS, HIGH);
    }

    return 0;
}
```

<a name="spcr"></a>

### Control and Status Registers

<table class="table table-hover table-bordered table-striped">
  <thead>
    <tr>
      <th>SPCR Bit #</th>
      <th>Name</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>bit 7</td>
      <td>`SPIE`</td>
      <td>SPI Interrupt Enable.</td>
    </tr>
    <tr>
      <td>bit 6</td>
      <td>`SPE`</td>
      <td>SPI Enable. When set hardware SPI operations will be enabled.</td>
    </tr>
    <tr>
      <td>bit 5</td>
      <td>`DORD`</td>
      <td>Data Order. When set LSB will be transmitted first.</td>
    </tr>
    <tr>
      <td>bit 4</td>
      <td>`MSTR`</td>
      <td>Master / Slave Select. When set device will act as SPI master.</td>
    </tr>
    <tr>
      <td>bit 3</td>
      <td>`CPOL`</td>
      <td>Clock Polarity. When set leading edge will be falling and trailing edge rising. Vice versa when unset.</td>
    </tr>
    <tr>
      <td>bit 2</td>
      <td>`CPHA`</td>
      <td>Clock Phase. When set data will be sampled on trailing edge of the clock. Vice versa when unset.</td>
    </tr>
    <tr>
      <td>bit 1
      bit 0</td>
      <td>`SPR1`
      `SPR0`</td>
      <td>SPI Clock Rate Select 1 and 0. Used together with `SPI2X` to set the `SCK` frequency.</td>
    </tr>
  </tbody>
</table>

<table class="table table-hover table-bordered table-striped">
  <thead>
    <tr>
      <th>SPSR Bit #</th>
      <th>Name</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>bit 7</td>
      <td>`SPIF`</td>
      <td>SPI Interrupt Flag. Set when a serial transfer is complete. An interrupt is   generated if `SPIE` in `SPCR` is set and global interrupts are enabled. Cleared by hardware when interrupt handling vector is executed.</td>
    </tr>
    <tr>
      <td>bit 6</td>
      <td>`WCOL`</td>
      <td>Write Collision Flag. Set if the `SPDR` is written during a data transfer.</td>
    </tr>
    <tr>
      <td>bit 5
      bit 4
      bit 3
      bit 2
      bit 1
      </td>
      <td></td>
      <td>Reserved. Always zero.</td>
    </tr>
    <tr>
      <td>bit 0</td>
      <td>`SPI2X`</td>
      <td>Double SPI Speed. Used together with `SPR1` and `SPR0` to set the `SCK` frequency.</td>
    </tr>
  </tbody>
</table>

<table class="table table-hover table-bordered table-striped">
  <thead>
    <tr>
      <th>SPI2X</th>
      <th>SPR1</th>
      <th>SPR0</th>
      <th>SCK Frequency</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>0</td>
      <td>0</td>
      <td>0</td>
      <td>f<sub>osc</sub>/4</td>
    </tr>
    <tr>
      <td>0</td>
      <td>0</td>
      <td>1</td>
      <td>f<sub>osc</sub>/16</td>
    </tr>
    <tr>
      <td>0</td>
      <td>1</td>
      <td>0</td>
      <td>f<sub>osc</sub>/64</td>
    </tr>
    <tr>
      <td>0</td>
      <td>1</td>
      <td>1</td>
      <td>f<sub>osc</sub>/128</td>
    </tr>
    <tr>
      <td>1</td>
      <td>0</td>
      <td>0</td>
      <td>f<sub>osc</sub>/2</td>
    </tr>
    <tr>
      <td>1</td>
      <td>0</td>
      <td>1</td>
      <td>f<sub>osc</sub>/8</td>
    </tr>
    <tr>
      <td>1</td>
      <td>1</td>
      <td>0</td>
      <td>f<sub>osc</sub>/32</td>
    </tr>
    <tr>
      <td>1</td>
      <td>1</td>
      <td>1</td>
      <td>f<sub>osc</sub>/64</td>
    </tr>
  </tbody>
</table>

### Wiring TPIC6B595

Wiring is pretty straight forward but depends on the chip used. [TPIC6B595 from Adafruit](http://www.adafruit.com/products/457) was used when writing this article.

All shift registers should share `CLOCK` and `LATCH` signals. When cascading more than one shift register `DATA` is redirected to next register by connecting `SER OUT` to `SER IN`. Outputs are connected to corresponding leds. To enable outputs of TPIC6B595 you must also tie `SRCLR` pin to positive voltage and `G` pin to ground.

In image below `CLOCK` is blue, `LATCH` is yellow and `DATA` is orange.

<img class="img-responsive img-thumbnail" src="/img/tpic6b595.png" />

### More Reading

[Full source code](https://github.com/tuupola/avr_demo/tree/master/blog/driving_595) of this article. [Introduction to 74HC595 Shift Register](http://www.protostack.com/blog/2010/05/introduction-to-74hc595-shift-register-controlling-16-leds/)by ProtoStack. [The 74HC595 8 bit shift register](http://bildr.org/2011/02/74hc595/) by DrLuke. [Setup And Use of The SPI](http://atmel.com/dyn/resources/prod_documents/doc2585.pdf) technote by Atmel. [The Serial Peripheral Interface (SPI)](http://avrbeginners.net/architecture/spi/spi.html)    from AVR beginners. [Serial Peripheral Interface Bus](http://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus) article in Wikipedia.
