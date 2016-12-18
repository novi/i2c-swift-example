# i2c-swift-example

This repository demonstrates how to control I2C devie using Swift. 

* `Sources/I2CDetect`: Detect I2C Device on the bus
* `Sources/I2CDeviceModule`: Some I2C module driver library, LED and sensors...
* `Sources/Counter`: Counter demo for LED 8Seg module (ZT.SEG8B4A036A)
* `Sources/LightSens`: Ambient Light Sensor demo (BH1750)
* `Sources/LightSensDisplay`: Combine with LED and light sensor the above

## Supported Platform

* [I2CTinyUSB](https://github.com/novi/i2c_tiny_usb) adapter (Mac)
* I2C Kernel device (/dev/i2c-*) (Linux, Raspberry Pi etc...)

## Building

Install libusb package.

### macOS

```
$ brew install libusb-compat libusb
```

### Linux(Ubuntu 16.04)


```
$ sudo apt-get install i2c-tools libi2c-dev libusb-dev
```

Build library and its demo.

```
make debug
```

On Linux, you should probably run the demo with `sudo`.

```
sudo .build/debug/I2CDetect
```