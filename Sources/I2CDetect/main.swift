//
//  main.swift
//  I2CDetect
//
//  Created by Yusuke Ito on 12/17/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C

#if os(Linux)
    public func getCurrentI2CDevice() throws -> I2CDevice {
        do {
            return try I2CBusDevice(portNumber: 0)
        } catch {
            print(error)
            print("trying to connect i2c tiny usb device...")
            return try I2CTinyUSB()
        }
    }
    
#else
    
    public func getCurrentI2CDevice() throws -> I2CDevice {
        return try I2CTinyUSB()
    }
    
#endif


let device = try getCurrentI2CDevice()

var addr = 0x08 as UInt8
while addr <= 0x77 {
    
    let addrStr = String(format: "0x%lx", addr)
    
    usleep(50 * 1000); // wait
    
    print("sending... to", addrStr)
    
#if os(Linux)
    do {
        if try device.write(toAddress: addr, data: [], readBytes: 0) == [] {
            print("device found at", addrStr)
        }
    } catch I2CTinyUSB.USBDeviceError.USBI2CNoAckError {
        // no device found
    } catch I2CBusDevice.I2CError.noAckError {
        // no device found
    }
#else
    do {
        if try device.write(toAddress: addr, data: [], readBytes: 0) == [] {
            print("device found at", addrStr)
        }
    } catch I2CTinyUSB.USBDeviceError.USBI2CNoAckError {
        // no device found
    }
#endif
    
    addr += 1
}

//closeDevice()



