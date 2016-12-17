//
//  BusDevice.swift
//  I2C
//
//  Created by Yusuke Ito on 12/17/16.
//  Copyright © 2016 Yusuke Ito. All rights reserved.
//

import Foundation

// https://www.kernel.org/doc/Documentation/i2c/dev-interface
// http://matsup.blogspot.jp/2015/03/physical-computing-intel-edison-i2c_14.html



#if os(Linux)
    
    import Ci2c
    
    
    public final class I2CBusDevice: I2CDevice {
        
        public enum I2CError: Error {
            case deviceOpenError(UInt8, Int32)
            case slaveAddressSetError(Int32)
            case readOrWriteError(Int32)
            case noAckError(Int32)
        }
        
        private var currentAddress: UInt8 = 0
        
        private func chageAddressIfNeeded(_ newAddress: UInt8) throws {
            guard currentAddress != newAddress else {
                return
            }
            let status = ioctl(i2c, UInt(I2C_SLAVE), CInt(newAddress))
            guard status == 0 else {
                throw I2CError.slaveAddressSetError(status)
            }
            self.currentAddress = newAddress
        }
        
        
        private let i2c: CInt
        
        public init(portNumber: UInt8) throws {
            let fd = open("/dev/i2c-\(portNumber)", O_RDWR)
            guard fd != -1 else {
                throw I2CError.deviceOpenError(portNumber, fd)
            }
            self.i2c = fd
        }
        
        public func closeDevice() {
            close(i2c)
        }
        
        private func setBufferPtr(msg: UnsafeMutablePointer<i2c_msg>, buf: UnsafeMutablePointer<Int8>) {
            msg.pointee.buf = buf
        }
        
        public func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8] {
            
            // send only start, stop
            if data.count == 0 && readBytes == 0 {
                try chageAddressIfNeeded(toAddress)
                
                let response = i2c_smbus_write_quick(i2c, UInt8(I2C_SMBUS_WRITE))
                if response < 0 {
                    throw I2CError.noAckError(response)
                }
                return []
            }
            
            let writeLength = data.count
            
            var messageLength = 0
            if writeLength > 0 {
                messageLength += 1
            }
            if readBytes > 0 {
                messageLength += 1
            }
            
            var messageIndex = 0
            var messages = [i2c_msg](repeating: i2c_msg(), count: messageLength)
            
            if writeLength > 0 {
                var writeBuf = unsafeBitCast(data, to: [Int8].self)
                messages[messageIndex].addr = UInt16(toAddress)
                messages[messageIndex].flags = 0 // Write mode
                messages[messageIndex].len = Int16(data.count)
                setBufferPtr(msg: &messages[messageIndex], buf: &writeBuf)
                
                messageIndex += 1
            }
            
            var readBuf: [Int8]?
            if readBytes > 0 {
                readBuf = [Int8](repeating: 0, count: Int(readBytes))
                messages[messageIndex].addr = UInt16(toAddress)
                messages[messageIndex].flags = UInt16(I2C_M_RD)
                messages[messageIndex].len = Int16(readBytes)
                setBufferPtr(msg: &messages[messageIndex], buf: &readBuf!)
            }
            
            //print("writing...", messages)
            
            var packets = i2c_rdwr_ioctl_data(msgs: &messages, nmsgs: UInt32(messages.count))
            let status = ioctl(i2c, UInt(I2C_RDWR), &packets)
            guard status >= 0 else {
                throw I2CError.readOrWriteError(status)
            }
            
            if let buf = readBuf {
                return unsafeBitCast(buf, to: [UInt8].self)
            }
            return []
        }
    }
    
#endif
