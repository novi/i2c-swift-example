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
    func read(toAddress: UInt8, readBytes: UInt32) throws -> [UInt8]
    
    // write then read (no STOP condition between write and read)
    // data.count == 0 (empty) -> only reading
    // readBytes == 0 -> only writing
    // the both data.count and readBytes == 0 -> only receiving ack
    // return buffer's count should be `readBytes`
    func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8]
}

public extension I2CDevice {
    
    func write(toAddress: UInt8, data: [UInt8]) throws {
        _ = try write(toAddress: toAddress, data: data, readBytes: 0)
    }
    
    func read(toAddress: UInt8, readBytes: UInt32) throws -> [UInt8] {
        return try write(toAddress: toAddress, data: [], readBytes: readBytes)
    }
}


// https://www.kernel.org/doc/Documentation/i2c/dev-interface
// http://matsup.blogspot.jp/2015/03/physical-computing-intel-edison-i2c_14.html

public final class KernelI2CDevice: I2CDevice {
    
    public init(portNumber: UInt8) {
        
    }
    
    public func write(toAddress: UInt8, data: [UInt8]) throws {
        
    }
    public func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8] {
        fatalError()
    }
}

