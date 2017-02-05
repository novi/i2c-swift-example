//
//  BMP180.swift
//  I2CDeviceModule
//
//  Created by Yusuke Ito on 2/5/17.
//  Copyright © 2017 Yusuke Ito. All rights reserved.
//

import Foundation
import I2C

public final class BMP180 {
    public let address: UInt8
    public let device: I2CDevice
    public init(device: I2CDevice, address: UInt8 = 0x77) {
        self.device = device
        self.address = address
    }
    
    fileprivate var calibration: CalibrationData? = nil
}

public enum BMP180Error: Error {
    case registerAccessError(address: UInt8)
    case invalidDeviceID
    case notCalibratedError
}

fileprivate extension BMP180 {
    
    enum ControlRegister: UInt8 {
        case outXLSB = 0xf8
        case outLSB = 0xf7
        case outMSB = 0xf6
        
        case ctrlMeas = 0xf4
        case softReset = 0xe0
        case id = 0xd0
    }
    
    enum CalibrationRegister: UInt8 {
        case MD = 0xbf
        case MC = 0xbd
        case MB = 0xbb
        case B2 = 0xb9
        case B1 = 0xb7
        case AC6 = 0xb5
        case AC5 = 0xb3
        case AC4 = 0xb1
        case AC3 = 0xaf
        case AC2 = 0xad
        case AC1 = 0xab
    }
    
    struct CalibrationData {
        let MD: Int16
        let MC: Int16
        let MB: Int16
        let B2: Int16
        let B1: Int16
        let AC6: UInt16
        let AC5: UInt16
        let AC4: UInt16
        let AC3: Int16
        let AC2: Int16
        let AC1: Int16
    }
    
    func readRegister(address: UInt8) throws -> UInt8 {
        let data = try device.write(toAddress: self.address, data: [address], readBytes: 1)
        guard data.count == 1 else {
            throw BMP180Error.registerAccessError(address: address)
        }
        return data[0]
    }
    
    func readRegister(_ register: ControlRegister) throws -> UInt8 {
        return try readRegister(address: register.rawValue)
    }
    
    func readRegister(address: UInt8) throws -> UInt16 {
        return UInt16(try readRegister(address: address) as UInt8)
    }
    
    func writeRegister(_ register: ControlRegister, value: UInt8) throws {
        try device.write(toAddress: self.address, data: [register.rawValue, value])
    }
    
    func getCalibration(_ register: CalibrationRegister) throws -> UInt16 {
        let lsb = try readRegister(address: register.rawValue) as UInt16
        let msb = try readRegister(address: register.rawValue-1) as UInt16
        return UInt16( (msb << 8) | lsb )
    }
    
    func getCalibration(_ register: CalibrationRegister) throws -> Int16 {
        let val: UInt16 = try getCalibration(register)
        return unsafeBitCast(val, to: Int16.self)
    }
    
    func getCalibration() throws -> CalibrationData {
        return try CalibrationData(MD: getCalibration(.MD),
                               MC: getCalibration(.MC),
                               MB: getCalibration(.MB),
                               B2: getCalibration(.B1),
                               B1: getCalibration(.B1),
                               AC6: getCalibration(.AC6),
                               AC5: getCalibration(.AC5),
                               AC4: getCalibration(.AC4),
                               AC3: getCalibration(.AC3),
                               AC2: getCalibration(.AC2),
                               AC1: getCalibration(.AC1))
    }
    
    func checkID() throws {
        guard try readRegister(address: ControlRegister.id.rawValue) == 0x55 as UInt8 else {
            throw BMP180Error.invalidDeviceID
        }
    }
    
}

public extension BMP180 {
    
    func reset() throws {
        try checkID()
        try writeRegister(.softReset, value: 0xb6)
        usleep(1000*10) // 10ms
    }
    
    func calibrate() throws {
        try checkID()
        usleep(1000*1) // 1ms
        self.calibration = try getCalibration()
    }
    
    public struct MesurementResult {
        public let temperature: Int16 // in 0.1 celsius
        public let pressure: Int64 // in pa
    }
    
    enum OversamplingSetting: UInt8 {
        case oss0 = 0
        case oss1 = 1
        case oss2 = 2
        case oss3 = 3
        fileprivate var waitMs: UInt {
            switch self {
            case .oss0: return 5
            case .oss1: return 8
            case .oss2: return 14
            case .oss3: return 24
            }
        }
    }
    
    func mesure(oversampling oss: OversamplingSetting) throws -> MesurementResult {
        try checkID()
        
        guard let calibration = self.calibration else {
            throw BMP180Error.notCalibratedError
        }
        
        let b5: Int64
        let t: Int64
        do {
            try writeRegister(.ctrlMeas, value: 0x2e)
            usleep(1000*7) // wait 7ms
            let utLSB = Int64(try readRegister(.outLSB))
            let utMSB = Int64(try readRegister(.outMSB))
            let ut = (utMSB << 8) | utLSB
            
            let x1 = ((ut - Int64(calibration.AC6)) * Int64(calibration.AC5)) >> 15
            let x2 = (Int64(calibration.MC) << 11) / (x1 + Int64(calibration.MD))
            b5 = x1 + x2
            t = (b5 + 8) >> 4
        }
        
        let p: Int64
        do {
            try writeRegister(.ctrlMeas, value: 0x34 | (oss.rawValue << 6))
            usleep(useconds_t(oss.waitMs + 2) * 1000) // wait
            let upXLSB = Int64(try readRegister(.outXLSB))
            let upLSB = Int64(try readRegister(.outLSB))
            let upMSB = Int64(try readRegister(.outMSB))
            let up = Int64(upMSB << 16 | upLSB << 8 | upXLSB) >> Int64(8-oss.rawValue)
            
            let b6 = (b5 - 4000)
            
            var x1 = ((Int64(calibration.B2) * ((b6 * b6) >> 12) )) >> 11
            var x2 = (Int64(calibration.AC2) * b6) >> 11
            var x3 = x1 + x2
            let b3 = ( (((Int64(calibration.AC1) * 4) + x3) << Int64(oss.rawValue)) + 2 ) / 4
            
            x1 = (Int64(calibration.AC4) * b6) >> 13
            x2 = ((Int64(calibration.B1) * ((b6 * b6) >> 12) )) >> 16
            x3 = (x1 + x2 + 2) >> 2
            let b4 = (Int64(calibration.AC4) * (x3 + 32768)) >> 15
            let b7 = (up - b3) * (50000 >> Int64(oss.rawValue))
            
            let p0: Int64
            if b7 < 0x80000000 {
                p0 = (b7 << 1) / b4
            } else {
                p0 = (b7 / b4) << 1
            }
            let xx1 = (((p0 >> 8) * (p0 >> 8)) * 3038) >> 16
            let xx2 = (-7357 * p0) >> 16
            p = p0 + ((xx1 + xx2 + 3791) >> 4)
        }
        return MesurementResult(temperature: Int16(t), pressure: p)
    }
    
}
