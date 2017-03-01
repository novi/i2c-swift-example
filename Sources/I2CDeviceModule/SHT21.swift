//
//  SHT21.swift
//  I2CDeviceModule
//
//  Created by Yusuke Ito on 3/1/17.
//  Copyright © 2017 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C

public final class SHT21 {
    public let address: UInt8
    public let device: I2CDevice
    public init(device: I2CDevice, address: UInt8 = 0x40) {
        self.device = device
        self.address = address
    }
}


fileprivate extension SHT21 {
    
    enum Command: UInt8 {
        case mesureHoldT = 0xe3
        case mesureHoldRH = 0xe5
        case reset = 0xfe
    }
    
    func sendAndRead(command: Command, readByte: UInt32) throws -> [UInt8] {
        return try device.write(toAddress: address, data: [command.rawValue], readBytes: readByte)
    }
    
    func send(command: Command) throws -> UInt16 {
        let data = try sendAndRead(command: command, readByte: 3)
        let value: UInt16 = UInt16(data[0] << 8) | UInt16(data[1] & 0xfc)
        return value
    }
}


public extension SHT21 {
    
    func reset() throws {
        _ = try sendAndRead(command: .reset, readByte: 0)
    }
    
    func mesureTemperature() throws -> Double {
        let val = Double(try send(command: .mesureHoldT))
        return -46.85 + (175.72 * val / 65536)
    }
    
    func mesureRH() throws -> Double {
        let val = Double(try send(command: .mesureHoldRH))
        return -6 + (125 * val / 65536)
    }
}
