//
//  I2C.swift
//  i2clib
//
//  Created by Yusuke Ito on 12/14/16.
//
//

import Foundation

public protocol I2CDevice {
    func write(toAddress: UInt8, data: [UInt8]) throws
    func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8]
}

public final class NativeI2CDevice: I2CDevice {
    
    public init(portNumber: UInt8) {
        
    }
    
    public func write(toAddress: UInt8, data: [UInt8]) throws {
        
    }
    public func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8] {
        fatalError()
    }
}

