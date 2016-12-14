//
//  I2C.swift
//  i2clib
//
//  Created by Yusuke Ito on 12/14/16.
//
//

import Foundation

public protocol I2CDevice {
    func write(_ buf: [UInt8]) throws
    func write(_ buf: [UInt8], readBytes: UInt8) throws -> [UInt8]
}

public final class NativeI2CDevice: I2CDevice {
    
    public init(portNumber: UInt8) {
        
    }
    
    public func write(_ buf: [UInt8]) throws {
        
    }
    
    public func write(_ buf: [UInt8], readBytes: UInt8) throws -> [UInt8] {
        fatalError()
    }
}

