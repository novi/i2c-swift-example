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

final class MyZT8Seg: ZT8SegDevice {
    let device: DeviceWrap
    let address: UInt8 = 0x51
    init<D: I2CDevice>(_ d: D) throws {
        device = DeviceWrap(d)
    }
}

let zt8 = try MyZT8Seg(getCurrentI2CDevice())

try zt8.resume()

print("module version", try zt8.getVersion())

var i = 0
while true {
    
    // as integer
    let str = "\(i)"
    
    // as hex
    //let str = String(format: "%x", i)
    
    try zt8.setString(str)
    
    usleep(100 * 1000)
    
    i += 1
}
