import XCTest
@testable import I2C

final class USBI2CTests: XCTestCase {
    
    func testScanDevice() throws {
        
        let device = try I2CTinyUSB()
        
        var addr = 0x08 as UInt8
        while addr <= 0x77 {
            
            let addrStr = String(format: "0x%lx", addr)
            
            usleep(50_000); // 50ms wait
            
            print("sending... to", addrStr)
            
            do {
                if try device.write(toAddress: addr, data: [], readBytes: 0) == [] {
                    print("device found at", addrStr)
                }
            } catch I2CTinyUSB.USBDeviceError.USBI2CNoAckError {
                // no device found
            }
            
            addr += 1
        }
        
        device.closeDevice()
    }
    
    
    func testDeviceConnected() throws {
        
        let device = try I2CTinyUSB()
        
        XCTAssertTrue(try device.write(toAddress: 0x23, data: [], readBytes: 0) == [])
        
        device.closeDevice()
    }


    static var allTests : [(String, (USBI2CTests) -> () throws -> Void)] {
        return [
            ("testScanDevice", testScanDevice),
            ("testDeviceConnected", testDeviceConnected)
        ]
    }
}
