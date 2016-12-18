//
//  Device.swift
//  I2CDeviceModule
//
//  Created by Yusuke Ito on 12/17/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C

public final class DeviceWrap: I2CDevice {
    private let device: I2CDevice
    
    public init<D: I2CDevice>(_ d: D) {
        self.device = d
    }
    
    public func write(toAddress: UInt8, data: [UInt8]) throws {
        try device.write(toAddress: toAddress, data: data)
    }
    
    public func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8] {
        return try device.write(toAddress: toAddress, data: data, readBytes: readBytes)
    }
}

#if os(Linux)
public func getCurrentI2CDevice() throws -> DeviceWrap {
    
    for i in 0..<10 {
        if FileManager.default.fileExists(atPath: "/dev/i2c-\(i)") {
            print("/dev/i2c-\(i) found")
            return DeviceWrap(try I2CBusDevice(portNumber: UInt8(i) ))
        }
    }
    
    print("trying to connect i2c tiny usb device...")
    return try DeviceWrap(I2CTinyUSB())
}
    
#else
    
public func getCurrentI2CDevice() throws -> DeviceWrap {
    return try DeviceWrap(I2CTinyUSB())
}

#endif
