//
//  main.swift
//  Counter
//
//  Created by Yusuke Ito on 12/17/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C
import I2CDeviceModule

final class DeviceWrap: I2CDevice {
    private let device: I2CDevice
    init<D: I2CDevice>(_ d: D) {
        self.device = d
    }
    
    func write(toAddress: UInt8, data: [UInt8]) throws {
        try device.write(toAddress: toAddress, data: data)
    }
    
    func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8] {
        return try device.write(toAddress: toAddress, data: data, readBytes: readBytes)
    }
}

final class MyZT8Seg: ZT8SegDevice {
    let device: DeviceWrap
    let address: UInt8 = 0x51
    init<D: I2CDevice>(_ d: D) throws {
        device = DeviceWrap(d)
    }
}

let zt8 = try MyZT8Seg(I2CTinyUSB())

try zt8.resume()

var i = 0
while true {
    try zt8.setString("\(i)")
    
    usleep(500_1000)
    
    i += 1
}