//
//  BH1750.swift
//  I2CDeviceModule
//
//  Created by Yusuke Ito on 12/18/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C

public final class BH1750 {
    public let address: UInt8
    public let device: I2CDevice
    public init(device: I2CDevice, address: UInt8 = 0x23) {
        self.device = device
        self.address = address
    }
}

extension BH1750 {
    
    fileprivate enum OpCode: UInt8 {
        case powerDown = 0
        case powerOn = 0x1
        case reset = 0x7
        case continuouslyHighresMode = 0x10
        case continuouslyHighresMode2 = 0x11
        case continuouslyLowresMode = 0x13
    }
    
    public enum MeasurementMode {
        case continuouslyHighres
        case continuouslyHighres2
        case continuouslyLowres
        fileprivate var opCode: OpCode {
            switch self {
            case .continuouslyHighres: return .continuouslyHighresMode
            case .continuouslyHighres2: return .continuouslyHighresMode2
            case .continuouslyLowres: return .continuouslyLowresMode
            }
        }
    }
    
    public func powerDown() throws {
        try device.write(toAddress: address, data: [OpCode.powerDown.rawValue])
    }
    
    public func powerOn() throws {
        try device.write(toAddress: address, data: [OpCode.powerOn.rawValue])
        usleep(10 * 1000)
    }
    
    public func change(mode: MeasurementMode) throws {
        try device.write(toAddress: address, data: [mode.opCode.rawValue])
        usleep(1 * 1000)
    }
    
    public func readRawData() throws -> UInt16 {
        let buf = try device.read(toAddress: address, readBytes: 2)
        // swap high and low bytes
        let value = UnsafePointer(buf.reversed()).withMemoryRebound(to: UInt16.self, capacity: 1) {
            $0.pointee
        }
        //print(buf, value)
        return value
    }
    
    public func readLxValue() throws -> Double {
        return Double(try readRawData()) / 1.2
    }
    
    // bit layout in highres mode 2
    // MSB
    // 2^14 2^13 2^12 2^11 2^10 2^9 2^8 2^7 ... 2^6 2^5 2^4 2^3 2^2 2^1 2^0 2^-
    public func readLxValue2() throws -> Double {
        var value = try readRawData()
        let lsb = value & 0x1
        value = (value >> 1) & 0x7f
        return (Double(value) + Double(lsb > 0 ? 0.5 : 0)) / 1.2
    }
    
}

