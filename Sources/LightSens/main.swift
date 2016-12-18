//
//  main.swift
//  LightSens
//
//  Created by Yusuke Ito on 12/18/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2CDeviceModule

let device = try getCurrentI2CDevice()

let module = BH1750(device: device)

try module.powerOn()

try module.change(mode: .continuouslyHighres)

while true {
    
    usleep(200 * 1000)
    
    let value = try module.readLxValue()
    
    print("\(value) lx")
}
