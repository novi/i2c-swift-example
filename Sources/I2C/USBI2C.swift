//
//  USBI2C.swift
//  i2clib
//
//  Created by Yusuke Ito on 12/14/16.
//
//

import Foundation
import CUSB

extension String {
    init?(tupleCString tuple: Any) {
        let mirror = Mirror(reflecting: tuple)
        
        var buffer = [CChar](repeating: 0, count: Int(mirror.children.count))
        var index = 0
        for c in mirror.children {
            buffer[index] = c.value as? CChar ?? 0
            index += 1
        }
        self.init(utf8String: buffer)
    }
}

fileprivate func findDevice(vendor: UInt16, product: UInt16) -> UnsafeMutablePointer<usb_device>? {
    usb_find_busses()
    usb_find_devices()
    guard var bus = usb_get_busses() else {
        return nil
    }
    while true {
        // has valid device
        if var dev = bus.pointee.devices {
            while true {
                
                //print("dirname", String(tupleCString: bus.pointee.dirname))
                //print("filename", String(tupleCString: dev.pointee.filename))
                
                if dev.pointee.descriptor.idVendor == vendor &&
                    dev.pointee.descriptor.idProduct == product {
                    return dev
                }
                
                if let next = dev.pointee.next {
                    dev = next
                } else {
                    break
                }
            }
        }
        if let next = bus.pointee.next {
            // has next bus
            bus = next
            continue
        } else {
            break
        }
    }
    return nil
}

public final class I2CTinyUSB {
    
    public enum USBDeviceError: Error {
        case USBDeviceOpenError
        case USBControlMessageSendError
        case I2CTinyUSBNotFound
        case USBI2CWriteError
        case USBI2CReadError
        case USBI2CNoAckError
    }
    
    private static var usbInitialized: Bool = false
    private static func usbInit() {
        guard usbInitialized == false else {
            return
        }
        usbInitialized = true
        usb_init()
    }
    
    private static let VendorID: UInt16 = 0x0403
    private static let ProductID: UInt16 = 0xc631
    
    fileprivate let USB_CTRL_IN = (USB_TYPE_CLASS | USB_ENDPOINT_IN)
    fileprivate let USB_CTRL_OUT = (USB_TYPE_CLASS)
    fileprivate let CMD_ECHO = 0 as Int32
    fileprivate let CMD_GET_FUNC = 1 as Int32
    fileprivate let CMD_SET_DELAY = 2 as Int32
    fileprivate let CMD_GET_STATUS = 3 as Int32
    fileprivate let CMD_I2C_IO = 4 as Int32
    fileprivate let CMD_I2C_BEGIN = 1 as Int32 // flag to I2C_IO
    fileprivate let CMD_I2C_END = 2 as Int32 // flag to I2C_IO

    fileprivate let TimeoutControl = 1000 as Int32
    fileprivate let TimeoutI2CBus = 1000 as Int32
    
    fileprivate let usb: OpaquePointer
    public init() throws {
        type(of: self).usbInit()
        
        guard let dev = findDevice(vendor: type(of: self).VendorID, product: type(of: self).ProductID) else {
            throw USBDeviceError.I2CTinyUSBNotFound
        }
        guard let handler = usb_open(dev) else {
            throw USBDeviceError.USBDeviceOpenError
        }
        self.usb = handler
        
        let funcVal = String(format: "%lx", try getFunc())
        try print("func=\(funcVal), status=\(getStatus())")
        
        try usbSet(cmd: CMD_SET_DELAY, value: 10)
    }
    
    public func closeDevice() {
        usb_release_interface(usb, 0)
        usb_close(usb)
    }
}

