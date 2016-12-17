//
//  ZTSeg8.swift
//  I2CDeviceModule
//
//  Created by Yusuke Ito on 12/17/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C

// https://github.com/svn2github/obdcon/blob/master/obdlogger/ZtLib.h

public enum ZT8SegError: Error {
    case invalidStatus(UInt8)
    case invalidVersion([UInt8])
}

// Driver for ZT.SEG8B4A036A

public enum ZT8Seg {
    
    public enum Status: UInt8 {
        case run = 0x0
        case sleep = 0x1
        case setAddress = 0x2
        case test = 0x4
        case busy = 0x10
    }
}

public protocol ZT8SegDevice {
    associatedtype D: I2CDevice
    var device: D { get }
    var address: UInt8 { get }
    
    var segmentTable: [UInt8] { get }
    
    func sleep() throws
    func resume() throws
    func getStatus() throws -> ZT8Seg.Status
    func getVersion() throws -> String
    func setBrightness(onDelay: UInt8, offDelay: UInt8) throws
    func setData(_ data: [UInt8]) throws
    func setString(_ string: String) throws
}


fileprivate enum Register: UInt8 {
    case cmd = 0x1
    case data = 0x2
    case reset = 0x3
    case version = 0x1f
    case sleep = 0x4
    case status = 0x6
    case brightness = 0xa
    
    enum Sleep: UInt8 {
        case on = 0xa5
        case off = 0xa1
    }
}


public extension ZT8SegDevice {
    
    
    func sleep() throws {
        let buf: [UInt8] = [Register.sleep.rawValue, Register.Sleep.on.rawValue, 0, 0, 0]
        try device.write(toAddress: address, data: buf)
    }
    
    func resume() throws {
        let buf: [UInt8] = [Register.sleep.rawValue, Register.Sleep.off.rawValue, 0, 0, 0]
        try device.write(toAddress: address, data: buf)
    }
    
    func getStatus() throws -> ZT8Seg.Status {
        let readData = try device.write(toAddress: address, data: [Register.status.rawValue], readBytes: 1)
        guard let status = ZT8Seg.Status(rawValue: readData[0]) else {
            throw ZT8SegError.invalidStatus(readData[0])
        }
        return status
    }
    
    func getVersion() throws -> String {
        let readData = try device.write(toAddress: address, data: [Register.version.rawValue], readBytes: 19)
        guard let version = String(data: Data(readData), encoding: .utf8) else {
            throw ZT8SegError.invalidVersion(readData)
        }
        return version
    }
    
    func setBrightness(onDelay: UInt8, offDelay: UInt8) throws {
        let buf: [UInt8] = [Register.brightness.rawValue, onDelay, offDelay, 0, 0]
        try device.write(toAddress: address, data: buf)
    }
    
    func setData(_ data: [UInt8]) throws {
        
        precondition(data.count == 4, "data is should be 4 bytes")
        
        var buf = data
        buf.insert(Register.data.rawValue, at: 0)
        try device.write(toAddress: address, data: buf)
    }
    
    var segmentTable: [UInt8] {
        return [0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71]
    }
    
    func setString(_ string: String) throws {
        precondition(segmentTable.count == 16)
        
        var buffer: [UInt8] = [0,0,0,0]
        let chars = Array(string.characters)
        var index = buffer.count - 1
        for c in chars[0..<min(4, chars.count)].reversed() {
            var intVal = Int(String(c), radix: 16) ?? 0
            if intVal > 0xf {
                intVal = 0
            }
            buffer[index] = segmentTable[intVal]
            index -= 1
        }
        
        try setData(buffer)
    }
}

