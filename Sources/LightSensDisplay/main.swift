//
//  main.swift
//  LightSensDisplay
//
//  Created by Yusuke Ito on 12/18/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C
import I2CDeviceModule

final class MyZT8Seg: ZT8SegDevice {
    let device: DeviceWrap
    let address: UInt8 = 0x51
    init<D: I2CDevice>(_ d: D) throws {
        device = DeviceWrap(d)
    }
}

let device = try getCurrentI2CDevice()

let sensor = BH1750(device: device)

try sensor.powerOn()

try sensor.change(mode: .continuouslyHighres)


let zt8 = try MyZT8Seg(device)

try zt8.resume()

print("LED module version", try zt8.getVersion())

while true {
    
    usleep(200 * 1000)
    
    let value = Int(try sensor.readLxValue())
    
    print("\(value) lx")
    
    try zt8.setString("\(min(value, 9999))")
}