fileprivate extension I2CTinyUSB {
    
    func usbRead(cmd: Int32, outBuffer: UnsafeMutablePointer<Int8>, length: UInt32) throws {
        let bytesRead = usb_control_msg(usb, USB_CTRL_IN, cmd, 0, 0, outBuffer, Int32(length), TimeoutControl)
        if bytesRead < 0 {
            throw USBDeviceError.USBControlMessageSendError
        }
    }
    
    func usbSet(cmd: Int32, value: Int32) throws {
        let nBytes = usb_control_msg(usb, USB_TYPE_VENDOR, cmd, value, 0, nil, 0, TimeoutControl)
        if nBytes < 0 {
            throw USBDeviceError.USBControlMessageSendError
        }
    }
    
    enum Status: Int {
        case idle = 0
        case addressACK = 1
        case addressNAK = 2
    }
    
    func getFunc() throws -> UInt32 {
        let buffer = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        defer {
            buffer.deallocate(capacity: 1)
        }
        try usbRead(cmd: CMD_GET_FUNC, outBuffer: unsafeBitCast(buffer, to: UnsafeMutablePointer<Int8>.self), length: UInt32(MemoryLayout<UInt32>.size))
        return buffer.pointee
    }
    
    func getStatus() throws -> Status {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        defer {
            buffer.deallocate(capacity: 1)
        }
        try usbRead(cmd: CMD_GET_STATUS, outBuffer: unsafeBitCast(buffer, to: UnsafeMutablePointer<Int8>.self), length: 1)
        guard let status = Status(rawValue: Int(buffer.pointee)) else {
            throw USBDeviceError.USBControlMessageSendError
        }
        return status
    }
}

extension I2CTinyUSB {
    
    fileprivate func sendAck(addr: UInt8) throws {
        let nBytes = usb_control_msg(usb, USB_CTRL_IN, CMD_I2C_IO + CMD_I2C_BEGIN + CMD_I2C_END, 0, Int32(addr), nil, 0, TimeoutControl)
        if nBytes < 0 {
            throw USBDeviceError.USBControlMessageSendError
        }
        if try getStatus() == .addressACK {
            return
        }
        throw USBDeviceError.USBI2CNoAckError
    }
}

extension I2CTinyUSB: I2CDevice {
    
    private func write(toAddress: UInt8, data: [UInt8], sendStop: Bool) throws {
        var buffer = unsafeBitCast(data, to: [Int8].self)
        // start control flow, (end control flow if no reading)
        let nBytes = usb_control_msg(usb, USB_CTRL_OUT, CMD_I2C_IO + CMD_I2C_BEGIN + (sendStop ? CMD_I2C_END : 0), 0, Int32(toAddress), &buffer, Int32(data.count), TimeoutControl)
        if nBytes < 0 {
            throw USBDeviceError.USBI2CWriteError
        }
        if sendStop {
            // check ACK
            if try getStatus() != .addressACK {
                throw USBDeviceError.USBI2CNoAckError
            }
        }
    }
    
    public func write(toAddress: UInt8, data: [UInt8], readBytes: UInt32) throws -> [UInt8] {
        
        if data.count == 0 && readBytes == 0 {
            try sendAck(addr: toAddress)
            return []
        }
        
        let writeLength = data.count
        
        if writeLength > 0 {
            // start control flow and write bytes
            try write(toAddress: toAddress, data: data, sendStop: readBytes == 0)
        }
        
        if readBytes > 0 {
            var readBuffer = [Int8](repeating: 0, count: Int(readBytes))
            // read data and end control flow
            let nBytes = usb_control_msg(usb, USB_CTRL_IN, CMD_I2C_IO + (writeLength > 0 ? 0 : CMD_I2C_BEGIN) + CMD_I2C_END, 0, Int32(toAddress), &readBuffer, Int32(readBytes), TimeoutI2CBus)
            if nBytes < 0 {
                throw USBDeviceError.USBI2CReadError
            }
            if try getStatus() != .addressACK {
                throw USBDeviceError.USBI2CNoAckError
            }
            return unsafeBitCast(readBuffer, to: [UInt8].self)
        }
        
        return []
    }
    
}
